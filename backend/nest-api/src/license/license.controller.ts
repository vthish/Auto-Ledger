import { Controller, Post, Body, Get, Param } from '@nestjs/common';
import { LicenseService } from './license.service';

@Controller('license')
export class LicenseController {
  constructor(private readonly licenseService: LicenseService) {}

  // POST endpoint to issue a new license
  @Post('issue')
  async issueLicense(
    @Body()
    licenseData: {
      licenseNumber: string;
      expiryDate: string;
      userId: string;
    },
  ) {
    return this.licenseService.issueLicense(licenseData);
  }

  // GET endpoint to fetch license details
  @Get(':id')
  async getLicense(@Param('id') id: string) {
    return this.licenseService.getLicenseById(id);
  }
}
