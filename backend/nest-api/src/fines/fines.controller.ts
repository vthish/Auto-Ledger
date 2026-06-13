import {
  Controller,
  Post,
  Get,
  Patch,
  Delete,
  Body,
  Request,
  UseGuards,
  Param,
} from '@nestjs/common';
import { FinesService } from './fines.service';
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
  IsArray,
  IsEnum,
  IsOptional,
  IsNumber,
  IsBoolean,
} from 'class-validator';

export interface AuthRequest {
  user: { id: string; role?: string };
}

export class IssueFineDto {
  @ApiProperty({ example: 'License_UUID_Here' })
  @IsString()
  @IsNotEmpty()
  licenseId: string;

  @ApiProperty({ example: ['Offense_UUID_1', 'Offense_UUID_2'] })
  @IsArray()
  @IsString({ each: true })
  offenseIds: string[];

  @ApiPropertyOptional({ example: 'Speeding over 80kmph' })
  @IsString()
  @IsOptional()
  comment?: string;
}

export class CourtVerdictDto {
  @ApiProperty({ example: 'ACTIVE', enum: ['ACTIVE', 'REVOKED'] })
  @IsEnum(['ACTIVE', 'REVOKED'])
  verdict: 'ACTIVE' | 'REVOKED';
}

export class CreateOffenseDto {
  @ApiProperty({ example: 'SPD-001' })
  @IsString()
  @IsNotEmpty()
  code: string;

  @ApiProperty({ example: 'Overspeeding' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 3 })
  @IsNumber()
  @IsNotEmpty()
  points: number;

  @ApiProperty({ example: 3000 })
  @IsNumber()
  @IsNotEmpty()
  amount: number;

  @ApiProperty({ example: false })
  @IsBoolean()
  @IsNotEmpty()
  isCourtCase: boolean;
}

export class UpdateOffenseDto {
  @ApiPropertyOptional({ example: 'Overspeeding Heavy' })
  @IsString()
  @IsOptional()
  name?: string;

  @ApiPropertyOptional({ example: 4 })
  @IsNumber()
  @IsOptional()
  points?: number;

  @ApiPropertyOptional({ example: 5000 })
  @IsNumber()
  @IsOptional()
  amount?: number;

  @ApiPropertyOptional({ example: true })
  @IsBoolean()
  @IsOptional()
  isCourtCase?: boolean;
}

export class PayFineDto {
  @ApiProperty({ example: 5000 })
  @IsNumber()
  @IsNotEmpty()
  amount: number;

  @ApiProperty({ example: 'CREDIT_CARD' })
  @IsString()
  @IsNotEmpty()
  paymentMethod: string;
}

@ApiTags('Fines & Penalties')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('fines')
export class FinesController {
  constructor(private readonly finesService: FinesService) {}

  @ApiOperation({ summary: 'Issue a new fine (Traffic Officer Only)' })
  @Post()
  async issueFine(@Request() req: AuthRequest, @Body() data: IssueFineDto) {
    return this.finesService.issueFine({
      licenseId: data.licenseId,
      officerId: req.user.id,
      offenseIds: data.offenseIds,
      comment: data.comment,
    });
  }

  @ApiOperation({ summary: 'Get all fines for current driver' })
  @Get('my-fines')
  async getMyFines(@Request() req: AuthRequest) {
    return this.finesService.getMyFines(req.user.id);
  }

  @ApiOperation({ summary: 'Pay a Fine (User / Driver)' })
  @Post(':id/pay')
  async payFine(@Param('id') fineId: string, @Body() data: PayFineDto) {
    return this.finesService.payFine(fineId, data.amount, data.paymentMethod);
  }

  @ApiOperation({
    summary: 'Process Court Case Verdict (Divisional Head Only)',
  })
  @Patch('court-case/:id')
  async processCourtCase(
    @Param('id') fineId: string,
    @Body() data: CourtVerdictDto,
  ) {
    return this.finesService.updateCourtCase(fineId, data.verdict);
  }

  @ApiOperation({ summary: 'Get all Offense Categories (Police Admin Only)' })
  @Get('offense')
  async getAllOffenses() {
    return this.finesService.getAllOffenses();
  }

  @ApiOperation({ summary: 'Create Offense Category (Police Admin Only)' })
  @Post('offense')
  async createOffenseCategory(
    @Request() req: AuthRequest,
    @Body() data: CreateOffenseDto,
  ) {
    return this.finesService.createOffenseCategory(data, req.user.id);
  }

  @ApiOperation({ summary: 'Update Offense Category (Police Admin Only)' })
  @Patch('offense/:id')
  async updateOffenseCategory(
    @Param('id') offenseId: string,
    @Body() data: UpdateOffenseDto,
  ) {
    return this.finesService.updateOffenseCategory(offenseId, data);
  }

  @ApiOperation({ summary: 'Delete Offense Category (Police Admin Only)' })
  @Delete('offense/:id')
  async deleteOffenseCategory(@Param('id') offenseId: string) {
    return this.finesService.deleteOffenseCategory(offenseId);
  }
}
