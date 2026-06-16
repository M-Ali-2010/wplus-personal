import { IsBoolean, IsOptional, IsUUID } from 'class-validator';

export class GenerateCommentDto {
  @IsUUID()
  streamId: string;

  @IsOptional()
  @IsBoolean()
  includeGift?: boolean;
}
