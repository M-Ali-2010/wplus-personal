import { IsNumber, IsOptional, IsString, IsUUID, Min } from 'class-validator';

export class TopUpDto {
  @IsNumber()
  @Min(1)
  amount: number;

  @IsString()
  idempotencyKey: string;

  @IsOptional()
  @IsString()
  description?: string;
}

export class IdempotencyBody {
  @IsString()
  idempotencyKey: string;
}
