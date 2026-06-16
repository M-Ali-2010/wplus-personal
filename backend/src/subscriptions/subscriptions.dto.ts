import { IsNumber, IsOptional, IsString, IsUUID, Min, MinLength } from 'class-validator';

export class SubscribeDto {
  @IsUUID()
  creatorId: string;

  @IsOptional()
  @IsString()
  tier?: string;

  @IsString()
  idempotencyKey: string;
}

export class CreatePremiumPostDto {
  @IsString()
  @MinLength(1)
  title: string;

  @IsString()
  @MinLength(1)
  content: string;

  @IsNumber()
  @Min(0)
  price: number;

  @IsOptional()
  @IsString()
  thumbnailUrl?: string;
}

export class PurchasePremiumPostDto {
  @IsString()
  idempotencyKey: string;
}
