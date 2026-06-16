import { Body, Controller, Get, Param, Post, Req, UseGuards } from '@nestjs/common';
import { BattlesService } from './battles.service';
import { StartBattleDto, UpdateScoreDto } from './battles.dto';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { User } from '../entities/user.entity';

@Controller('api/battles')
export class BattlesController {
  constructor(private battlesService: BattlesService) {}

  @Get('opponents')
  getOpponents() {
    return this.battlesService.getOpponents();
  }

  @Get('leaderboard')
  getLeaderboard() {
    return this.battlesService.getLeaderboard();
  }

  @UseGuards(JwtAuthGuard)
  @Post('start')
  start(@Req() req: { user: User }, @Body() dto: StartBattleDto) {
    return this.battlesService.startBattle(req.user.id, dto);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/score')
  updateScore(@Param('id') id: string, @Body() dto: UpdateScoreDto) {
    return this.battlesService.updateScore(id, dto.playerScore, dto.aiScore);
  }

  @UseGuards(JwtAuthGuard)
  @Post(':id/end')
  end(@Param('id') id: string, @Body() body: { winnerId?: string }) {
    return this.battlesService.endBattle(id, body.winnerId);
  }
}
