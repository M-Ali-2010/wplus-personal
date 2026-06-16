import 'user.dart';

enum BattleMode { classic, speed, survival }

enum BattleDifficulty { medium, hard, extreme }

class AiOpponent {
  const AiOpponent({
    required this.id,
    required this.name,
    required this.tagline,
    required this.difficulty,
    required this.winRate,
    required this.emoji,
    required this.colorHex,
  });

  final String id;
  final String name;
  final String tagline;
  final BattleDifficulty difficulty;
  final int winRate;
  final String emoji;
  final int colorHex;

  String get difficultyLabel {
    switch (difficulty) {
      case BattleDifficulty.medium:
        return 'Medium';
      case BattleDifficulty.hard:
        return 'Hard';
      case BattleDifficulty.extreme:
        return 'Extreme';
    }
  }
}

class BattleState {
  const BattleState({
    required this.opponent,
    required this.mode,
    this.battleId,
    this.streamId,
    this.playerScore = 0,
    this.aiScore = 0,
    this.currentRound = 1,
    this.totalRounds = 3,
    this.secondsLeft = 45,
    this.playerWinStreak = 0,
    this.aiWinStreak = 0,
    this.isActive = true,
    this.playerEnergy = 80,
    this.playerCharisma = 70,
    this.playerCreativity = 65,
    this.playerSupport = 90,
  });

  final AiOpponent opponent;
  final BattleMode mode;
  final String? battleId;
  final String? streamId;
  final int playerScore;
  final int aiScore;
  final int currentRound;
  final int totalRounds;
  final int secondsLeft;
  final int playerWinStreak;
  final int aiWinStreak;
  final bool isActive;
  final int playerEnergy;
  final int playerCharisma;
  final int playerCreativity;
  final int playerSupport;

  double get playerScoreRatio {
    final total = playerScore + aiScore;
    if (total == 0) return 0.5;
    return playerScore / total;
  }

  BattleState copyWith({
    int? playerScore,
    int? aiScore,
    int? currentRound,
    int? secondsLeft,
    int? playerWinStreak,
    int? aiWinStreak,
    bool? isActive,
    int? playerEnergy,
    int? playerCharisma,
    int? playerCreativity,
    int? playerSupport,
  }) {
    return BattleState(
      opponent: opponent,
      mode: mode,
      battleId: battleId,
      streamId: streamId,
      playerScore: playerScore ?? this.playerScore,
      aiScore: aiScore ?? this.aiScore,
      currentRound: currentRound ?? this.currentRound,
      totalRounds: totalRounds,
      secondsLeft: secondsLeft ?? this.secondsLeft,
      playerWinStreak: playerWinStreak ?? this.playerWinStreak,
      aiWinStreak: aiWinStreak ?? this.aiWinStreak,
      isActive: isActive ?? this.isActive,
      playerEnergy: playerEnergy ?? this.playerEnergy,
      playerCharisma: playerCharisma ?? this.playerCharisma,
      playerCreativity: playerCreativity ?? this.playerCreativity,
      playerSupport: playerSupport ?? this.playerSupport,
    );
  }
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.user,
    required this.trophies,
    required this.isCurrentUser,
  });

  final int rank;
  final UserProfile user;
  final int trophies;
  final bool isCurrentUser;
}

class BattleReward {
  const BattleReward({
    required this.title,
    required this.trophies,
    required this.xp,
    required this.icon,
  });

  final String title;
  final int trophies;
  final int xp;
  final String icon;
}
