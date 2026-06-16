import { IsNumber, IsOptional, IsString, IsUUID, Min, MinLength } from 'class-validator';

export class SendPaidMessageDto {
  @IsUUID()
  receiverId: string;

  @IsString()
  @MinLength(1)
  text: string;

  @IsNumber()
  @Min(1)
  amount: number;

  @IsOptional()
  @IsUUID()
  streamId?: string;

  @IsOptional()
  @IsUUID()
  postId?: string;

  @IsString()
  idempotencyKey: string;
}
