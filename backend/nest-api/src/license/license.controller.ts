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
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';

interface AuthenticatedRequest extends Request {
  user: {
    id: string;
  };
}

@ApiTags('License')
@Controller('license')
export class LicenseController {
  constructor(private readonly licenseService: LicenseService) {}

  @ApiOperation({ summary: 'Get virtual license card details' })
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Get('my-card')
  async getMyCard(@Req() req: AuthenticatedRequest) {
    return this.licenseService.getVirtualCardDetails(req.user.id);
  }

  @ApiOperation({ summary: 'Scan license QR token' })
  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Get('scan/:token')
  async scanLicense(@Param('token') token: string) {
    return this.licenseService.getLicenseByQrToken(token);
  }

  @ApiOperation({ summary: 'Issue a new license' })
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

  @ApiOperation({ summary: 'Get license by ID' })
  @Get(':id')
  async getLicense(@Param('id') id: string) {
    return this.licenseService.getLicenseById(id);
  }

  @ApiOperation({ summary: 'Update license details' })
  @Patch(':id')
  async update(
    @Param('id') id: string,
    @Body() updateData: { expiryDate?: string; points?: number },
  ) {
    return this.licenseService.updateLicense(id, updateData);
  }

  @ApiOperation({ summary: 'Revoke a license' })
  @Delete(':id')
  async revoke(@Param('id') id: string) {
    return this.licenseService.deleteLicense(id);
  }
}
