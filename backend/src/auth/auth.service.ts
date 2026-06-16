import { Injectable, ConflictException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcryptjs';
import { User } from '../entities/user.entity';
import { Wallet } from '../entities/wallet.entity';
import { UserRole } from '../common/enums';
import { RegisterDto, LoginDto } from './auth.dto';

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User) private usersRepo: Repository<User>,
    @InjectRepository(Wallet) private walletsRepo: Repository<Wallet>,
    private jwtService: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    const exists = await this.usersRepo.findOne({
      where: [{ email: dto.email }, { username: dto.username }],
    });
    if (exists) throw new ConflictException('Email or username already taken');

    const user = this.usersRepo.create({
      email: dto.email,
      username: dto.username,
      displayName: dto.displayName ?? dto.username,
      passwordHash: await bcrypt.hash(dto.password, 10),
      role: dto.asCreator ? UserRole.CREATOR : UserRole.USER,
    });
    await this.usersRepo.save(user);

    const wallet = this.walletsRepo.create({
      user,
      userId: user.id,
      balance: dto.asCreator ? 2500 : 500,
      currency: 'W',
    });
    await this.walletsRepo.save(wallet);
    user.wallet = wallet;

    return this.buildAuthResponse(user);
  }

  async login(dto: LoginDto) {
    const user = await this.usersRepo.findOne({
      where: { email: dto.email },
      relations: ['wallet'],
    });
    if (!user || !(await bcrypt.compare(dto.password, user.passwordHash))) {
      throw new UnauthorizedException('Invalid credentials');
    }
    return this.buildAuthResponse(user);
  }

  toPublicUser(user: User) {
    return {
      id: user.id,
      username: user.username,
      displayName: user.displayName,
      role: user.role,
      isVerified: user.isVerified,
      avatarUrl: user.avatarUrl,
      bio: user.bio,
      followersCount: user.followersCount,
      followingCount: user.followingCount,
      trophies: user.trophies,
    };
  }

  private buildAuthResponse(user: User) {
    const payload = { sub: user.id, role: user.role };
    return {
      accessToken: this.jwtService.sign(payload),
      user: this.toPublicUser(user),
      wallet: user.wallet
        ? {
            balance: Number(user.wallet.balance),
            pendingBalance: Number(user.wallet.pendingBalance),
            currency: user.wallet.currency,
          }
        : null,
    };
  }
}
