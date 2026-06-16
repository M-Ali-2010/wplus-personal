import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, Repository } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import { Wallet } from '../entities/wallet.entity';
import { Transaction } from '../entities/transaction.entity';
import { TransactionStatus, TransactionType } from '../common/enums';
import { TopUpDto } from './wallet.dto';

@Injectable()
export class WalletService {
  private commission: number;

  constructor(
    @InjectRepository(Wallet) private walletsRepo: Repository<Wallet>,
    @InjectRepository(Transaction) private txRepo: Repository<Transaction>,
    private dataSource: DataSource,
    private config: ConfigService,
  ) {
    this.commission = parseFloat(this.config.get('PLATFORM_COMMISSION', '0.15'));
  }

  async getWallet(userId: string) {
    const wallet = await this.walletsRepo.findOne({ where: { userId } });
    if (!wallet) throw new NotFoundException('Wallet not found');
    return {
      balance: Number(wallet.balance),
      pendingBalance: Number(wallet.pendingBalance),
      currency: wallet.currency,
    };
  }

  async getTransactions(userId: string, limit = 50) {
    const txs = await this.txRepo.find({
      where: { userId },
      order: { createdAt: 'DESC' },
      take: limit,
    });
    return txs.map((tx) => this.toPublicTx(tx));
  }

  async topUp(userId: string, dto: TopUpDto) {
    return this.executeIdempotent(userId, dto.idempotencyKey, async (manager) => {
      const existing = await manager.findOne(Transaction, {
        where: { idempotencyKey: dto.idempotencyKey },
      });
      if (existing) {
        if (existing.status === TransactionStatus.COMPLETED) {
          return { transaction: this.toPublicTx(existing), duplicate: true };
        }
        throw new ConflictException('Transaction in progress');
      }

      const wallet = await manager.findOne(Wallet, { where: { userId } });
      if (!wallet) throw new NotFoundException('Wallet not found');

      const tx = manager.create(Transaction, {
        userId,
        type: TransactionType.TOPUP,
        amount: dto.amount,
        currency: wallet.currency,
        status: TransactionStatus.PENDING,
        idempotencyKey: dto.idempotencyKey,
        description: dto.description ?? 'Wallet top-up',
      });
      await manager.save(tx);

      wallet.balance = Number(wallet.balance) + dto.amount;
      await manager.save(wallet);

      tx.status = TransactionStatus.COMPLETED;
      await manager.save(tx);

      return {
        transaction: this.toPublicTx(tx),
        wallet: {
          balance: Number(wallet.balance),
          pendingBalance: Number(wallet.pendingBalance),
          currency: wallet.currency,
        },
        duplicate: false,
      };
    });
  }

  async debit(
    userId: string,
    amount: number,
    type: TransactionType,
    idempotencyKey: string,
    meta: {
      counterpartyId?: string;
      counterpartyName?: string;
      referenceId?: string;
      description?: string;
    },
  ) {
    return this.executeIdempotent(userId, idempotencyKey, async (manager) => {
      const existing = await manager.findOne(Transaction, {
        where: { idempotencyKey },
      });
      if (existing?.status === TransactionStatus.COMPLETED) {
        return { transaction: existing, duplicate: true };
      }

      const wallet = await manager.findOne(Wallet, { where: { userId } });
      if (!wallet) throw new NotFoundException('Wallet not found');
      if (Number(wallet.balance) < amount) {
        throw new BadRequestException('Insufficient balance');
      }

      const tx = manager.create(Transaction, {
        userId,
        type,
        amount: -amount,
        currency: wallet.currency,
        status: TransactionStatus.PENDING,
        idempotencyKey,
        counterpartyId: meta.counterpartyId,
        counterpartyName: meta.counterpartyName,
        referenceId: meta.referenceId,
        description: meta.description,
      });
      await manager.save(tx);

      wallet.balance = Number(wallet.balance) - amount;
      await manager.save(wallet);

      tx.status = TransactionStatus.COMPLETED;
      await manager.save(tx);

      return { transaction: tx, duplicate: false, wallet };
    });
  }

  async creditCreator(
    creatorId: string,
    grossAmount: number,
    type: TransactionType,
    idempotencyKey: string,
    meta: {
      counterpartyId?: string;
      counterpartyName?: string;
      referenceId?: string;
      description?: string;
    },
  ) {
    const netAmount = grossAmount * (1 - this.commission);

    return this.executeIdempotent(creatorId, `${idempotencyKey}_credit`, async (manager) => {
      const existing = await manager.findOne(Transaction, {
        where: { idempotencyKey: `${idempotencyKey}_credit` },
      });
      if (existing?.status === TransactionStatus.COMPLETED) {
        return { transaction: existing, duplicate: true };
      }

      const wallet = await manager.findOne(Wallet, { where: { userId: creatorId } });
      if (!wallet) throw new NotFoundException('Creator wallet not found');

      const tx = manager.create(Transaction, {
        userId: creatorId,
        type,
        amount: netAmount,
        currency: wallet.currency,
        status: TransactionStatus.COMPLETED,
        idempotencyKey: `${idempotencyKey}_credit`,
        counterpartyId: meta.counterpartyId,
        counterpartyName: meta.counterpartyName,
        referenceId: meta.referenceId,
        description: meta.description,
      });
      await manager.save(tx);

      wallet.balance = Number(wallet.balance) + netAmount;
      await manager.save(wallet);

      return { transaction: tx, duplicate: false };
    });
  }

  getCommissionRate() {
    return this.commission;
  }

  private async executeIdempotent<T>(
    userId: string,
    key: string,
    fn: (manager: typeof this.dataSource.manager) => Promise<T>,
  ): Promise<T> {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();
    try {
      const result = await fn(queryRunner.manager);
      await queryRunner.commitTransaction();
      return result;
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  private toPublicTx(tx: Transaction) {
    return {
      id: tx.id,
      type: tx.type,
      amount: Number(tx.amount),
      status: tx.status,
      createdAt: tx.createdAt,
      counterpartyName: tx.counterpartyName,
      description: tx.description,
    };
  }
}
