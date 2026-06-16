import { IsEnum, IsUUID } from 'class-validator';
import { BattleMode } from '../common/enums';

export class StartBattleDto {
  @IsUUID()
  streamId: string;

  @IsUUID()
  opponentId: string;

  @IsEnum(BattleMode)
  mode: BattleMode;
}

export class UpdateScoreDto {
  playerScore: number;
  aiScore: number;
}
