import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleDestroy {
  private client: Redis;

  constructor(private config: ConfigService) {
    this.client = new Redis({
      host: this.config.get('REDIS_HOST', 'localhost'),
      port: this.config.get<number>('REDIS_PORT', 6379),
      maxRetriesPerRequest: 3,
      lazyConnect: true,
    });
    this.client.connect().catch(() => {
      // Redis optional in dev — streams fall back to DB counts
    });
  }

  get redis(): Redis {
    return this.client;
  }

  async getViewerCount(streamId: string): Promise<number | null> {
    try {
      const val = await this.client.get(`stream:${streamId}:viewers`);
      return val ? parseInt(val, 10) : null;
    } catch {
      return null;
    }
  }

  async setViewerCount(streamId: string, count: number): Promise<void> {
    try {
      await this.client.set(`stream:${streamId}:viewers`, count.toString(), 'EX', 3600);
    } catch {
      // ignore
    }
  }

  async incrementViewer(streamId: string): Promise<number> {
    try {
      return await this.client.incr(`stream:${streamId}:viewers`);
    } catch {
      return 0;
    }
  }

  async decrementViewer(streamId: string): Promise<number> {
    try {
      const val = await this.client.decr(`stream:${streamId}:viewers`);
      return Math.max(0, val);
    } catch {
      return 0;
    }
  }

  onModuleDestroy() {
    this.client.disconnect();
  }
}
