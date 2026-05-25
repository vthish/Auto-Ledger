import { Controller, Post, Body, Get, Param, Patch } from '@nestjs/common';
import { FinesService } from './fines.service';

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
}
