import { Controller, Post, Body } from '@nestjs/common';
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
}
