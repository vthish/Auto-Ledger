import {
  Controller,
  Post,
  Body,
  Get,
  Param,
  Patch,
  UseGuards,
  Req,
} from '@nestjs/common';
import { Request } from 'express';
import { FinesService } from './fines.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

interface AuthenticatedRequest extends Request {
  user: {
    id: string;
  };
}

@UseGuards(JwtAuthGuard)
@Controller('fines')
export class FinesController {
  constructor(private readonly finesService: FinesService) {}

  @Post('issue')
  async issueFine(
    @Body()
    fineData: {
      licenseNumber: string;
      offenseCode: string;
      officerId: string;
    },
  ) {
    return this.finesService.issueFine(fineData);
  }

  @Patch('court/:fineId/resolve')
  async resolveCourtCase(
    @Param('fineId') fineId: string,
    @Body() data: { finalVerdict: 'ACTIVE' | 'REVOKED' },
  ) {
    return this.finesService.resolveCourtCase(fineId, data.finalVerdict);
  }

  @Get('district/:districtId/court-cases')
  async getDistrictCourtCases(@Param('districtId') districtId: string) {
    return this.finesService.getCourtCasesByDistrict(districtId);
  }

  @Get('offenses')
  async getOffenses() {
    return this.finesService.getOffenses();
  }

  @Get('verify-license/:licenseNumber')
  async verifyLicense(@Param('licenseNumber') licenseNumber: string) {
    return this.finesService.verifyLicense(licenseNumber);
  }

  @Get('history')
  async getOfficerHistory(@Req() req: AuthenticatedRequest) {
    const officerId = req.user.id;
    return this.finesService.getOfficerFineHistory(officerId);
  }
  @Get('my-history')
  async getMyFineHistory(@Req() req: AuthenticatedRequest) {
    const userId = req.user.id;
    return this.finesService.getDriverFineHistory(userId);
  }
}
