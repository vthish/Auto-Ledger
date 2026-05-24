import { Controller, Post, Body } from '@nestjs/common';
import { OfficersService } from './officers.service';

@Controller('officers')
export class OfficersController {
  constructor(private readonly officersService: OfficersService) {}

  @Post('register')
  async registerOfficer(
    @Body()
    officerData: {
      badgeNumber: string;
      name: string;
      password: string;
      districtName: string;
    },
  ) {
    return this.officersService.registerOfficer(officerData);
  }
}
