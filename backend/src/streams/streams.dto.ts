import { IsBoolean, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateStreamDto {
  @IsString()
  @MinLength(3)
  title: string;

  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsString()
  thumbnailUrl?: string;

  @IsOptional()
  @IsBoolean()
  giftsEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  donationsEnabled?: boolean;

  @IsOptional()
  @IsBoolean()
  aiEnabled?: boolean;
}

export class PostCommentDto {
  @IsString()
  @MinLength(1)
  text: string;
}
