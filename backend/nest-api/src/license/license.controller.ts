import {
  Controller,
  Post,
  Get,
  Patch,
  Body,
  Request,
  UseGuards,
  Param,
  Query,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { LicenseService } from './license.service';
import {
  ApiTags,
  ApiOperation,
  ApiBearerAuth,
  ApiProperty,
  ApiPropertyOptional,
  PartialType,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { DeviceGuard } from '../common/guard/device.guard';
import {
  IsString,
  IsNotEmpty,
  IsDateString,
  IsEnum,
  IsOptional,
  IsArray,
  ValidateNested,
  Matches,
} from 'class-validator';
import { Type } from 'class-transformer';

const NIC_REGEX = /^(?:\d{9}[VvXx]|\d{12})$/;
const NIC_VALIDATION_MESSAGE =
  'NIC must contain 9 digits followed by V/X or exactly 12 digits.';

export interface AuthRequest {
  user: { id: string };
}

interface UploadedFileType {
  buffer: Buffer;
  originalname: string;
  mimetype: string;
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

  @ApiProperty({
    example: '200204802139',
    description:
      'Old NIC: 9 digits followed by V/X. New NIC: exactly 12 digits.',
  })
  @IsString()
  @IsNotEmpty()
  @Matches(NIC_REGEX, { message: NIC_VALIDATION_MESSAGE })
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

export class UpdateStatusDto {
  @ApiProperty({
    example: 'SUSPENDED',
    enum: ['ACTIVE', 'SUSPENDED', 'EXPIRED', 'REVOKED'],
  })
  @IsEnum(['ACTIVE', 'SUSPENDED', 'EXPIRED', 'REVOKED'])
  status: 'ACTIVE' | 'SUSPENDED' | 'EXPIRED' | 'REVOKED';
}

export class UpdateLicenseDto extends PartialType(CreateLicenseDto) {}

@ApiTags('Driving License')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard, DeviceGuard)
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

  @Get('get-upload-url')
  async getUploadUrl(
    @Query('fileName') fileName: string,
    @Query('fileType') fileType: string,
  ) {
    return this.licenseService.getS3UploadUrl(fileName, fileType);
  }

  @ApiOperation({ summary: 'Get current user active license' })
  @Get('my-license')
  async getMyLicense(@Request() req: AuthRequest) {
    return this.licenseService.getMyLicense(req.user.id);
  }

  @Roles('DMT_ADMIN')
  @ApiOperation({ summary: 'Update License Status' })
  @Patch(':id/status')
  async updateStatus(@Param('id') id: string, @Body() data: UpdateStatusDto) {
    return this.licenseService.updateStatus(id, data.status);
  }

  @Roles('DMT_ADMIN', 'POLICE_ADMIN')
  @ApiOperation({ summary: 'Get License by NIC' })
  @Get('search/:nic')
  async getLicenseByNIC(@Param('nic') nic: string) {
    return this.licenseService.getLicenseByNIC(nic);
  }

  @ApiOperation({ summary: 'DMT Admin: Get all licenses (Can filter by NIC)' })
  @Roles('DMT_ADMIN')
  @Get('all')
  async getAllLicenses(@Query('nic') nic?: string) {
    return this.licenseService.getAllLicenses(nic);
  }

  @ApiOperation({ summary: 'DMT Admin: Update License Details' })
  @Roles('DMT_ADMIN')
  @Patch(':id/update')
  async updateLicenseDetails(
    @Param('id') id: string,
    @Body() updateData: UpdateLicenseDto,
  ) {
    return this.licenseService.updateLicenseDetails(id, updateData);
  }

  @ApiOperation({
    summary: 'DMT Admin: Get licenses with Fines (Can filter by NIC)',
  })
  @Roles('DMT_ADMIN')
  @Get('with-fines')
  async getLicensesWithFines(@Query('nic') nic?: string) {
    return this.licenseService.getLicensesWithFines(nic);
  }

  @Roles('DMT_ADMIN')
  @Post('upload-image')
  @UseInterceptors(FileInterceptor('file'))
  @ApiOperation({ summary: 'Upload license image via backend (No CORS)' })
  uploadImage(@UploadedFile() file: UploadedFileType) {
    return this.licenseService.uploadImageToS3(file);
  }

  @ApiOperation({
    summary: 'Divisional Head: Get revoked licenses for their division',
  })
  @Roles('DIVISIONAL_HEAD')
  @Get('revoked')
  async getRevokedLicenses(@Request() req: AuthRequest) {
    return this.licenseService.getRevokedLicenses(req.user.id);
  }

  @Roles('DIVISIONAL_HEAD')
  @Patch(':id/resolve-revoked')
  async resolveRevokedLicense(
    @Param('id') id: string,
    @Body('verdict') verdict: 'ACTIVE' | 'REVOKED',
    @Request() req: AuthRequest,
  ) {
    return await this.licenseService.resolveRevokedLicense(
      id,
      verdict,
      req.user.id,
    );
  }
}
