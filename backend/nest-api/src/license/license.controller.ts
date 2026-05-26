import {
  Controller,
  Post,
  Body,
  Get,
  Param,
  Patch,
  Delete,
  UseGuards,
  Req,
} from '@nestjs/common';
import { LicenseService } from './license.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Request } from 'express';

interface AuthenticatedRequest extends Request {
  user: {
    id: string;
  };
}

@Controller('license')
export class LicenseController {
  constructor(private readonly licenseService: LicenseService) {}

  @UseGuards(JwtAuthGuard)
  @Get('my-card')
  async getMyCard(@Req() req: AuthenticatedRequest) {
    return this.licenseService.getVirtualCardDetails(req.user.id);
  }

  @UseGuards(JwtAuthGuard)
  @Get('scan/:token')
  async scanLicense(@Param('token') token: string) {
    return this.licenseService.getLicenseByQrToken(token);
  }

  @Post('issue')
  async issueLicense(
    @Body()
    licenseData: {
      nic: string;
      userId: string;
    },
  ) {
    return this.licenseService.issueLicense(licenseData);
  }

  @Get(':id')
  async getLicense(@Param('id') id: string) {
    return this.licenseService.getLicenseById(id);
  }

  @Patch(':id')
  async update(
    @Param('id') id: string,
    @Body() updateData: { expiryDate?: string; points?: number },
  ) {
    return this.licenseService.updateLicense(id, updateData);
  }

  @Delete(':id')
  async revoke(@Param('id') id: string) {
    return this.licenseService.deleteLicense(id);
  }
}
