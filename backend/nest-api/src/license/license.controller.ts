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
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiProperty,
  ApiPropertyOptional,
} from '@nestjs/swagger';
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
  @ApiProperty({ example: 'B' })
  @IsString()
  @IsNotEmpty()
  vehicleClass: string;

  @ApiProperty({ example: '2024-01-01T00:00:00Z' })
  @IsDateString()
  issueDate: Date;

  @ApiProperty({ example: '2032-01-01T00:00:00Z' })
  @IsDateString()
  expiryDate: Date;

  @ApiPropertyOptional({ example: 'AT' })
  @IsString()
  @IsOptional()
  restriction?: string;
}

export class CreateLicenseDto {
  @ApiProperty({ example: 'B1234567' })
  @IsString()
  @IsNotEmpty()
  licenseNo: string;

  @ApiProperty({ example: 'K.V.V. Thishan' })
  @IsString()
  @IsNotEmpty()
  fullName: string;

  @ApiProperty({ example: '200204802139' })
  @IsString()
  @IsNotEmpty()
  nicNo: string;

  @ApiProperty({ example: 'No 10, Galle Road, Galle' })
  @IsString()
  @IsNotEmpty()
  address: string;

  @ApiProperty({ example: 'O+' })
  @IsString()
  @IsNotEmpty()
  bloodGroup: string;

  @ApiProperty({ example: '2000-01-01T00:00:00Z' })
  @IsDateString()
  dateOfBirth: Date;

  @ApiProperty({ example: '2024-01-01T00:00:00Z' })
  @IsDateString()
  issueDate: Date;

  @ApiPropertyOptional({ example: 'base64_image_string' })
  @IsString()
  @IsOptional()
  image?: string;

  @ApiProperty({ type: [VehicleCategoryDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => VehicleCategoryDto)
  categories: VehicleCategoryDto[];
}

export class ScanQRDto {
  @ApiProperty({ example: 'License_ID:RandomHash:Timestamp' })
  @IsString()
  @IsNotEmpty()
  qrToken: string;

  @ApiPropertyOptional({ example: 'Galle Fort' })
  @IsString()
  @IsOptional()
  location?: string;
}

export class UpdateStatusDto {
  @ApiProperty({
    example: 'SUSPENDED',
    enum: ['ACTIVE', 'SUSPENDED', 'EXPIRED', 'REVOKED'],
  })
  @IsEnum(['ACTIVE', 'SUSPENDED', 'EXPIRED', 'REVOKED'])
  status: 'ACTIVE' | 'SUSPENDED' | 'EXPIRED' | 'REVOKED';
}

@ApiTags('Driving License')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('license')
export class LicenseController {
  constructor(private readonly licenseService: LicenseService) {}

  @ApiOperation({ summary: 'Create a new driving license' })
  @Post()
  async createLicense(
    @Request() req: AuthRequest,
    @Body() data: CreateLicenseDto,
  ) {
    return this.licenseService.createLicense({
      licenseNo: data.licenseNo,
      fullName: data.fullName,
      nicNo: data.nicNo,
      address: data.address,
      bloodGroup: data.bloodGroup,
      dateOfBirth: data.dateOfBirth,
      issueDate: data.issueDate,
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

  @ApiOperation({ summary: 'Scan License QR Code' })
  @Post('scan-qr')
  async scanQR(@Request() req: AuthRequest, @Body() data: ScanQRDto) {
    return this.licenseService.scanLicenseQR(
      data.qrToken,
      req.user.id,
      data.location,
    );
  }

  @ApiOperation({ summary: 'Update License Status' })
  @Patch(':id/status')
  async updateStatus(@Param('id') id: string, @Body() data: UpdateStatusDto) {
    return this.licenseService.updateStatus(id, data.status);
  }

  @ApiOperation({ summary: 'Get License by NIC (Admin/Officer Only)' })
  @Get('search/:nic')
  async getLicenseByNIC(@Param('nic') nic: string) {
    return this.licenseService.getLicenseByNIC(nic);
  }
}
