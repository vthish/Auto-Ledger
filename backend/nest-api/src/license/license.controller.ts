import {
  Controller,
  Post,
  Get,
  Patch,
  Body,
  Request,
  UseGuards,
  Param,
} from '@nestjs/common';
import { LicenseService } from './license.service';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import {
  IsString,
  IsNotEmpty,
  IsDateString,
  IsEnum,
  IsOptional,
  IsArray,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';

export interface AuthRequest {
  user: { id: string };
}

export class VehicleCategoryDto {
  @IsString()
  @IsNotEmpty()
  vehicleClass: string;

  @IsDateString()
  issueDate: Date;

  @IsDateString()
  expiryDate: Date;

  @IsString()
  @IsOptional()
  restriction?: string;
}

export class CreateLicenseDto {
  @IsString()
  @IsNotEmpty()
  licenseNo: string;

  @IsString()
  @IsNotEmpty()
  address: string;

  @IsString()
  @IsNotEmpty()
  bloodGroup: string;

  @IsDateString()
  dateOfBirth: Date;

  @IsDateString()
  issueDate: Date;

  @IsString()
  @IsNotEmpty()
  userId: string;

  @IsString()
  @IsOptional()
  image?: string;

  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => VehicleCategoryDto)
  categories: VehicleCategoryDto[];
}

export class ScanQRDto {
  @IsString()
  @IsNotEmpty()
  qrToken: string;

  @IsString()
  @IsOptional()
  location?: string;
}

export class UpdateStatusDto {
  @IsEnum(['ACTIVE', 'SUSPENDED', 'EXPIRED', 'REVOKED'])
  status: 'ACTIVE' | 'SUSPENDED' | 'EXPIRED' | 'REVOKED';
}

@ApiTags('Driving License')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('license')
export class LicenseController {
  constructor(private readonly licenseService: LicenseService) {}

  @ApiOperation({ summary: 'Create a new driving license (DMT Admin Only)' })
  @Post()
  async createLicense(
    @Request() req: AuthRequest,
    @Body() data: CreateLicenseDto,
  ) {
    return this.licenseService.createLicense({
      licenseNo: data.licenseNo,
      address: data.address,
      bloodGroup: data.bloodGroup,
      dateOfBirth: data.dateOfBirth,
      issueDate: data.issueDate,
      userId: data.userId,
      image: data.image,
      categories: data.categories,
      dmtAdminId: req.user.id,
    });
  }

  @ApiOperation({ summary: 'Get current user active license' })
  @Get('my-license')
  async getMyLicense(@Request() req: AuthRequest) {
    return this.licenseService.getMyLicense(req.user.id);
  }

  @ApiOperation({ summary: 'Generate 3-Minute QR Code for License' })
  @Get('generate-qr')
  async generateQR(@Request() req: AuthRequest) {
    return this.licenseService.generateLicenseQR(req.user.id);
  }

  @ApiOperation({ summary: 'Scan License QR Code (Traffic Officer Only)' })
  @Post('scan-qr')
  async scanQR(@Request() req: AuthRequest, @Body() data: ScanQRDto) {
    return this.licenseService.scanLicenseQR(
      data.qrToken,
      req.user.id,
      data.location,
    );
  }

  @ApiOperation({
    summary: 'Update License Status (DMT Admin / Divisional Head)',
  })
  @Patch(':id/status')
  async updateStatus(@Param('id') id: string, @Body() data: UpdateStatusDto) {
    return this.licenseService.updateStatus(id, data.status);
  }
}
