import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';
import { DataSource } from 'typeorm';

async function autoSeedIfEmpty(app: any) {
  try {
    const dataSource = app.get(DataSource);
    const result = await dataSource.query('SELECT COUNT(*) FROM users');
    const count = parseInt(result[0].count, 10);
    if (count === 0) {
      console.log('🌱 Empty DB detected — running seed...');
      const { seed } = await import('./seed-fn');
      await seed(dataSource);
      console.log('✅ Seed complete');
    } else {
      console.log(`✅ DB has ${count} users — skipping seed`);
    }
  } catch (e) {
    console.warn('⚠️  Auto-seed skipped:', (e as Error).message);
  }
}

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors({ origin: true, credentials: true });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  await autoSeedIfEmpty(app);

  const port = process.env.PORT ?? 3000;
  await app.listen(port);
  console.log(`W+ Backend running on port ${port}`);
}

bootstrap();
