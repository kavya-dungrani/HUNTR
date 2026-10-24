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

        // Update public leaderboard entry
        await firestore.collection('leaderboard').doc(user.uid).set({
          'id': user.uid,
          'hunterId': profile.hunterId,
          'displayName': profile.displayName,
          'level': profile.currentLevel,
          'rank': profile.currentRank,
          'totalXp': profile.totalXp,
          'affinity': profile.affinity,
          'equippedTitle': profile.equippedTitle,
          'questsCompleted': profile.questsCompleted,
          'streak': profile.streak,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
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
        final doc = await firestore.collection('hunters').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final profile = HunterProfile.fromJson(doc.data()!);
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
      final snap = await firestore
          .collection('leaderboard')
          .orderBy('totalXp', descending: true)
          .limit(25)
          .get();

      if (snap.docs.isNotEmpty) {
        return snap.docs.map((d) => d.data()).toList();
      }
    } catch (_) {}

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
