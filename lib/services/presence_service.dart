import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceService with WidgetsBindingObserver {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  String? _currentUid;
  Timer? _heartbeatTimer;
  bool _isInitialized = false;

  static const int presenceTimeoutMs = 90000; // 90 seconds

  void start(String uid) {
    if (_currentUid == uid && _isInitialized) return;

    _currentUid = uid;
    if (!_isInitialized) {
      WidgetsBinding.instance.addObserver(this);
      _isInitialized = true;
    }

    _setOnline();
    _startHeartbeat();
  }

  void stop() {
    _stopHeartbeat();
    _setOffline();
    _currentUid = null;
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_currentUid != null) {
        _setOnline();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _setOnline() async {
    final uid = _currentUid;
    if (uid == null) return;
    try {
      await _firestore.collection('presence').doc(uid).set({
        'state': 'online',
        'lastSeen': FieldValue.serverTimestamp(),
        'client': 'flutter',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> _setOffline() async {
    final uid = _currentUid;
    if (uid == null) return;
    try {
      await _firestore.collection('presence').doc(uid).set({
        'state': 'offline',
        'lastSeen': FieldValue.serverTimestamp(),
        'client': 'flutter',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_currentUid == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _setOnline();
        _startHeartbeat();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _stopHeartbeat();
        _setOffline();
        break;
    }
  }

  static bool isUserOnline(Map<String, dynamic>? data) {
    if (data == null) return false;
    if (data['state'] != 'online') return false;

    final lastSeen = data['lastSeen'];
    if (lastSeen == null) return true;

    int lastSeenMillis = 0;
    if (lastSeen is Timestamp) {
      lastSeenMillis = lastSeen.millisecondsSinceEpoch;
    } else if (lastSeen is int) {
      lastSeenMillis = lastSeen;
    } else if (lastSeen is DateTime) {
      lastSeenMillis = lastSeen.millisecondsSinceEpoch;
    }

    if (lastSeenMillis == 0) return true;
    return DateTime.now().millisecondsSinceEpoch - lastSeenMillis < presenceTimeoutMs;
  }

  Stream<bool> streamUserPresence(String uid) {
    return _firestore
        .collection('presence')
        .doc(uid)
        .snapshots()
        .map((doc) => isUserOnline(doc.data()));
  }
}

