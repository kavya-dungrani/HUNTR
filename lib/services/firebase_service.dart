import 'social_service.dart';
import 'guild_service.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_engine.dart';
import '../models/daily_system.dart';

class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  static const String serverClientId =
      '693350757736-bov402t9a0t0a8g8ha4uumg6gumtv4ts.apps.googleusercontent.com';

  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  static const String _keyLocalProfile = 'local_hunter_profile';
  static const String _keyLocalQuests = 'local_hunter_quests';
  static const String _keyLocalDungeon = 'local_hunter_dungeon';
  static const String _keyLocalBonus = 'local_hunter_bonus';
  static const String _keyLocalAchievements = 'local_hunter_achievements';
  static const String _keyHasLoggedIn = 'hunter_has_logged_in';

  User? get currentUser => auth.currentUser;

  Future<bool> hasLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getBool(_keyHasLoggedIn) ?? false) || (currentUser != null);
  }

  // ================= AUTH METHODS =================

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.updateDisplayName(displayName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasLoggedIn, true);
    return cred;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasLoggedIn, true);
    return cred;
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final GoogleAuthProvider authProvider = GoogleAuthProvider();
        final cred = await auth.signInWithPopup(authProvider);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyHasLoggedIn, true);
        return cred;
      } else {
        await GoogleSignIn.instance.initialize(
          serverClientId: serverClientId,
        );
        final account = await GoogleSignIn.instance.authenticate();
        final googleAuth = account.authentication;
        if (googleAuth.idToken == null) {
          throw Exception('Failed to obtain Google ID token.');
        }
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        final cred = await auth.signInWithCredential(credential);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyHasLoggedIn, true);
        return cred;
      }
    } catch (e) {
      debugPrint('FirebaseService signInWithGoogle error: $e');
      rethrow;
    }
  }

  Future<UserCredential> signInAnonymously() async {
    final cred = await auth.signInAnonymously();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasLoggedIn, true);
    return cred;
  }

  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}
      }
      await auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLocalProfile);
      await prefs.remove(_keyLocalQuests);
      await prefs.remove(_keyLocalDungeon);
      await prefs.remove(_keyLocalBonus);
      await prefs.remove(_keyLocalAchievements);
      await prefs.setBool(_keyHasLoggedIn, false);
    } catch (e) {
      debugPrint('FirebaseService signOut error: $e');
    }
  }

  Future<void> deleteAccount(HunterProfile? profile) async {
    final user = currentUser;
    if (user != null) {
      final uid = user.uid;

      // 1. Remove from global leaderboard
      try {
        await firestore.collection('leaderboard').doc(uid).delete();
      } catch (e) {
        debugPrint('FirebaseService deleteAccount leaderboard error: $e');
      }

      // 2. Remove public player profile card
      try {
        await firestore.collection('players').doc(uid).delete();
      } catch (e) {
        debugPrint('FirebaseService deleteAccount player error: $e');
      }

      // 3. Remove presence
      try {
        await firestore.collection('presence').doc(uid).delete();
      } catch (e) {
        debugPrint('FirebaseService deleteAccount presence error: $e');
      }

      // 4. Release unique username if claimed
      if (profile != null && profile.username.isNotEmpty) {
        try {
          final clean = normalizeUsername(profile.username);
          await firestore.collection('usernames').doc(clean).delete();
        } catch (e) {
          debugPrint('FirebaseService deleteAccount username error: $e');
        }
      }

      // 5. Leave guild if enrolled
      if (profile != null && profile.guildId != null && profile.guildId!.isNotEmpty) {
        try {
          final isLeader = profile.guildRole == 'leader';
          await GuildService.instance.leaveGuild(profile.guildId!, uid, isLeader);
        } catch (e) {
          debugPrint('FirebaseService deleteAccount leaveGuild error: $e');
        }
      }

      // 6. Remove private hunter profile
      try {
        await firestore.collection('hunters').doc(uid).delete();
      } catch (e) {
        debugPrint('FirebaseService deleteAccount hunter doc error: $e');
      }

      // 7. Delete auth user credentials
      try {
        await user.delete();
      } catch (e) {
        debugPrint('FirebaseService deleteAccount auth user error: $e');
        await signOut();
      }
    }

    // 8. Clear all local preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // ================= FIRESTORE SYNC =================

  Future<void> saveProfile(HunterProfile profile) async {
    // 1. Always save to local SharedPreferences immediately for instant responsiveness
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocalProfile, jsonEncode(profile.toJson()));
    await prefs.setBool(_keyHasLoggedIn, true);

    // 2. Sync to Firestore if authenticated
    final user = currentUser;
    if (user != null) {
      try {
        final profileMap = profile.toJson();
        await firestore.collection('hunters').doc(user.uid).set(profileMap, SetOptions(merge: true));

        // Sync public player card and leaderboard entry
        await SocialService.instance.syncPublicPlayer(profile);
      } catch (e) {
        // Log quietly — local copy is safe
        debugPrint('Firestore profile sync error (offline or permission): $e');
      }
    }
  }

  Future<HunterProfile?> loadProfile() async {
    final user = currentUser;
    if (user != null) {
      try {
        var doc = await firestore.collection('hunters').doc(user.uid).get();
        if (!doc.exists || doc.data() == null) {
          doc = await firestore.collection('players').doc(user.uid).get();
        }
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          data['id'] = data['id'] ?? user.uid;
          final profile = HunterProfile.fromJson(data);
          // Migration guarantee: ensure username and hunterId are claimed
          if (profile.username.isNotEmpty) {
            SocialService.instance.claimUsername(user.uid, profile.username).catchError((_) => profile.username);
          }
          if (profile.hunterId.isNotEmpty) {
            SocialService.instance.claimHunterId(user.uid, profile.hunterId, profile.username).catchError((_) => profile.hunterId);
          }
          // Cache locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keyLocalProfile, jsonEncode(profile.toJson()));
          return profile;
        }
      } catch (e) {
        debugPrint('Firestore load error (falling back to local cache): $e');
      }
    }

    // Fallback to local SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyLocalProfile);
    if (jsonStr != null) {
      try {
        final data = jsonDecode(jsonStr) as Map<String, dynamic>;
        return HunterProfile.fromJson(data);
      } catch (_) {}
    }
    return null;
  }

  Future<void> saveQuests(List<Quest> quests) async {
    final prefs = await SharedPreferences.getInstance();
    final list = quests.map((q) => q.toJson()).toList();
    await prefs.setString(_keyLocalQuests, jsonEncode(list));

    final user = currentUser;
    if (user != null) {
      try {
        await firestore.collection('hunters').doc(user.uid).set({
          'activeQuests': list,
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  Future<List<Quest>> loadQuests() async {
    final user = currentUser;
    if (user != null) {
      try {
        final doc = await firestore.collection('hunters').doc(user.uid).get();
        if (doc.exists && doc.data()?['activeQuests'] != null) {
          final list = (doc.data()!['activeQuests'] as List).cast<Map<String, dynamic>>();
          return list.map((m) => Quest.fromJson(m)).toList();
        }
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyLocalQuests);
    if (jsonStr != null) {
      try {
        final list = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
        return list.map((m) => Quest.fromJson(m)).toList();
      } catch (_) {}
    }
    return [];
  }

  Future<void> saveDungeonBreak(DungeonBreak? dungeon) async {
    final prefs = await SharedPreferences.getInstance();
    if (dungeon != null) {
      await prefs.setString(_keyLocalDungeon, jsonEncode(dungeon.toJson()));
    } else {
      await prefs.remove(_keyLocalDungeon);
    }
  }

  Future<DungeonBreak?> loadDungeonBreak() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyLocalDungeon);
    if (str != null) {
      try {
        return DungeonBreak.fromJson(jsonDecode(str));
      } catch (_) {}
    }
    return null;
  }

  Future<void> saveAchievements(List<String> achievements) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyLocalAchievements, achievements);
  }

  Future<List<String>> loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keyLocalAchievements) ?? [];
  }

  Future<List<Map<String, dynamic>>> fetchLeaderboard() async {
    try {
      final snap = await firestore.collection('leaderboard').limit(100).get();
      if (snap.docs.isNotEmpty) {
        final list = snap.docs.map((d) {
          final data = d.data();
          data['id'] = data['id'] ?? d.id;
          return data;
        }).toList();

        list.sort((a, b) {
          final aXp = (a['totalXp'] is num) ? (a['totalXp'] as num) : num.tryParse(a['totalXp']?.toString() ?? '0') ?? 0;
          final bXp = (b['totalXp'] is num) ? (b['totalXp'] as num) : num.tryParse(b['totalXp']?.toString() ?? '0') ?? 0;
          return bXp.compareTo(aXp);
        });

        return list;
      }

      // Fallback to players collection if leaderboard empty
      final playerSnap = await firestore.collection('players').limit(100).get();
      if (playerSnap.docs.isNotEmpty) {
        final list = playerSnap.docs.map((d) {
          final data = d.data();
          data['id'] = data['id'] ?? d.id;
          return data;
        }).toList();

        list.sort((a, b) {
          final aXp = (a['totalXp'] is num) ? (a['totalXp'] as num) : num.tryParse(a['totalXp']?.toString() ?? '0') ?? 0;
          final bXp = (b['totalXp'] is num) ? (b['totalXp'] as num) : num.tryParse(b['totalXp']?.toString() ?? '0') ?? 0;
          return bXp.compareTo(aXp);
        });

        return list;
      }
    } catch (e) {
      debugPrint('[FirebaseService] Leaderboard fetch error: $e');
    }

    // Built-in Top Hunters default demo data (Solo Leveling Guilds)
    return [
      {
        'id': 'lb-1',
        'hunterId': 'HUNTER-MONARCH-S',
        'displayName': 'Sung Jin-Woo',
        'level': 142,
        'rank': 'S-Rank',
        'totalXp': 589200,
        'affinity': 'STR',
        'equippedTitle': 'Shadow Monarch',
        'questsCompleted': 1420,
        'streak': 365,
      },
      {
        'id': 'lb-2',
        'hunterId': 'HUNTER-GOLIATH-S',
        'displayName': 'Thomas Andre',
        'level': 118,
        'rank': 'S-Rank',
        'totalXp': 412500,
        'affinity': 'VIT',
        'equippedTitle': 'Goliath',
        'questsCompleted': 980,
        'streak': 240,
      },
      {
        'id': 'lb-3',
        'hunterId': 'HUNTER-BLADE-S',
        'displayName': 'Cha Hae-In',
        'level': 98,
        'rank': 'S-Rank',
        'totalXp': 295000,
        'affinity': 'AGI',
        'equippedTitle': 'Sword Dancer',
        'questsCompleted': 760,
        'streak': 180,
      },
      {
        'id': 'lb-4',
        'hunterId': 'HUNTER-BEAST-A',
        'displayName': 'Baek Yoonho',
        'level': 84,
        'rank': 'A-Rank',
        'totalXp': 198000,
        'affinity': 'STR',
        'equippedTitle': 'White Tiger',
        'questsCompleted': 540,
        'streak': 115,
      },
      {
        'id': 'lb-5',
        'hunterId': 'HUNTER-FLAME-A',
        'displayName': 'Choi Jong-In',
        'level': 79,
        'rank': 'A-Rank',
        'totalXp': 165000,
        'affinity': 'INT',
        'equippedTitle': 'Ultimate Mage',
        'questsCompleted': 480,
        'streak': 92,
      },
    ];
  }

  Stream<List<Map<String, dynamic>>> streamLeaderboard() {
    return firestore.collection('leaderboard').limit(100).snapshots().map((snap) {
      if (snap.docs.isEmpty) return <Map<String, dynamic>>[];
      final list = snap.docs.map((d) {
        final data = d.data();
        data['id'] = data['id'] ?? d.id;
        return data;
      }).toList();

      list.sort((a, b) {
        final aXp = (a['totalXp'] is num) ? (a['totalXp'] as num) : num.tryParse(a['totalXp']?.toString() ?? '0') ?? 0;
        final bXp = (b['totalXp'] is num) ? (b['totalXp'] as num) : num.tryParse(b['totalXp']?.toString() ?? '0') ?? 0;
        return bXp.compareTo(aXp);
      });

      return list;
    });
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLocalProfile);
    await prefs.remove(_keyLocalQuests);
    await prefs.remove(_keyLocalDungeon);
    await prefs.remove(_keyLocalBonus);
    await prefs.remove(_keyLocalAchievements);
    await signOut();
  }
}
