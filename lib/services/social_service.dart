import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_engine.dart';

class SocialService {
  SocialService._();
  static final SocialService instance = SocialService._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // ============================================================
  // USERNAME & HUNTER ID REGISTRY
  // ============================================================

  Future<bool> checkUsernameAvailable(String username) async {
    final clean = normalizeUsername(username);
    if (!isValidUsername(clean)) return false;

    try {
      final docSnap = await _firestore.collection('usernames').doc(clean).get();
      return !docSnap.exists;
    } catch (_) {
      return false;
    }
  }

  Future<String> claimUsername(String uid, String username) async {
    final clean = normalizeUsername(username);
    if (!isValidUsername(clean)) {
      throw Exception('Username must be 3-20 lowercase alphanumeric characters.');
    }

    final docRef = _firestore.collection('usernames').doc(clean);

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(docRef);
      if (existing.exists && existing.data()?['uid'] != uid) {
        throw Exception('Username "$clean" is already claimed.');
      }
      transaction.set(docRef, {
        'uid': uid,
        'username': clean,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    return clean;
  }

  Future<String> claimHunterId(String uid, [String? preferred, String? username]) async {
    var hid = preferred?.toUpperCase() ?? '';
    if (!RegExp(r'^HUNTR-[A-Z0-9]{8}$').hasMatch(hid)) {
      hid = generateUniqueHunterId();
    }

    final docRef = _firestore.collection('hunterIds').doc(hid);

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(docRef);
      if (existing.exists && existing.data()?['uid'] != uid) {
        hid = generateUniqueHunterId();
        final retryRef = _firestore.collection('hunterIds').doc(hid);
        transaction.set(retryRef, {
          'uid': uid,
          'username': username ?? 'hunter',
          'createdAt': FieldValue.serverTimestamp(),
        });
        return;
      }
      transaction.set(docRef, {
        'uid': uid,
        'username': username ?? 'hunter',
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    return hid;
  }

  Future<void> syncPublicPlayer(HunterProfile profile) async {
    final cleanUsername = normalizeUsername(profile.username);

    final statsMap = <String, int>{};
    profile.stats.forEach((k, v) {
      statsMap[k.name] = v;
    });

    final publicData = {
      'uid': profile.id,
      'username': cleanUsername,
      'hunterId': profile.hunterId,
      'displayName': profile.displayName,
      'currentLevel': profile.currentLevel,
      'currentRank': profile.currentRank,
      'totalXp': profile.totalXp,
      'affinity': profile.affinity,
      'equippedTitle': profile.equippedTitle.isNotEmpty ? profile.equippedTitle : 'The Awakened',
      'questsCompleted': profile.questsCompleted,
      'streak': profile.streak,
      'guildId': profile.guildId,
      'guildName': profile.guildName,
      'guildTag': profile.guildTag,
      'stats': statsMap,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    final batch = _firestore.batch();
    batch.set(_firestore.collection('players').doc(profile.id), publicData, SetOptions(merge: true));
    batch.set(
      _firestore.collection('leaderboard').doc(profile.id),
      {
        'id': profile.id,
        'hunterId': profile.hunterId,
        'username': cleanUsername,
        'displayName': profile.displayName,
        'level': profile.currentLevel,
        'rank': profile.currentRank,
        'totalXp': profile.totalXp,
        'affinity': profile.affinity,
        'equippedTitle': profile.equippedTitle.isNotEmpty ? profile.equippedTitle : 'The Awakened',
        'questsCompleted': profile.questsCompleted,
        'streak': profile.streak,
        'guildId': profile.guildId,
        'guildName': profile.guildName,
        'guildTag': profile.guildTag,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<Map<String, dynamic>?> getPublicPlayer(String uid) async {
    try {
      final doc = await _firestore.collection('players').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
      final lbDoc = await _firestore.collection('leaderboard').doc(uid).get();
      if (lbDoc.exists && lbDoc.data() != null) {
        final d = lbDoc.data()!;
        return {
          'uid': uid,
          'username': d['username'] ?? normalizeUsername(d['displayName'] ?? 'hunter'),
          'hunterId': d['hunterId'] ?? 'HUNTR-UNKNOWN',
          'displayName': d['displayName'] ?? 'Hunter',
          'currentLevel': d['level'] ?? 1,
          'currentRank': d['rank'] ?? 'E-Rank',
          'totalXp': d['totalXp'] ?? 0,
          'affinity': d['affinity'] ?? 'AGI',
          'equippedTitle': d['equippedTitle'] ?? 'The Awakened',
          'questsCompleted': d['questsCompleted'] ?? 0,
          'streak': d['streak'] ?? 1,
          'guildId': d['guildId'],
          'guildName': d['guildName'],
          'guildTag': d['guildTag'],
        };
      }
    } catch (_) {}
    return null;
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Future<List<Map<String, dynamic>>> searchHunters(String queryText, String currentUid) async {
    final trimmed = queryText.trim();
    if (trimmed.isEmpty) return [];

    final results = <Map<String, dynamic>>[];
    final seen = <String>{};

    // 1. Exact Hunter ID lookup if starts with HUNTR-
    if (trimmed.toUpperCase().startsWith('HUNTR-')) {
      try {
        final snap = await _firestore
            .collection('players')
            .where('hunterId', isEqualTo: trimmed.toUpperCase())
            .limit(5)
            .get();
        for (var d in snap.docs) {
          if (d.id != currentUid && !seen.contains(d.id)) {
            seen.add(d.id);
            results.add(d.data());
          }
        }
        if (results.isNotEmpty) return results;
      } catch (_) {}
    }

    // 2. Lowercase username prefix lookup
    final clean = normalizeUsername(trimmed);
    if (clean.length >= 2) {
      try {
        final snap = await _firestore
            .collection('players')
            .where('username', isGreaterThanOrEqualTo: clean)
            .where('username', isLessThanOrEqualTo: '$clean\uf8ff')
            .limit(15)
            .get();
        for (var d in snap.docs) {
          if (d.id != currentUid && !seen.contains(d.id)) {
            seen.add(d.id);
            results.add(d.data());
          }
        }
      } catch (_) {}
    }

    return results;
  }

  // ============================================================
  // FRIENDSHIP ACTIONS
  // ============================================================

  Future<String> getFriendshipStatus(String currentUid, String targetUid) async {
    if (currentUid == targetUid) return 'self';

    try {
      final friendDoc = await _firestore
          .collection('hunters')
          .doc(currentUid)
          .collection('friends')
          .doc(targetUid)
          .get();
      if (friendDoc.exists) return 'friends';

      final outDoc = await _firestore
          .collection('friendRequests')
          .doc('${currentUid}_$targetUid')
          .get();
      if (outDoc.exists && outDoc.data()?['status'] == 'pending') {
        return 'request_sent';
      }

      final inDoc = await _firestore
          .collection('friendRequests')
          .doc('${targetUid}_$currentUid')
          .get();
      if (inDoc.exists && inDoc.data()?['status'] == 'pending') {
        return 'request_received';
      }
    } catch (_) {}

    return 'none';
  }

  Future<void> sendFriendRequest(HunterProfile currentUser, Map<String, dynamic> target) async {
    final targetUid = target['uid'] as String;
    if (currentUser.id == targetUid) {
      throw Exception('You cannot add yourself as a friend.');
    }

    final requestId = '${currentUser.id}_$targetUid';
    final invId = '${targetUid}_${currentUser.id}';

    // Auto-accept if target already sent a request
    final invSnap = await _firestore.collection('friendRequests').doc(invId).get();
    if (invSnap.exists && invSnap.data()?['status'] == 'pending') {
      await acceptFriendRequest(invId, targetUid, currentUser.id);
      return;
    }

    await _firestore.collection('friendRequests').doc(requestId).set({
      'id': requestId,
      'fromUid': currentUser.id,
      'toUid': targetUid,
      'fromUsername': currentUser.username,
      'fromHunterId': currentUser.hunterId,
      'fromDisplayName': currentUser.displayName,
      'fromLevel': currentUser.currentLevel,
      'fromRank': currentUser.currentRank,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptFriendRequest(String requestId, String fromUid, String toUid) async {
    final sender = await getPublicPlayer(fromUid);
    final receiver = await getPublicPlayer(toUid);

    final batch = _firestore.batch();

    // 1. Mark request accepted
    batch.update(_firestore.collection('friendRequests').doc(requestId), {
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    // 2. Add sender as friend in receiver's friends collection
    batch.set(
      _firestore.collection('hunters').doc(toUid).collection('friends').doc(fromUid),
      {
        'uid': fromUid,
        'username': sender?['username'] ?? 'hunter',
        'hunterId': sender?['hunterId'] ?? 'HUNTR-UNKNOWN',
        'displayName': sender?['displayName'] ?? 'Hunter',
        'level': sender?['currentLevel'] ?? 1,
        'rank': sender?['currentRank'] ?? 'E-Rank',
        'affinity': sender?['affinity'] ?? 'AGI',
        'equippedTitle': sender?['equippedTitle'] ?? 'The Awakened',
        'addedAt': FieldValue.serverTimestamp(),
      },
    );

    // 3. Add receiver as friend in sender's friends collection
    batch.set(
      _firestore.collection('hunters').doc(fromUid).collection('friends').doc(toUid),
      {
        'uid': toUid,
        'username': receiver?['username'] ?? 'hunter',
        'hunterId': receiver?['hunterId'] ?? 'HUNTR-UNKNOWN',
        'displayName': receiver?['displayName'] ?? 'Hunter',
        'level': receiver?['currentLevel'] ?? 1,
        'rank': receiver?['currentRank'] ?? 'E-Rank',
        'affinity': receiver?['affinity'] ?? 'AGI',
        'equippedTitle': receiver?['equippedTitle'] ?? 'The Awakened',
        'addedAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  Future<void> declineFriendRequest(String requestId) async {
    await _firestore.collection('friendRequests').doc(requestId).delete();
  }

  Future<void> removeFriend(String currentUid, String friendUid) async {
    final batch = _firestore.batch();
    batch.delete(_firestore.collection('hunters').doc(currentUid).collection('friends').doc(friendUid));
    batch.delete(_firestore.collection('hunters').doc(friendUid).collection('friends').doc(currentUid));
    batch.delete(_firestore.collection('friendRequests').doc('${currentUid}_$friendUid'));
    batch.delete(_firestore.collection('friendRequests').doc('${friendUid}_$currentUid'));
    await batch.commit();
  }

  // ============================================================
  // STREAMS
  // ============================================================

  Stream<List<Map<String, dynamic>>> streamFriends(String uid) {
    return _firestore
        .collection('hunters')
        .doc(uid)
        .collection('friends')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> streamIncomingRequests(String uid) {
    return _firestore
        .collection('friendRequests')
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}

