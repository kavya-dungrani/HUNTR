import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_engine.dart';
import '../models/quest_library.dart';
import '../models/achievements.dart';
import '../models/daily_system.dart';
import '../services/firebase_service.dart';
import '../services/audio_service.dart';

class HunterProvider extends ChangeNotifier {
  HunterProfile? _profile;
  List<Quest> _quests = [];
  List<Quest> _dailyQuests = [];
  DungeonBreak? _activeDungeon;
  Quest? _activeBonus;
  List<String> _unlockedAchievements = ['first_blood'];
  bool _isLoading = true;

  // Level Up State for Animated Dialog
  bool _showLevelUpModal = false;
  int _leveledUpTo = 1;
  String _newRankAchieved = '';

  HunterProfile? get profile => _profile;
  bool get isOnboarded => _profile != null;
  List<Quest> get quests => _quests;
  List<Quest> get dailyQuests => _dailyQuests;
  DungeonBreak? get activeDungeon => _activeDungeon;
  Quest? get activeBonus => _activeBonus;
  List<String> get unlockedAchievements => _unlockedAchievements;
  bool get isLoading => _isLoading;

  bool get showLevelUpModal => _showLevelUpModal;
  int get leveledUpTo => _leveledUpTo;
  String get newRankAchieved => _newRankAchieved;

  void dismissLevelUpModal() {
    _showLevelUpModal = false;
    notifyListeners();
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final loadedProfile = await FirebaseService.instance.loadProfile();
      if (loadedProfile != null) {
        _profile = loadedProfile;
        _quests = await FirebaseService.instance.loadQuests();
        _activeDungeon = await FirebaseService.instance.loadDungeonBreak();
        _unlockedAchievements = await FirebaseService.instance.loadAchievements();

        // If no daily quests, generate them
        if (_dailyQuests.isEmpty) {
          _dailyQuests = DailySystem.generateDailyQuests(_profile!.currentRank);
        }

        // Check if dungeon break expired or needs creation
        if (_activeDungeon == null || _activeDungeon!.isExpired) {
          _activeDungeon = DailySystem.generateDungeonBreak(_profile!.currentRank);
          await FirebaseService.instance.saveDungeonBreak(_activeDungeon);
        }

        _activeBonus = DailySystem.generateDailyBonusQuest(_profile!.currentRank);
      }
    } catch (e) {
      debugPrint('HunterProvider initialize error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

    bool get isAuthenticated => FirebaseService.instance.currentUser != null || _profile != null;

  // ================= AWAKENING / LOGIN / AUTH =================

  void _createDefaultProfileAndQuests(String uid, String name, String affinity) {
    final hunterId = generateHunterId(uid, affinity);

    final stats = {
      HunterStat.STR: affinity == 'STR' ? 15 : 10,
      HunterStat.AGI: affinity == 'AGI' ? 15 : 10,
      HunterStat.VIT: affinity == 'VIT' ? 15 : 10,
      HunterStat.INT: affinity == 'INT' ? 15 : 10,
      HunterStat.PERC: affinity == 'PERC' ? 15 : 10,
    };

    _profile = HunterProfile(
      id: uid,
      hunterId: hunterId,
      displayName: name,
      totalXp: 50,
      currentLevel: 1,
      stats: stats,
      currentRank: 'E-Rank',
      affinity: affinity,
      hp: 100,
      mp: 100,
      maxHp: 100,
      maxMp: 100,
      titles: ['The Awakened'],
      equippedTitle: 'The Awakened',
      availableSkillPoints: 3,
    );

    _quests = [
      questLibrary[0].toQuest(), // 20 Pushups
      questLibrary[8].toQuest(), // 30s Plank
      questLibrary[15].toQuest(), // LeetCode 1
      questLibrary[21].toQuest(), // Read 20 pages
    ];

    _dailyQuests = DailySystem.generateDailyQuests('E-Rank');
    _activeDungeon = DailySystem.generateDungeonBreak('E-Rank');
    _activeBonus = DailySystem.generateDailyBonusQuest('E-Rank');
    _unlockedAchievements = ['first_blood'];
  }

  Future<void> loginWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cred = await FirebaseService.instance.signInWithEmail(
        email: email,
        password: password,
      );

      final loaded = await FirebaseService.instance.loadProfile();
      if (loaded != null) {
        _profile = loaded;
        _quests = await FirebaseService.instance.loadQuests();
        _activeDungeon = await FirebaseService.instance.loadDungeonBreak();
        _unlockedAchievements = await FirebaseService.instance.loadAchievements();
        if (_dailyQuests.isEmpty) {
          _dailyQuests = DailySystem.generateDailyQuests(_profile!.currentRank);
        }
        if (_activeDungeon == null || _activeDungeon!.isExpired) {
          _activeDungeon = DailySystem.generateDungeonBreak(_profile!.currentRank);
          await FirebaseService.instance.saveDungeonBreak(_activeDungeon);
        }
        _activeBonus = DailySystem.generateDailyBonusQuest(_profile!.currentRank);
      } else {
        final uid = cred.user?.uid ?? 'hunter_${DateTime.now().millisecondsSinceEpoch}';
        final name = cred.user?.displayName?.isNotEmpty == true 
            ? cred.user!.displayName! 
            : email.split('@').first;
        _createDefaultProfileAndQuests(uid, name, 'AGI');
        await _saveState();
      }

      AudioService.instance.playLevelUp();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String affinity,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cred = await FirebaseService.instance.signUpWithEmail(
        email: email,
        password: password,
        displayName: name,
      );

      final uid = cred.user?.uid ?? 'hunter_${DateTime.now().millisecondsSinceEpoch}';
      _createDefaultProfileAndQuests(uid, name, affinity);
      AudioService.instance.playAwakening();
      await _saveState();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle({String preferredAffinity = 'AGI'}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final cred = await FirebaseService.instance.signInWithGoogle();
      if (cred != null) {
        final loaded = await FirebaseService.instance.loadProfile();
        if (loaded != null) {
          _profile = loaded;
          _quests = await FirebaseService.instance.loadQuests();
          _activeDungeon = await FirebaseService.instance.loadDungeonBreak();
          _unlockedAchievements = await FirebaseService.instance.loadAchievements();
          if (_dailyQuests.isEmpty) {
            _dailyQuests = DailySystem.generateDailyQuests(_profile!.currentRank);
          }
          if (_activeDungeon == null || _activeDungeon!.isExpired) {
            _activeDungeon = DailySystem.generateDungeonBreak(_profile!.currentRank);
            await FirebaseService.instance.saveDungeonBreak(_activeDungeon);
          }
          _activeBonus = DailySystem.generateDailyBonusQuest(_profile!.currentRank);
        } else {
          final uid = cred.user?.uid ?? 'hunter_${DateTime.now().millisecondsSinceEpoch}';
          final name = cred.user?.displayName?.isNotEmpty == true 
              ? cred.user!.displayName! 
              : 'Awakened Hunter';
          _createDefaultProfileAndQuests(uid, name, preferredAffinity);
          await _saveState();
        }
        AudioService.instance.playAwakening();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> awakenHunter({
    required String name,
    required String affinity,
    String? email,
    String? password,
    bool isAnonymous = false,
  }) async {
    _isLoading = true;
    notifyListeners();

    String uid = 'hunter_${DateTime.now().millisecondsSinceEpoch}';

    try {
      if (isAnonymous) {
        final cred = await FirebaseService.instance.signInAnonymously();
        uid = cred.user?.uid ?? uid;
      } else if (email != null && password != null && email.isNotEmpty && password.isNotEmpty) {
        try {
          final cred = await FirebaseService.instance.signUpWithEmail(
            email: email,
            password: password,
            displayName: name,
          );
          uid = cred.user?.uid ?? uid;
        } catch (_) {
          try {
            final cred = await FirebaseService.instance.signInWithEmail(
              email: email,
              password: password,
            );
            uid = cred.user?.uid ?? uid;
          } catch (_) {}
        }
      }
    } catch (_) {}

    _createDefaultProfileAndQuests(uid, name, affinity);
    AudioService.instance.playAwakening();
    await _saveState();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOutHunter() async {
    _isLoading = true;
    notifyListeners();
    try {
      await FirebaseService.instance.signOut();
      _profile = null;
      _quests = [];
      _dailyQuests = [];
      _activeDungeon = null;
      _activeBonus = null;
      _unlockedAchievements = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ================= QUEST ACTIONS =================

  void completeQuest(String questId) {
    if (_profile == null) return;

    Quest? found;
    // Check active quests
    final qIndex = _quests.indexWhere((q) => q.id == questId);
    if (qIndex != -1) {
      found = _quests[qIndex];
      found.progress = found.target;
      found.completed = true;
    } else {
      // Check daily quests
      final dIndex = _dailyQuests.indexWhere((q) => q.id == questId);
      if (dIndex != -1) {
        found = _dailyQuests[dIndex];
        found.progress = found.target;
        found.completed = true;
      } else if (_activeBonus != null && _activeBonus!.id == questId) {
        found = _activeBonus;
        found!.progress = found.target;
        found.completed = true;
      }
    }

    if (found == null) return;

    // Apply streak multiplier
    final multiplier = getStreakBonusMultiplier(_profile!.streak);
    final earnedXp = (found.xpReward * multiplier).round();
    final earnedStatXp = found.statXpReward;

    _profile!.questsCompleted += 1;
    if (found.category == QuestCategory.physical || found.category == QuestCategory.fitness) {
      _profile!.physicalQuestsCompleted += 1;
      _profile!.physicalXp += earnedStatXp;
    } else if (found.category == QuestCategory.coding) {
      _profile!.codingQuestsCompleted += 1;
      _profile!.mentalXp += earnedStatXp;
    } else {
      _profile!.mentalQuestsCompleted += 1;
      _profile!.mentalXp += earnedStatXp;
    }

    // Boost the associated stat directly
    final currentStatVal = _profile!.stats[found.stat] ?? 10;
    _profile!.stats[found.stat] = currentStatVal + 1;

    // Update HP/MP
    _profile!.maxHp = calculateMaxHp(_profile!.physicalXp, _profile!.currentRank);
    _profile!.maxMp = calculateMaxMp(_profile!.mentalXp, _profile!.currentRank);
    _profile!.hp = min(_profile!.maxHp, _profile!.hp + 20);
    _profile!.mp = min(_profile!.maxMp, _profile!.mp + 15);

    // Add total XP
    _addXp(earnedXp, source: found.name);

    // Audio & Haptic Feedback
    AudioService.instance.playSuccess();

    // Check Achievements
    _checkAchievements();

    _saveState();
    notifyListeners();
  }

  void incrementProgress(String questId, [int amount = 1]) {
    Quest? found;
    final qIndex = _quests.indexWhere((q) => q.id == questId);
    if (qIndex != -1) {
      found = _quests[qIndex];
    } else {
      final dIndex = _dailyQuests.indexWhere((q) => q.id == questId);
      if (dIndex != -1) {
        found = _dailyQuests[dIndex];
      }
    }

    if (found == null || found.completed) return;

    found.progress = min(found.target, found.progress + amount);
    AudioService.instance.playClick();

    if (found.progress >= found.target) {
      completeQuest(questId);
    } else {
      _saveState();
      notifyListeners();
    }
  }

  void acceptLibraryQuest(LibraryQuest libQuest) {
    _quests.add(libQuest.toQuest());
    AudioService.instance.playClick();
    _saveState();
    notifyListeners();
  }

  void addCustomQuest(Quest quest) {
    _quests.add(quest);
    AudioService.instance.playClick();
    _saveState();
    notifyListeners();
  }

  void deleteQuest(String questId) {
    _quests.removeWhere((q) => q.id == questId);
    AudioService.instance.playClick();
    _saveState();
    notifyListeners();
  }

  // ================= DUNGEON BREAK =================

  void completeDungeonBreak() {
    if (_profile == null || _activeDungeon == null) return;
    final dungeon = _activeDungeon!;
    dungeon.completed = true;

    _addXp(dungeon.xpReward, source: dungeon.challenge);

    // Boost all stats by 2
    _profile!.stats.forEach((key, value) {
      _profile!.stats[key] = value + 2;
    });

    _profile!.systemLog.insert(
      0,
      SystemLogEntry(
        id: 'dungeon_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        eventType: 'dungeon_cleared',
        message: 'DUNGEON CONQUERED: ${dungeon.challenge}',
        xp: dungeon.xpReward,
      ),
    );

    AudioService.instance.playLevelUp();
    _activeDungeon = null;
    _checkAchievements();
    _saveState();
    notifyListeners();
  }

  void dismissDungeonBreak() {
    if (_activeDungeon != null) {
      _activeDungeon!.dismissed = true;
      _activeDungeon = null;
      AudioService.instance.playClick();
      _saveState();
      notifyListeners();
    }
  }

  // ================= STAT & SKILL ALLOCATION =================

  void allocateStatPoint(HunterStat stat) {
    if (_profile == null || _profile!.availableSkillPoints <= 0) return;
    _profile!.availableSkillPoints -= 1;
    _profile!.stats[stat] = (_profile!.stats[stat] ?? 10) + 1;
    AudioService.instance.playClick();
    _checkAchievements();
    _saveState();
    notifyListeners();
  }

  void allocateSkillPoint(String skillKey) {
    if (_profile == null || _profile!.availableSkillPoints <= 0) return;
    _profile!.availableSkillPoints -= 1;
    _profile!.skillPoints[skillKey] = (_profile!.skillPoints[skillKey] ?? 0) + 1;
    AudioService.instance.playClick();
    _saveState();
    notifyListeners();
  }

  void equipTitle(String title) {
    if (_profile == null) return;
    _profile!.equippedTitle = title;
    AudioService.instance.playClick();
    _saveState();
    notifyListeners();
  }

  // ================= INTERNAL ENGINE LOGIC =================

  void _addXp(int amount, {String source = 'Quest'}) {
    if (_profile == null) return;
    final oldLevel = _profile!.currentLevel;
    final oldRank = _profile!.currentRank;

    _profile!.totalXp += amount;
    final newLevel = calculateLevel(_profile!.totalXp);
    final newRank = calculateRank(newLevel);

    _profile!.currentLevel = newLevel;
    _profile!.currentRank = newRank;

    // Check Level Up
    if (newLevel > oldLevel) {
      final levelsGained = newLevel - oldLevel;
      _profile!.availableSkillPoints += levelsGained * 3;
      _leveledUpTo = newLevel;
      _newRankAchieved = newRank != oldRank ? newRank : '';
      _showLevelUpModal = true;
      AudioService.instance.playLevelUp();
    }

    // Add to system log
    _profile!.systemLog.insert(
      0,
      SystemLogEntry(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        eventType: 'quest_complete',
        message: 'Completed: $source (+$amount XP)',
        xp: amount,
      ),
    );
  }

  void _checkAchievements() {
    if (_profile == null) return;
    for (final ach in allAchievements) {
      if (!_unlockedAchievements.contains(ach.id)) {
        if (ach.checkUnlocked(_profile!, _quests)) {
          _unlockedAchievements.add(ach.id);
          _addXp(ach.xpReward, source: 'Achievement: ${ach.name}');
          if (ach.titleUnlock != null && !_profile!.titles.contains(ach.titleUnlock!)) {
            _profile!.titles.add(ach.titleUnlock!);
          }
          if (ach.badgeId != null && !_profile!.badges.contains(ach.badgeId!)) {
            _profile!.badges.add(ach.badgeId!);
          }
        }
      }
    }
    FirebaseService.instance.saveAchievements(_unlockedAchievements);
  }

  Future<void> _saveState() async {
    if (_profile != null) {
      await FirebaseService.instance.saveProfile(_profile!);
      await FirebaseService.instance.saveQuests(_quests);
      await FirebaseService.instance.saveDungeonBreak(_activeDungeon);
    }
  }

  Future<void> resetHunter() async {
    await FirebaseService.instance.clearAll();
    _profile = null;
    _quests = [];
    _dailyQuests = [];
    _activeDungeon = null;
    _activeBonus = null;
    _unlockedAchievements = [];
    notifyListeners();
  }
}
