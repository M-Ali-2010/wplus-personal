import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleDestroy {
  private client: Redis;

  private enabled = false;

  constructor(private config: ConfigService) {
    const host = this.config.get<string>('REDIS_HOST', '');
    // Redis is optional — skip entirely when no host configured (e.g. Render free).
    // Streams fall back to DB viewer counts.
    if (!host) {
      this.client = new Redis({ lazyConnect: true, enableOfflineQueue: false });
      return;
    }
    this.enabled = true;
    this.client = new Redis({
      host,
      port: this.config.get<number>('REDIS_PORT', 6379),
      maxRetriesPerRequest: 3,
      lazyConnect: true,
    });
    this.client.connect().catch(() => {
      // Redis optional — streams fall back to DB counts
    });
    this.client.on('error', () => {
      // swallow — optional dependency
    });
  }

  get redis(): Redis {
    return this.client;
  }

  async getViewerCount(streamId: string): Promise<number | null> {
    if (!this.enabled) return null;
    try {
      const val = await this.client.get(`stream:${streamId}:viewers`);
      return val ? parseInt(val, 10) : null;
    } catch {
      return null;
    }
  }

  async setViewerCount(streamId: string, count: number): Promise<void> {
    if (!this.enabled) return;
    try {
      await this.client.set(`stream:${streamId}:viewers`, count.toString(), 'EX', 3600);
    } catch {
      // ignore
    }
  }

  async incrementViewer(streamId: string): Promise<number> {
    if (!this.enabled) return 0;
    try {
      return await this.client.incr(`stream:${streamId}:viewers`);
    } catch {
      return 0;
    }
  }

  async decrementViewer(streamId: string): Promise<number> {
    if (!this.enabled) return 0;
    try {
      const val = await this.client.decr(`stream:${streamId}:viewers`);
      return Math.max(0, val);
    } catch {
      return 0;
    }
  }

  onModuleDestroy() {
    if (this.enabled) this.client.disconnect();
  }
}
