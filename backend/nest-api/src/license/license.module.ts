import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { JwtModule } from '@nestjs/jwt';
import { LicenseController } from './license.controller';
import { LicenseService } from './license.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [
    HttpModule,
    PrismaModule,
    JwtModule.register({
      secret: process.env.JWT_SECRET || 'defaultSecretKey',
      signOptions: { expiresIn: '24h' },
    }),
  ],
  controllers: [LicenseController],
  providers: [LicenseService],
})
export class LicenseModule {}
