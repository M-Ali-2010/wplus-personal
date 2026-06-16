import { IsNumber, IsOptional, IsString, IsUUID, Min } from 'class-validator';

export class CreateDonationDto {
  @IsUUID()
  receiverId: string;

  @IsNumber()
  @Min(1)
  amount: number;

  @IsString()
  idempotencyKey: string;

  @IsOptional()
  @IsString()
  message?: string;

  @IsOptional()
  @IsUUID()
  postId?: string;

  @IsOptional()
  @IsUUID()
  streamId?: string;
}
