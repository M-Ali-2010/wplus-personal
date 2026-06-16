import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AccessToken } from 'livekit-server-sdk';

@Injectable()
export class LivekitService {
  constructor(private config: ConfigService) {}

  isConfigured(): boolean {
    return !!(
      this.config.get('LIVEKIT_URL') &&
      this.config.get('LIVEKIT_API_KEY') &&
      this.config.get('LIVEKIT_API_SECRET')
    );
  }

  createRoomName(streamId: string): string {
    return `wplus_stream_${streamId}`;
  }

  /** Returns stub token when LiveKit not configured (dev mode). */
  async generateToken(streamId: string, userId: string, canPublish: boolean): Promise<{
    token: string;
    url: string;
    room: string;
    isStub: boolean;
  }> {
    const room = this.createRoomName(streamId);
    const url = this.config.get('LIVEKIT_URL', 'wss://livekit.example.com');

    if (!this.isConfigured()) {
      return {
        token: `stub_${userId}_${streamId}_${canPublish ? 'pub' : 'sub'}`,
        url,
        room,
        isStub: true,
      };
    }

    const apiKey = this.config.get('LIVEKIT_API_KEY')!;
    const apiSecret = this.config.get('LIVEKIT_API_SECRET')!;

    const at = new AccessToken(apiKey, apiSecret, {
      identity: userId,
      ttl: '6h',
    });
    at.addGrant({
      roomJoin: true,
      room,
      canPublish,
      canSubscribe: true,
      canPublishData: true,
    });

    return {
      token: await at.toJwt(),
      url,
      room,
      isStub: false,
    };
  }
}
