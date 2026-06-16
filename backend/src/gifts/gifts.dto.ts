import { IsInt, IsOptional, IsString, IsUUID, Min } from 'class-validator';

export class SendGiftDto {
  @IsUUID()
  giftId: string;

  @IsUUID()
  receiverId: string;

  @IsString()
  idempotencyKey: string;

  @IsOptional()
  @IsUUID()
  streamId?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  quantity?: number;
}
