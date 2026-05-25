import {
  Controller,
  Post,
  Body,
  Get,
  Param,
  Patch,
  Delete,
} from '@nestjs/common';
import { LicenseService } from './license.service';

@Controller('license')
export class LicenseController {
  constructor(private readonly licenseService: LicenseService) {}

  // POST endpoint to issue a new license automatically via DMT integration
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

  // GET endpoint to fetch license details
  @Get(':id')
  async getLicense(@Param('id') id: string) {
    return this.licenseService.getLicenseById(id);
  }

  // PATCH endpoint to update license details (like violation points)
  @Patch(':id')
  async update(
    @Param('id') id: string,
    @Body() updateData: { expiryDate?: string; points?: number },
  ) {
    return this.licenseService.updateLicense(id, updateData);
  }

  // DELETE endpoint to revoke/remove a license
  @Delete(':id')
  async revoke(@Param('id') id: string) {
    return this.licenseService.deleteLicense(id);
  }
}
