import { Controller, Post, Body, Get, Param } from '@nestjs/common';
import { OfficersService } from './officers.service';

@Controller('officers')
export class OfficersController {
  constructor(private readonly officersService: OfficersService) {}

  @Post('register/head')
  async registerDivisionalHead(
    @Body()
    data: {
      badgeNumber: string;
      name: string;
      password: string;
      districtName: string;
    },
  ) {
    return this.officersService.registerDivisionalHead(data);
  }

  @Post('register')
  async registerOfficer(
    @Body()
    officerData: {
      badgeNumber: string;
      name: string;
      password: string;
      role?: string;
      districtId: string;
    },
  ) {
    return this.officersService.registerOfficer(officerData);
  }

  @Post('shift')
  async assignShift(
    @Body()
    data: {
      officerId: string;
      startTime: string;
      endTime: string;
    },
  ) {
    return this.officersService.assignShift(data);
  }

  @Get('district/:districtId')
  async getDistrictOfficers(@Param('districtId') districtId: string) {
    return this.officersService.getOfficersByDistrict(districtId);
  }
}
