import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { UsersModule } from './users/users.module';
import { LicenseModule } from './license/license.module';
import { FinesModule } from './fines/fines.module';
import { OfficersModule } from './officers/officers.module';

@Module({
  imports: [
    PrismaModule,
    UsersModule,
    LicenseModule,
    FinesModule,
    OfficersModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
