import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/game_engine.dart';

class GuildService {
  GuildService._();
  static final GuildService instance = GuildService._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  // ============================================================
  // GUILD CREATION & LOOKUP
  // ============================================================

  Future<String> createGuild({
    required HunterProfile leader,
    required String name,
    required String tag,
    required String description,
    required String icon,
    required String joinType,
  }) async {
    final cleanName = name.trim();
    final cleanTag = tag.trim().toUpperCase();

    if (cleanName.length < 3) {
      throw Exception('Guild name must be at least 3 characters.');
    }
    if (cleanTag.length < 2 || cleanTag.length > 5) {
      throw Exception('Guild tag must be between 2 and 5 uppercase characters.');
    }

    final guildId = 'guild-${DateTime.now().millisecondsSinceEpoch}';
    final guildRef = _firestore.collection('guilds').doc(guildId);
    final memberRef = guildRef.collection('members').doc(leader.id);
    final hunterRef = _firestore.collection('hunters').doc(leader.id);
    final playerRef = _firestore.collection('players').doc(leader.id);
    final lbRef = _firestore.collection('leaderboard').doc(leader.id);

    final batch = _firestore.batch();

    // 1. Guild document
    batch.set(guildRef, {
      'id': guildId,
      'name': cleanName,
      'nameLower': cleanName.toLowerCase(),
      'tag': cleanTag,
      'description': description.trim().isNotEmpty ? description.trim() : 'No description provided.',
      'icon': icon,
      'joinType': joinType,
      'leaderUid': leader.id,
      'leaderUsername': leader.username,
      'leaderDisplayName': leader.displayName,
      'memberCount': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Leader as first member
    batch.set(memberRef, {
      'uid': leader.id,
      'username': leader.username,
      'hunterId': leader.hunterId,
      'displayName': leader.displayName,
      'level': leader.currentLevel,
      'rank': leader.currentRank,
      'role': 'leader',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    // 3. User profile updates
    final updates = {
      'guildId': guildId,
      'guildRole': 'leader',
      'guildName': cleanName,
      'guildTag': cleanTag,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    batch.set(hunterRef, updates, SetOptions(merge: true));
    batch.set(playerRef, updates, SetOptions(merge: true));
    batch.set(lbRef, updates, SetOptions(merge: true));

    await batch.commit();
    return guildId;
  }

  Future<List<Map<String, dynamic>>> searchGuilds({
    String queryText = '',
    String joinTypeFilter = 'all',
  }) async {
    try {
      final snap = await _firestore.collection('guilds').limit(100).get();
      var list = snap.docs.map((d) {
        final data = d.data();
        data['id'] = data['id'] ?? d.id;
        return data;
      }).toList();

      // Sort client-side by memberCount descending
      list.sort((a, b) {
        final aCount = (a['memberCount'] is num) ? (a['memberCount'] as num).toInt() : int.tryParse(a['memberCount']?.toString() ?? '0') ?? 0;
        final bCount = (b['memberCount'] is num) ? (b['memberCount'] as num).toInt() : int.tryParse(b['memberCount']?.toString() ?? '0') ?? 0;
        return bCount.compareTo(aCount);
      });

      // Filter by joinType in-memory
      if (joinTypeFilter != 'all') {
        list = list.where((g) => (g['joinType'] ?? 'open') == joinTypeFilter).toList();
      }

      final term = queryText.trim().toLowerCase();
      if (term.isNotEmpty) {
        list = list.where((g) {
          final n = (g['name'] ?? '').toString().toLowerCase();
          final t = (g['tag'] ?? '').toString().toLowerCase();
          return n.contains(term) || t.contains(term);
        }).toList();
      }

      return list;
    } catch (e) {
      debugPrint('[GuildService] searchGuilds error: $e');
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> streamGuilds({String joinTypeFilter = 'all'}) {
    return _firestore.collection('guilds').limit(100).snapshots().map((snap) {
      var list = snap.docs.map((d) {
        final data = d.data();
        data['id'] = data['id'] ?? d.id;
        return data;
      }).toList();

      list.sort((a, b) {
        final aCount = (a['memberCount'] is num) ? (a['memberCount'] as num).toInt() : int.tryParse(a['memberCount']?.toString() ?? '0') ?? 0;
        final bCount = (b['memberCount'] is num) ? (b['memberCount'] as num).toInt() : int.tryParse(b['memberCount']?.toString() ?? '0') ?? 0;
        return bCount.compareTo(aCount);
      });

      if (joinTypeFilter != 'all') {
        list = list.where((g) => (g['joinType'] ?? 'open') == joinTypeFilter).toList();
      }

      return list;
    });
  }

  Future<Map<String, dynamic>?> getGuild(String guildId) async {
    try {
      final doc = await _firestore.collection('guilds').doc(guildId).get();
      if (doc.exists) return doc.data();
    } catch (_) {}
    return null;
  }

  // ============================================================
  // MEMBERSHIP ACTIONS
  // ============================================================

  Future<void> joinOpenGuild(HunterProfile user, Map<String, dynamic> guild) async {
    final guildId = guild['id'] as String;
    if (guild['joinType'] != 'open') {
      throw Exception('This guild requires leadership approval to join.');
    }

    final batch = _firestore.batch();
    final guildRef = _firestore.collection('guilds').doc(guildId);
    final memberRef = guildRef.collection('members').doc(user.id);
    final hunterRef = _firestore.collection('hunters').doc(user.id);
    final playerRef = _firestore.collection('players').doc(user.id);
    final lbRef = _firestore.collection('leaderboard').doc(user.id);

    batch.set(memberRef, {
      'uid': user.id,
      'username': user.username,
      'hunterId': user.hunterId,
      'displayName': user.displayName,
      'level': user.currentLevel,
      'rank': user.currentRank,
      'role': 'member',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    batch.update(guildRef, {
      'memberCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final updates = {
      'guildId': guildId,
      'guildRole': 'member',
      'guildName': guild['name'],
      'guildTag': guild['tag'],
      'updatedAt': FieldValue.serverTimestamp(),
    };

    batch.set(hunterRef, updates, SetOptions(merge: true));
    batch.set(playerRef, updates, SetOptions(merge: true));
    batch.set(lbRef, updates, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> requestToJoinGuild(HunterProfile user, String guildId) async {
    final reqRef = _firestore.collection('guilds').doc(guildId).collection('joinRequests').doc(user.id);
    await reqRef.set({
      'id': user.id,
      'guildId': guildId,
      'uid': user.id,
      'username': user.username,
      'hunterId': user.hunterId,
      'displayName': user.displayName,
      'level': user.currentLevel,
      'rank': user.currentRank,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelJoinRequest(String guildId, String uid) async {
    await _firestore.collection('guilds').doc(guildId).collection('joinRequests').doc(uid).delete();
  }

  Future<Map<String, dynamic>?> getUserGuildRequest(String guildId, String uid) async {
    try {
      final doc = await _firestore.collection('guilds').doc(guildId).collection('joinRequests').doc(uid).get();
      if (doc.exists && doc.data()?['status'] == 'pending') {
        return doc.data();
      }
    } catch (_) {}
    return null;
  }

  Future<void> acceptJoinRequest(Map<String, dynamic> guild, Map<String, dynamic> request) async {
    final guildId = guild['id'] as String;
    final reqUid = request['uid'] as String;

    final batch = _firestore.batch();
    final guildRef = _firestore.collection('guilds').doc(guildId);
    final memberRef = guildRef.collection('members').doc(reqUid);
    final reqRef = guildRef.collection('joinRequests').doc(reqUid);
    final hunterRef = _firestore.collection('hunters').doc(reqUid);
    final playerRef = _firestore.collection('players').doc(reqUid);
    final lbRef = _firestore.collection('leaderboard').doc(reqUid);

    batch.set(memberRef, {
      'uid': reqUid,
      'username': request['username'],
      'hunterId': request['hunterId'],
      'displayName': request['displayName'],
      'level': request['level'],
      'rank': request['rank'],
      'role': 'member',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    batch.update(guildRef, {
      'memberCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.delete(reqRef);

    final updates = {
      'guildId': guildId,
      'guildRole': 'member',
      'guildName': guild['name'],
      'guildTag': guild['tag'],
      'updatedAt': FieldValue.serverTimestamp(),
    };

    batch.set(hunterRef, updates, SetOptions(merge: true));
    batch.set(playerRef, updates, SetOptions(merge: true));
    batch.set(lbRef, updates, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> rejectJoinRequest(String guildId, String reqUid) async {
    await _firestore.collection('guilds').doc(guildId).collection('joinRequests').doc(reqUid).delete();
  }

  Future<void> removeMember(String guildId, String memberUid) async {
    final batch = _firestore.batch();
    final guildRef = _firestore.collection('guilds').doc(guildId);
    final memberRef = guildRef.collection('members').doc(memberUid);
    final hunterRef = _firestore.collection('hunters').doc(memberUid);
    final playerRef = _firestore.collection('players').doc(memberUid);
    final lbRef = _firestore.collection('leaderboard').doc(memberUid);

    batch.delete(memberRef);
    batch.update(guildRef, {
      'memberCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final clearUpdates = {
      'guildId': null,
      'guildRole': null,
      'guildName': null,
      'guildTag': null,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    batch.set(hunterRef, clearUpdates, SetOptions(merge: true));
    batch.set(playerRef, clearUpdates, SetOptions(merge: true));
    batch.set(lbRef, clearUpdates, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> leaveGuild(String guildId, String uid, bool isLeader) async {
    final docSnap = await _firestore.collection('guilds').doc(guildId).get();
    final memberCount = (docSnap.data()?['memberCount'] as int?) ?? 1;

    final batch = _firestore.batch();
    final memberRef = _firestore.collection('guilds').doc(guildId).collection('members').doc(uid);
    final hunterRef = _firestore.collection('hunters').doc(uid);
    final playerRef = _firestore.collection('players').doc(uid);
    final lbRef = _firestore.collection('leaderboard').doc(uid);

    final clearUpdates = {
      'guildId': null,
      'guildRole': null,
      'guildName': null,
      'guildTag': null,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    batch.delete(memberRef);
    batch.set(hunterRef, clearUpdates, SetOptions(merge: true));
    batch.set(playerRef, clearUpdates, SetOptions(merge: true));
    batch.set(lbRef, clearUpdates, SetOptions(merge: true));

    if (isLeader && memberCount <= 1) {
      batch.delete(_firestore.collection('guilds').doc(guildId));
    } else {
      batch.update(_firestore.collection('guilds').doc(guildId), {
        'memberCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<void> updateGuildSettings(
    String guildId, {
    String? description,
    String? icon,
    String? joinType,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (description != null) updates['description'] = description.trim();
    if (icon != null) updates['icon'] = icon;
    if (joinType != null) updates['joinType'] = joinType;

    await _firestore.collection('guilds').doc(guildId).update(updates);
  }

  // ============================================================
  // STREAMS
  // ============================================================

  Stream<Map<String, dynamic>?> streamGuild(String guildId) {
    return _firestore
        .collection('guilds')
        .doc(guildId)
        .snapshots()
        .map((snap) => snap.data());
  }

  Stream<List<Map<String, dynamic>>> streamGuildMembers(String guildId) {
    return _firestore
        .collection('guilds')
        .doc(guildId)
        .collection('members')
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => d.data()).toList();
      list.sort((a, b) => ((b['level'] as int?) ?? 0).compareTo((a['level'] as int?) ?? 0));
      return list;
    });
  }

  Stream<List<Map<String, dynamic>>> streamGuildRequests(String guildId) {
    return _firestore
        .collection('guilds')
        .doc(guildId)
        .collection('joinRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }
}

