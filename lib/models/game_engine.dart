// Hunter System Core Game Engine — Dart Port
import 'dart:math';

// ============================================================
// DIFFICULTY SYSTEM
// ============================================================

enum DifficultyGrade { E, D, C, B, A, S }

const Map<DifficultyGrade, int> difficultyXp = {
  DifficultyGrade.E: 15,
  DifficultyGrade.D: 35,
  DifficultyGrade.C: 60,
  DifficultyGrade.B: 100,
  DifficultyGrade.A: 150,
  DifficultyGrade.S: 250,
};

const Map<DifficultyGrade, int> difficultyStatXp = {
  DifficultyGrade.E: 10,
  DifficultyGrade.D: 20,
  DifficultyGrade.C: 35,
  DifficultyGrade.B: 60,
  DifficultyGrade.A: 100,
  DifficultyGrade.S: 180,
};

String getDifficultyLabel(DifficultyGrade d) {
  switch (d) {
    case DifficultyGrade.E: return 'E-Class';
    case DifficultyGrade.D: return 'D-Class';
    case DifficultyGrade.C: return 'C-Class';
    case DifficultyGrade.B: return 'B-Class';
    case DifficultyGrade.A: return 'A-Class';
    case DifficultyGrade.S: return 'S-Class';
  }
}

String getDifficultyStars(DifficultyGrade d) {
  switch (d) {
    case DifficultyGrade.E: return '★☆☆☆☆☆';
    case DifficultyGrade.D: return '★★☆☆☆☆';
    case DifficultyGrade.C: return '★★★☆☆☆';
    case DifficultyGrade.B: return '★★★★☆☆';
    case DifficultyGrade.A: return '★★★★★☆';
    case DifficultyGrade.S: return '★★★★★★';
  }
}

int getDifficultyColor(DifficultyGrade d) {
  switch (d) {
    case DifficultyGrade.E: return 0xFF94a3b8;
    case DifficultyGrade.D: return 0xFF10b981;
    case DifficultyGrade.C: return 0xFF3b82f6;
    case DifficultyGrade.B: return 0xFFa855f7;
    case DifficultyGrade.A: return 0xFFeab308;
    case DifficultyGrade.S: return 0xFFec4899;
  }
}

// ============================================================
// QUEST CATEGORIES
// ============================================================

enum QuestCategory {
  physical, mental, knowledge, coding, study, health,
  discipline, productivity, social, creative, financial,
  personalDevelopment, custom, fitness, learning
}

String getCategoryLabel(QuestCategory c) {
  switch (c) {
    case QuestCategory.physical: return 'PHYSICAL';
    case QuestCategory.mental: return 'MENTAL';
    case QuestCategory.knowledge: return 'KNOWLEDGE';
    case QuestCategory.coding: return 'CODING';
    case QuestCategory.study: return 'STUDY';
    case QuestCategory.health: return 'HEALTH';
    case QuestCategory.discipline: return 'DISCIPLINE';
    case QuestCategory.productivity: return 'PRODUCTIVITY';
    case QuestCategory.social: return 'SOCIAL';
    case QuestCategory.creative: return 'CREATIVE';
    case QuestCategory.financial: return 'FINANCIAL';
    case QuestCategory.personalDevelopment: return 'PERSONAL DEV';
    case QuestCategory.custom: return 'CUSTOM';
    case QuestCategory.fitness: return 'FITNESS';
    case QuestCategory.learning: return 'LEARNING';
  }
}

enum StatXpType { physical, mental, both, none }

StatXpType getStatXpType(QuestCategory category) {
  switch (category) {
    case QuestCategory.physical:
    case QuestCategory.fitness:
    case QuestCategory.health:
      return StatXpType.physical;
    case QuestCategory.mental:
    case QuestCategory.knowledge:
    case QuestCategory.learning:
    case QuestCategory.coding:
    case QuestCategory.study:
    case QuestCategory.productivity:
      return StatXpType.mental;
    case QuestCategory.discipline:
    case QuestCategory.personalDevelopment:
      return StatXpType.both;
    default:
      return StatXpType.none;
  }
}

// ============================================================
// HP / MP
// ============================================================

const int hpIncreasePerThreshold = 12;
const int mpIncreasePerThreshold = 10;
const int xpThreshold = 500;

const Map<String, int> hpByRank = {
  'E-Rank': 100, 'D-Rank': 130, 'C-Rank': 170,
  'B-Rank': 220, 'A-Rank': 290, 'S-Rank': 400,
};

const Map<String, int> mpByRank = {
  'E-Rank': 100, 'D-Rank': 125, 'C-Rank': 160,
  'B-Rank': 210, 'A-Rank': 280, 'S-Rank': 400,
};

int calculateMaxHp(int physicalXp, String rank) {
  final rankBase = hpByRank[rank] ?? 100;
  final thresholdsPassed = physicalXp ~/ xpThreshold;
  return rankBase + thresholdsPassed * hpIncreasePerThreshold;
}

int calculateMaxMp(int mentalXp, String rank) {
  final rankBase = mpByRank[rank] ?? 100;
  final thresholdsPassed = mentalXp ~/ xpThreshold;
  return rankBase + thresholdsPassed * mpIncreasePerThreshold;
}

// ============================================================
// HUNTER STATS
// ============================================================

// ignore: constant_identifier_names
enum HunterStat { STR, AGI, VIT, INT, PERC }

class StatDefinition {
  final HunterStat code;
  final String name;
  final String title;
  final String description;
  final int color;
  final int accentGlow;

  const StatDefinition({
    required this.code,
    required this.name,
    required this.title,
    required this.description,
    required this.color,
    required this.accentGlow,
  });
}

const Map<HunterStat, StatDefinition> hunterStats = {
  HunterStat.STR: StatDefinition(
    code: HunterStat.STR,
    name: 'Strength',
    title: 'Physical Might & Power',
    description: 'Increases muscular strength, physical impact, and capacity to overcome high-resistance trials.',
    color: 0xFFef4444,
    accentGlow: 0x66ef4444,
  ),
  HunterStat.AGI: StatDefinition(
    code: HunterStat.AGI,
    name: 'Agility',
    title: 'Speed & Reflexes',
    description: 'Enhances reaction time, cardiovascular endurance, flexibility, and swift execution.',
    color: 0xFF06b6d4,
    accentGlow: 0x6606b6d4,
  ),
  HunterStat.VIT: StatDefinition(
    code: HunterStat.VIT,
    name: 'Vitality',
    title: 'Health & Resilience',
    description: 'Boosts stamina, immune constitution, sleep restoration, and physical durability.',
    color: 0xFF10b981,
    accentGlow: 0x6610b981,
  ),
  HunterStat.INT: StatDefinition(
    code: HunterStat.INT,
    name: 'Intelligence',
    title: 'Knowledge & Intellect',
    description: 'Sharpens deep work focus, mental acuity, logic, cognitive retention, and learning capacity.',
    color: 0xFF8b5cf6,
    accentGlow: 0x668b5cf6,
  ),
  HunterStat.PERC: StatDefinition(
    code: HunterStat.PERC,
    name: 'Perception',
    title: 'Awareness & Discipline',
    description: 'Elevates mindfulness, self-mastery, focus clarity, intuition, and distraction resistance.',
    color: 0xFFf59e0b,
    accentGlow: 0x66f59e0b,
  ),
};

// ============================================================
// XP / LEVEL / RANK
// ============================================================

int getXpForLevel(int level) {
  if (level <= 1) return 0;
  return (50 * pow(level - 1, 1.5) * 1.5 + (level - 1) * 75).floor();
}

int calculateLevel(int xp) {
  if (xp <= 0) return 1;
  int level = 1;
  while (getXpForLevel(level + 1) <= xp) {
    level++;
    if (level >= 999) break;
  }
  return level;
}

String calculateRank(int level) {
  if (level >= 95) return 'S-Rank';
  if (level >= 70) return 'A-Rank';
  if (level >= 45) return 'B-Rank';
  if (level >= 25) return 'C-Rank';
  if (level >= 10) return 'D-Rank';
  return 'E-Rank';
}

({String label, int color}) getRankBadgeInfo(String rank) {
  switch (rank) {
    case 'S-Rank': return (label: 'S-RANK', color: 0xFFec4899);
    case 'A-Rank': return (label: 'A-RANK', color: 0xFFeab308);
    case 'B-Rank': return (label: 'B-RANK', color: 0xFFa855f7);
    case 'C-Rank': return (label: 'C-RANK', color: 0xFF3b82f6);
    case 'D-Rank': return (label: 'D-RANK', color: 0xFF10b981);
    default: return (label: 'E-RANK', color: 0xFF94a3b8);
  }
}

({int currentLevel, int currentProgressXp, int xpNeededForNext, int percentage, int totalXp}) getXpProgress(int xp) {
  final currentLevel = calculateLevel(xp);
  final currentLevelBaseXp = getXpForLevel(currentLevel);
  final nextLevelBaseXp = getXpForLevel(currentLevel + 1);
  final xpNeededForNext = nextLevelBaseXp - currentLevelBaseXp;
  final currentProgressXp = max(0, xp - currentLevelBaseXp);
  final percentage = xpNeededForNext > 0 ? min(100, (currentProgressXp * 100 / xpNeededForNext).round()) : 0;

  return (
    currentLevel: currentLevel,
    currentProgressXp: currentProgressXp,
    xpNeededForNext: xpNeededForNext,
    percentage: percentage,
    totalXp: xp,
  );
}

// ============================================================
// STREAK BONUSES
// ============================================================

int getStreakBonus(int streak) {
  if (streak >= 100) return 200;
  if (streak >= 60) return 150;
  if (streak >= 30) return 100;
  if (streak >= 14) return 50;
  if (streak >= 7) return 20;
  return 0;
}

double getStreakBonusMultiplier(int streak) {
  return 1 + getStreakBonus(streak) / 100;
}

// ============================================================
// HUNTER ID GENERATOR
// ============================================================

String generateHunterId(String userId, String affinity) {
  final cleanId = userId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
  var first6 = cleanId.length >= 6 ? cleanId.substring(0, 6) : cleanId;
  if (first6.length < 6) {
    final rng = Random();
    final fallback = List.generate(8, (_) => '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'[rng.nextInt(36)]).join();
    first6 = (first6 + fallback).substring(0, 6);
  }
  final cleanAffinity = affinity.toUpperCase().trim();
  return 'HUNTER-$first6-$cleanAffinity';
}

// ============================================================
// QUEST MODEL
// ============================================================

class Quest {
  final String id;
  final String name;
  final String? description;
  final DifficultyGrade difficulty;
  final QuestCategory category;
  final HunterStat stat;
  int progress;
  final int target;
  bool completed;
  final int xpReward;
  final int statXpReward;
  final StatXpType statXpType;
  final bool isCustom;

  Quest({
    required this.id,
    required this.name,
    this.description,
    required this.difficulty,
    required this.category,
    required this.stat,
    this.progress = 0,
    required this.target,
    this.completed = false,
    int? xpReward,
    int? statXpReward,
    StatXpType? statXpType,
    this.isCustom = false,
  }) : xpReward = xpReward ?? (difficultyXp[difficulty] ?? 15),
       statXpReward = statXpReward ?? (difficultyStatXp[difficulty] ?? 10),
       statXpType = statXpType ?? getStatXpType(category);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'difficulty': difficulty.index,
    'category': category.index,
    'stat': stat.index,
    'progress': progress,
    'target': target,
    'completed': completed,
    'xpReward': xpReward,
    'statXpReward': statXpReward,
    'statXpType': statXpType.index,
    'isCustom': isCustom,
  };

  factory Quest.fromJson(Map<String, dynamic> json) => Quest(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    difficulty: DifficultyGrade.values[json['difficulty'] as int],
    category: QuestCategory.values[json['category'] as int],
    stat: HunterStat.values[json['stat'] as int],
    progress: json['progress'] as int? ?? 0,
    target: json['target'] as int,
    completed: json['completed'] as bool? ?? false,
    xpReward: json['xpReward'] as int?,
    statXpReward: json['statXpReward'] as int?,
    statXpType: json['statXpType'] != null ? StatXpType.values[json['statXpType'] as int] : null,
    isCustom: json['isCustom'] as bool? ?? false,
  );
}

// ============================================================
// SYSTEM LOG
// ============================================================

class SystemLogEntry {
  final String id;
  final int timestamp;
  final String eventType;
  final String message;
  final int? xp;

  SystemLogEntry({
    required this.id,
    required this.timestamp,
    required this.eventType,
    required this.message,
    this.xp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp,
    'eventType': eventType,
    'message': message,
    'xp': xp,
  };

  factory SystemLogEntry.fromJson(Map<String, dynamic> json) => SystemLogEntry(
    id: json['id'] as String,
    timestamp: json['timestamp'] as int,
    eventType: json['eventType'] as String,
    message: json['message'] as String,
    xp: json['xp'] as int?,
  );
}

// ============================================================
// PROFILE MODEL
// ============================================================

class HunterProfile {
  String id;
  String hunterId;
  String displayName;
  int totalXp;
  int currentLevel;
  Map<HunterStat, int> stats;
  String currentRank;
  String affinity;

  int hp;
  int mp;
  int maxHp;
  int maxMp;
  int physicalXp;
  int mentalXp;

  int questsCompleted;
  int physicalQuestsCompleted;
  int mentalQuestsCompleted;
  int codingQuestsCompleted;

  int streak;
  int physicalStreak;
  int mentalStreak;
  int studyStreak;
  int codingStreak;
  int perfectDayStreak;
  int longestStreak;
  String? lastQuestDate;

  List<String> titles;
  String equippedTitle;
  List<String> badges;
  Map<String, int> skillPoints;
  int availableSkillPoints;

  List<SystemLogEntry> systemLog;

  HunterProfile({
    required this.id,
    required this.hunterId,
    required this.displayName,
    this.totalXp = 15,
    this.currentLevel = 1,
    Map<HunterStat, int>? stats,
    this.currentRank = 'E-Rank',
    this.affinity = 'AGI',
    this.hp = 100,
    this.mp = 100,
    this.maxHp = 100,
    this.maxMp = 100,
    this.physicalXp = 0,
    this.mentalXp = 0,
    this.questsCompleted = 0,
    this.physicalQuestsCompleted = 0,
    this.mentalQuestsCompleted = 0,
    this.codingQuestsCompleted = 0,
    this.streak = 1,
    this.physicalStreak = 0,
    this.mentalStreak = 0,
    this.studyStreak = 0,
    this.codingStreak = 0,
    this.perfectDayStreak = 0,
    this.longestStreak = 1,
    this.lastQuestDate,
    List<String>? titles,
    this.equippedTitle = '',
    List<String>? badges,
    Map<String, int>? skillPoints,
    this.availableSkillPoints = 0,
    List<SystemLogEntry>? systemLog,
  }) : stats = stats ?? {
         HunterStat.STR: 10, HunterStat.AGI: 10,
         HunterStat.VIT: 10, HunterStat.INT: 10, HunterStat.PERC: 10,
       },
       titles = titles ?? [],
       badges = badges ?? ['first_blood'],
       skillPoints = skillPoints ?? {
         'strength': 0, 'intelligence': 0, 'endurance': 0,
         'discipline': 0, 'focus': 0, 'agility': 0,
       },
       systemLog = systemLog ?? [
         SystemLogEntry(
           id: 'log-init',
           timestamp: DateTime.now().millisecondsSinceEpoch,
           eventType: 'quest_complete',
           message: 'System Awakening complete. Hunter registered.',
         ),
       ];

  Map<String, dynamic> toJson() => {
    'id': id,
    'hunterId': hunterId,
    'displayName': displayName,
    'totalXp': totalXp,
    'currentLevel': currentLevel,
    'stats': stats.map((k, v) => MapEntry(k.index.toString(), v)),
    'currentRank': currentRank,
    'affinity': affinity,
    'hp': hp, 'mp': mp, 'maxHp': maxHp, 'maxMp': maxMp,
    'physicalXp': physicalXp, 'mentalXp': mentalXp,
    'questsCompleted': questsCompleted,
    'physicalQuestsCompleted': physicalQuestsCompleted,
    'mentalQuestsCompleted': mentalQuestsCompleted,
    'codingQuestsCompleted': codingQuestsCompleted,
    'streak': streak, 'physicalStreak': physicalStreak,
    'mentalStreak': mentalStreak, 'studyStreak': studyStreak,
    'codingStreak': codingStreak, 'perfectDayStreak': perfectDayStreak,
    'longestStreak': longestStreak, 'lastQuestDate': lastQuestDate,
    'titles': titles, 'equippedTitle': equippedTitle,
    'badges': badges, 'skillPoints': skillPoints,
    'availableSkillPoints': availableSkillPoints,
    'systemLog': systemLog.map((e) => e.toJson()).toList(),
  };

  factory HunterProfile.fromJson(Map<String, dynamic> json) {
    final statsMap = <HunterStat, int>{};
    if (json['stats'] != null) {
      (json['stats'] as Map<String, dynamic>).forEach((k, v) {
        statsMap[HunterStat.values[int.parse(k)]] = v as int;
      });
    }

    return HunterProfile(
      id: json['id'] as String,
      hunterId: json['hunterId'] as String,
      displayName: json['displayName'] as String,
      totalXp: json['totalXp'] as int? ?? 15,
      currentLevel: json['currentLevel'] as int? ?? 1,
      stats: statsMap.isNotEmpty ? statsMap : null,
      currentRank: json['currentRank'] as String? ?? 'E-Rank',
      affinity: json['affinity'] as String? ?? 'AGI',
      hp: json['hp'] as int? ?? 100,
      mp: json['mp'] as int? ?? 100,
      maxHp: json['maxHp'] as int? ?? 100,
      maxMp: json['maxMp'] as int? ?? 100,
      physicalXp: json['physicalXp'] as int? ?? 0,
      mentalXp: json['mentalXp'] as int? ?? 0,
      questsCompleted: json['questsCompleted'] as int? ?? 0,
      physicalQuestsCompleted: json['physicalQuestsCompleted'] as int? ?? 0,
      mentalQuestsCompleted: json['mentalQuestsCompleted'] as int? ?? 0,
      codingQuestsCompleted: json['codingQuestsCompleted'] as int? ?? 0,
      streak: json['streak'] as int? ?? 1,
      physicalStreak: json['physicalStreak'] as int? ?? 0,
      mentalStreak: json['mentalStreak'] as int? ?? 0,
      studyStreak: json['studyStreak'] as int? ?? 0,
      codingStreak: json['codingStreak'] as int? ?? 0,
      perfectDayStreak: json['perfectDayStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 1,
      lastQuestDate: json['lastQuestDate'] as String?,
      titles: (json['titles'] as List?)?.cast<String>() ?? [],
      equippedTitle: json['equippedTitle'] as String? ?? '',
      badges: (json['badges'] as List?)?.cast<String>() ?? ['first_blood'],
      skillPoints: (json['skillPoints'] as Map<String, dynamic>?)?.cast<String, int>(),
      availableSkillPoints: json['availableSkillPoints'] as int? ?? 0,
      systemLog: (json['systemLog'] as List?)
          ?.map((e) => SystemLogEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
