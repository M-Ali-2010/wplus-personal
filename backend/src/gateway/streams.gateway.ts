import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Injectable, Logger } from '@nestjs/common';

@Injectable()
@WebSocketGateway({ cors: { origin: '*' }, namespace: '/streams' })
export class StreamsGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(StreamsGateway.name);

  handleConnection(client: Socket) {
    this.logger.debug(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    this.logger.debug(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('stream.join')
  handleJoin(client: Socket, payload: { streamId: string; userId?: string }) {
    const room = `stream:${payload.streamId}`;
    client.join(room);
    return { event: 'stream.joined', data: { streamId: payload.streamId } };
  }

  @SubscribeMessage('stream.leave')
  handleLeave(client: Socket, payload: { streamId: string }) {
    client.leave(`stream:${payload.streamId}`);
    return { event: 'stream.left', data: { streamId: payload.streamId } };
  }

  emitComment(streamId: string, payload: unknown) {
    this.server.to(`stream:${streamId}`).emit('stream.comment', payload);
  }

  emitGift(streamId: string, payload: unknown) {
    this.server.to(`stream:${streamId}`).emit('stream.gift', payload);
  }

  emitDonation(streamId: string, payload: unknown) {
    this.server.to(`stream:${streamId}`).emit('stream.donation', payload);
  }

  emitPaidMessage(streamId: string, payload: unknown) {
    this.server.to(`stream:${streamId}`).emit('stream.paid_message', payload);
  }

  emitViewerCount(streamId: string, count: number) {
    this.server.to(`stream:${streamId}`).emit('stream.viewer_count', { streamId, count });
  }

  emitStreamStarted(streamId: string, payload: unknown) {
    this.server.emit('stream.started', payload);
  }

  emitStreamEnded(streamId: string) {
    this.server.to(`stream:${streamId}`).emit('stream.ended', { streamId });
  }

  emitBattleEvent(streamId: string, event: string, payload: unknown) {
    this.server.to(`stream:${streamId}`).emit(event, payload);
  }

  emitModerationAction(streamId: string, payload: { action: string; userId: string }) {
    this.server.to(`stream:${streamId}`).emit('stream.moderation', payload);
  }
}
