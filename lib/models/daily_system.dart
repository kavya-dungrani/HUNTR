import 'dart:math';
import 'game_engine.dart';
import 'quest_library.dart';

class DungeonBreak {
  final String id;
  final String rank;
  final String challenge;
  final int timeLimitHours;
  final int xpReward;
  final int statXpReward;
  final int createdAt;
  final int expiresAt;
  bool completed;
  bool dismissed;

  DungeonBreak({
    required this.id,
    required this.rank,
    required this.challenge,
    this.timeLimitHours = 24,
    required this.xpReward,
    required this.statXpReward,
    required this.createdAt,
    required this.expiresAt,
    this.completed = false,
    this.dismissed = false,
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;

  int get remainingSeconds {
    final diff = (expiresAt - DateTime.now().millisecondsSinceEpoch) ~/ 1000;
    return max(0, diff);
  }

  String get formattedRemainingTime {
    final secs = remainingSeconds;
    final hours = secs ~/ 3600;
    final mins = (secs % 3600) ~/ 60;
    final s = secs % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'rank': rank,
    'challenge': challenge,
    'timeLimitHours': timeLimitHours,
    'xpReward': xpReward,
    'statXpReward': statXpReward,
    'createdAt': createdAt,
    'expiresAt': expiresAt,
    'completed': completed,
    'dismissed': dismissed,
  };

  factory DungeonBreak.fromJson(Map<String, dynamic> json) => DungeonBreak(
    id: json['id'] as String,
    rank: json['rank'] as String,
    challenge: json['challenge'] as String,
    timeLimitHours: json['timeLimitHours'] as int? ?? 24,
    xpReward: json['xpReward'] as int,
    statXpReward: json['statXpReward'] as int,
    createdAt: json['createdAt'] as int,
    expiresAt: json['expiresAt'] as int,
    completed: json['completed'] as bool? ?? false,
    dismissed: json['dismissed'] as bool? ?? false,
  );
}

const Map<String, ({String challenge, int xp, int statXp})> dungeonChallenges = {
  'E-Rank': (
    challenge: 'EMERGENCY GATE: Complete 50 push-ups + 30 squats + 10-minute jog within 24 hours.',
    xp: 500,
    statXp: 200,
  ),
  'D-Rank': (
    challenge: 'D-RANK RED GATE: Solve 3 LeetCode mediums + study for 1 hour within 24 hours.',
    xp: 800,
    statXp: 300,
  ),
  'C-Rank': (
    challenge: 'C-RANK HIGH ORC LAIR: Complete 100 push-ups AND solve 5 algorithm problems within 24 hours.',
    xp: 1200,
    statXp: 450,
  ),
  'B-Rank': (
    challenge: 'B-RANK ICE ELVES GATE: 1-hour extreme physical trial AND 2 hours deep architectural code.',
    xp: 1600,
    statXp: 600,
  ),
  'A-Rank': (
    challenge: 'A-RANK DEMON CASTLE: 2-hour workout + 3 LeetCode Hard problems + 2 hours deep study in 24 hours.',
    xp: 2200,
    statXp: 850,
  ),
  'S-Rank': (
    challenge: 'MONARCH BOSS TRIAL: 200 push-ups, 10km run, 5 Hard algorithms, and 4 hours deep work unbroken.',
    xp: 3500,
    statXp: 1500,
  ),
};

class DailySystem {
  static DungeonBreak generateDungeonBreak(String rank) {
    final template = dungeonChallenges[rank] ?? dungeonChallenges['E-Rank']!;
    final now = DateTime.now().millisecondsSinceEpoch;
    return DungeonBreak(
      id: 'dungeon_${DateTime.now().millisecondsSinceEpoch}',
      rank: rank,
      challenge: template.challenge,
      xpReward: template.xp,
      statXpReward: template.statXp,
      createdAt: now,
      expiresAt: now + (24 * 3600 * 1000),
    );
  }

  static List<Quest> generateDailyQuests(String userRank) {
    // Select 4-5 diverse quests from library (physical, mental, code, health)
    final now = DateTime.now().millisecondsSinceEpoch;
    final physical = questLibrary.where((q) => q.category == QuestCategory.physical).toList();
    final coding = questLibrary.where((q) => q.category == QuestCategory.coding).toList();
    final study = questLibrary.where((q) => q.category == QuestCategory.study).toList();
    final health = questLibrary.where((q) => q.category == QuestCategory.health || q.category == QuestCategory.discipline).toList();

    final rng = Random();
    final selected = <LibraryQuest>[
      if (physical.isNotEmpty) physical[rng.nextInt(physical.length)],
      if (coding.isNotEmpty) coding[rng.nextInt(coding.length)],
      if (study.isNotEmpty) study[rng.nextInt(study.length)],
      if (health.isNotEmpty) health[rng.nextInt(health.length)],
    ];

    return selected.map((lq) => Quest(
      id: 'daily_${lq.id}_$now',
      name: lq.name,
      description: lq.description,
      difficulty: lq.difficulty,
      category: lq.category,
      stat: lq.stat,
      progress: 0,
      target: lq.target,
      completed: false,
      xpReward: difficultyXp[lq.difficulty] ?? 25,
      statXpReward: difficultyStatXp[lq.difficulty] ?? 15,
      isCustom: false,
    )).toList();
  }

  static Quest generateDailyBonusQuest(String rank) {
    return Quest(
      id: 'bonus_${DateTime.now().millisecondsSinceEpoch}',
      name: 'SPECIAL MISSION: Daily Momentum Overdrive',
      description: 'Execute an extra high-intensity focus block or physical sprint for bonus multipliers!',
      difficulty: DifficultyGrade.C,
      category: QuestCategory.discipline,
      stat: HunterStat.PERC,
      progress: 0,
      target: 1,
      completed: false,
      xpReward: 150,
      statXpReward: 50,
    );
  }
}
