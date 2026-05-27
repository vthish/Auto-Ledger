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
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiProperty,
} from '@nestjs/swagger';

export class IssueFineDto {
  @ApiProperty({ example: 'qr-token-string-here' })
  qrToken: string;

  @ApiProperty({ example: ['01', '02'] })
  offenseCodes: string[];

  @ApiProperty({ example: 'TRF-GALLE-100' })
  officerId: string;
}

export class ResolveCourtCaseDto {
  @ApiProperty({ example: 'ACTIVE', enum: ['ACTIVE', 'REVOKED'] })
  finalVerdict: 'ACTIVE' | 'REVOKED';
}

export class FineIdsDto {
  @ApiProperty({ example: ['fine-uuid-1111', 'fine-uuid-2222'] })
  fineIds: string[];
}

interface AuthenticatedRequest extends Request {
  user: {
    id: string;
    role: string;
    districtId?: string;
  };
}

@ApiTags('Fines')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('fines')
export class FinesController {
  constructor(private readonly finesService: FinesService) {}

  @ApiOperation({ summary: 'Issue a new fine' })
  @Post('issue')
  async issueFine(@Body() fineData: IssueFineDto) {
    return this.finesService.issueFine(fineData);
  }

  @ApiOperation({ summary: 'Resolve a court case' })
  @Patch('court/:fineId/resolve')
  @UseGuards(RolesGuard)
  @Roles('DIVISIONAL_HEAD')
  async resolveCourtCase(
    @Param('fineId') fineId: string,
    @Body() data: ResolveCourtCaseDto,
  ) {
    return this.finesService.resolveCourtCase(fineId, data.finalVerdict);
  }

  @ApiOperation({ summary: 'Get all court cases for the district' })
  @Get('district/court-cases')
  @UseGuards(RolesGuard)
  @Roles('DIVISIONAL_HEAD')
  async getDistrictCourtCases(@Req() req: AuthenticatedRequest) {
    const districtId = req.user.districtId;
    return this.finesService.getCourtCasesByDistrict(districtId);
  }

  @ApiOperation({ summary: 'Get district statistics' })
  @Get('district/statistics')
  @UseGuards(RolesGuard)
  @Roles('DIVISIONAL_HEAD')
  async getDistrictStatistics(@Req() req: AuthenticatedRequest) {
    const districtId = req.user.districtId;
    return this.finesService.getDistrictStatistics(districtId);
  }

  @ApiOperation({ summary: 'Get all offense categories' })
  @Get('offenses')
  async getOffenses() {
    return this.finesService.getOffenses();
  }

  @ApiOperation({ summary: 'Verify a license manually' })
  @Get('verify-license/:licenseNumber')
  async verifyLicense(@Param('licenseNumber') licenseNumber: string) {
    return this.finesService.verifyLicense(licenseNumber);
  }

  @ApiOperation({ summary: 'Get fine history issued by the officer' })
  @Get('history')
  async getOfficerHistory(@Req() req: AuthenticatedRequest) {
    const officerId = req.user.id;
    return this.finesService.getOfficerFineHistory(officerId);
  }

  @ApiOperation({ summary: 'Get fine history of the driver' })
  @Get('my-history')
  async getMyFineHistory(@Req() req: AuthenticatedRequest) {
    const userId = req.user.id;
    return this.finesService.getDriverFineHistory(userId);
  }

  @ApiOperation({ summary: 'Calculate total amount for selected fines' })
  @Post('calculate-total')
  async calculateTotal(
    @Body() data: FineIdsDto,
    @Req() req: AuthenticatedRequest,
  ) {
    const userId = req.user.id;
    return this.finesService.calculateTotalAmount(data.fineIds, userId);
  }

  @ApiOperation({ summary: 'Pay selected fines' })
  @Post('pay')
  async payDummyFines(
    @Body() data: FineIdsDto,
    @Req() req: AuthenticatedRequest,
  ) {
    const userId = req.user.id;
    return this.finesService.payFines(data.fineIds, userId);
  }
}
