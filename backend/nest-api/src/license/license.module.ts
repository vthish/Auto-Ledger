import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { LicenseController } from './license.controller';
import { LicenseService } from './license.service';

@Module({
  imports: [HttpModule],
  controllers: [LicenseController],
  providers: [LicenseService],
})
export class LicenseModule {}
