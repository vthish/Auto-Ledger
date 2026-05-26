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
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

interface AuthenticatedRequest extends Request {
  user: {
    id: string;
    role: string;
    districtId?: string;
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
      qrToken: string;
      offenseCodes: string[];
      officerId: string;
    },
  ) {
    return this.finesService.issueFine(fineData);
  }

  @Patch('court/:fineId/resolve')
  @UseGuards(RolesGuard)
  @Roles('DIVISIONAL_HEAD')
  async resolveCourtCase(
    @Param('fineId') fineId: string,
    @Body() data: { finalVerdict: 'ACTIVE' | 'REVOKED' },
  ) {
    return this.finesService.resolveCourtCase(fineId, data.finalVerdict);
  }

  @Get('district/court-cases')
  @UseGuards(RolesGuard)
  @Roles('DIVISIONAL_HEAD')
  async getDistrictCourtCases(@Req() req: AuthenticatedRequest) {
    const districtId = req.user.districtId;
    return this.finesService.getCourtCasesByDistrict(districtId);
  }

  @Get('district/statistics')
  @UseGuards(RolesGuard)
  @Roles('DIVISIONAL_HEAD')
  async getDistrictStatistics(@Req() req: AuthenticatedRequest) {
    const districtId = req.user.districtId;
    return this.finesService.getDistrictStatistics(districtId);
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

  @Post('calculate-total')
  async calculateTotal(
    @Body() data: { fineIds: string[] },
    @Req() req: AuthenticatedRequest,
  ) {
    const userId = req.user.id;
    return this.finesService.calculateTotalAmount(data.fineIds, userId);
  }

  @Post('pay')
  async payDummyFines(
    @Body() data: { fineIds: string[] },
    @Req() req: AuthenticatedRequest,
  ) {
    const userId = req.user.id;
    return this.finesService.payFines(data.fineIds, userId);
  }
}
