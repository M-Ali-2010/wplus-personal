import { Body, Controller, Post } from '@nestjs/common';
import { AiService } from './ai.service';
import { GenerateCommentDto } from './ai.dto';

@Controller('api/ai')
export class AiController {
  constructor(private aiService: AiService) {}

  @Post('generate-comment')
  generateComment(@Body() dto: GenerateCommentDto) {
    return this.aiService.generateComment(dto);
  }
}
