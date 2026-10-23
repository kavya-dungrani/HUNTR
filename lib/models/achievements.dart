import 'game_engine.dart';

class AchievementDef {
  final String id;
  final String name;
  final String description;
  final String icon;
  final String category; // 'progression' | 'consistency' | 'physical' | 'mental' | 'code' | 'rank' | 'special'
  final int xpReward;
  final String? badgeId;
  final String? titleUnlock;

  const AchievementDef({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.xpReward,
    this.badgeId,
    this.titleUnlock,
  });

  bool checkUnlocked(HunterProfile profile, List<Quest> quests) {
    switch (id) {
      case 'first_blood':
        return profile.questsCompleted >= 1;
      case 'awakening':
        return profile.currentLevel >= 5;
      case 'hunter_rank':
        return profile.questsCompleted >= 50;
      case 'veteran':
        return profile.questsCompleted >= 250;
      case 'legend':
        return profile.questsCompleted >= 1000;
      case 'momentum':
        return profile.totalXp >= 1000;
      case 'xp_lord':
        return profile.totalXp >= 10000;
      case 'relentless':
        return profile.streak >= 30;
      case 'unstoppable':
        return profile.streak >= 60;
      case 'iron_will':
        return profile.streak >= 100;
      case 'iron_body':
        return (profile.stats[HunterStat.STR] ?? 0) >= 30;
      case 'shadow_step':
        return (profile.stats[HunterStat.AGI] ?? 0) >= 30;
      case 'titan_flesh':
        return (profile.stats[HunterStat.VIT] ?? 0) >= 30;
      case 'sovereign_mind':
        return (profile.stats[HunterStat.INT] ?? 0) >= 30;
      case 'all_seeing':
        return (profile.stats[HunterStat.PERC] ?? 0) >= 30;
      case 'code_architect':
        return profile.codingQuestsCompleted >= 25;
      case 'rank_d':
        return profile.currentRank != 'E-Rank';
      case 'rank_c':
        return ['C-Rank', 'B-Rank', 'A-Rank', 'S-Rank'].contains(profile.currentRank);
      case 'rank_b':
        return ['B-Rank', 'A-Rank', 'S-Rank'].contains(profile.currentRank);
      case 'rank_a':
        return ['A-Rank', 'S-Rank'].contains(profile.currentRank);
      case 'rank_s':
        return profile.currentRank == 'S-Rank';
      default:
        return false;
    }
  }
}

const List<AchievementDef> allAchievements = [
  // PROGRESSION
  AchievementDef(
    id: 'first_blood',
    name: 'First Blood',
    description: 'Complete your very first quest.',
    icon: '🏆',
    category: 'progression',
    xpReward: 50,
    titleUnlock: 'The Awakened',
  ),
  AchievementDef(
    id: 'awakening',
    name: 'Awakening',
    description: 'Reach Level 5.',
    icon: '⚡',
    category: 'progression',
    xpReward: 100,
    titleUnlock: 'Rookie Hunter',
  ),
  AchievementDef(
    id: 'hunter_rank',
    name: 'Proven Hunter',
    description: 'Complete 50 quests.',
    icon: '🗡️',
    category: 'progression',
    xpReward: 200,
    titleUnlock: 'Dungeon Raider',
  ),
  AchievementDef(
    id: 'veteran',
    name: 'Veteran Hunter',
    description: 'Complete 250 quests.',
    icon: '⚔️',
    category: 'progression',
    xpReward: 500,
    titleUnlock: 'Elite Slayer',
  ),
  AchievementDef(
    id: 'legend',
    name: 'Living Legend',
    description: 'Complete 1000 quests.',
    icon: '👑',
    category: 'progression',
    xpReward: 2000,
    titleUnlock: 'National Level Hunter',
  ),
  AchievementDef(
    id: 'momentum',
    name: 'Momentum',
    description: 'Reach 1,000 total XP.',
    icon: '🚀',
    category: 'progression',
    xpReward: 100,
  ),
  AchievementDef(
    id: 'xp_lord',
    name: 'XP Sovereign',
    description: 'Accumulate 10,000 total XP.',
    icon: '💎',
    category: 'progression',
    xpReward: 500,
    titleUnlock: 'Mana Vortex',
  ),

  // CONSISTENCY
  AchievementDef(
    id: 'relentless',
    name: 'Relentless',
    description: 'Maintain a 30-day quest streak.',
    icon: '🔥',
    category: 'consistency',
    xpReward: 500,
    badgeId: 'relentless',
    titleUnlock: 'Unyielding',
  ),
  AchievementDef(
    id: 'unstoppable',
    name: 'Unstoppable',
    description: 'Maintain a 60-day quest streak.',
    icon: '⚡',
    category: 'consistency',
    xpReward: 1000,
    badgeId: 'unstoppable',
    titleUnlock: 'Force of Nature',
  ),
  AchievementDef(
    id: 'iron_will',
    name: 'Iron Will',
    description: 'Maintain a 100-day quest streak.',
    icon: '🛡️',
    category: 'consistency',
    xpReward: 2500,
    badgeId: 'iron_will',
    titleUnlock: 'Indomitable',
  ),

  // STAT MASTERY
  AchievementDef(
    id: 'iron_body',
    name: 'Titan Strength',
    description: 'Achieve 30+ Strength (STR).',
    icon: '💪',
    category: 'physical',
    xpReward: 300,
    titleUnlock: 'Iron Breaker',
  ),
  AchievementDef(
    id: 'shadow_step',
    name: 'Shadow Velocity',
    description: 'Achieve 30+ Agility (AGI).',
    icon: '💨',
    category: 'physical',
    xpReward: 300,
    titleUnlock: 'Phantom Step',
  ),
  AchievementDef(
    id: 'titan_flesh',
    name: 'Immortal Vessel',
    description: 'Achieve 30+ Vitality (VIT).',
    icon: '❤️',
    category: 'physical',
    xpReward: 300,
    titleUnlock: 'Unbreakable',
  ),
  AchievementDef(
    id: 'sovereign_mind',
    name: 'Omniscient Mind',
    description: 'Achieve 30+ Intelligence (INT).',
    icon: '🧠',
    category: 'mental',
    xpReward: 300,
    titleUnlock: 'Archmage',
  ),
  AchievementDef(
    id: 'all_seeing',
    name: 'All-Seeing Eye',
    description: 'Achieve 30+ Perception (PERC).',
    icon: '👁️',
    category: 'mental',
    xpReward: 300,
    titleUnlock: 'Hawkeye',
  ),

  // CODE & TECH
  AchievementDef(
    id: 'code_architect',
    name: 'Code Architect',
    description: 'Complete 25 coding/algorithm quests.',
    icon: '💻',
    category: 'code',
    xpReward: 350,
    titleUnlock: 'Cyber Monarch',
  ),

  // RANKS
  AchievementDef(
    id: 'rank_d',
    name: 'Rank D Awakening',
    description: 'Advance past E-Rank.',
    icon: '🥉',
    category: 'rank',
    xpReward: 200,
  ),
  AchievementDef(
    id: 'rank_c',
    name: 'Rank C Breakthrough',
    description: 'Achieve C-Rank authorization.',
    icon: '🥈',
    category: 'rank',
    xpReward: 400,
  ),
  AchievementDef(
    id: 'rank_b',
    name: 'Rank B Elite',
    description: 'Reach B-Rank status.',
    icon: '🥇',
    category: 'rank',
    xpReward: 800,
  ),
  AchievementDef(
    id: 'rank_a',
    name: 'Rank A Vanguard',
    description: 'Reach A-Rank pinnacle.',
    icon: '🎖️',
    category: 'rank',
    xpReward: 1500,
  ),
  AchievementDef(
    id: 'rank_s',
    name: 'Shadow Monarch (S-Rank)',
    description: 'Ascend to the legendary S-Rank.',
    icon: '👑',
    category: 'rank',
    xpReward: 5000,
    titleUnlock: 'Shadow Monarch',
  ),
];
