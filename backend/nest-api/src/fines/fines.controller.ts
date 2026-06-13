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
  @IsString()
  @IsNotEmpty()
  licenseId: string;

  @IsArray()
  @IsString({ each: true })
  offenseIds: string[];

  @IsString()
  @IsOptional()
  comment?: string;
}

export class CourtVerdictDto {
  @IsEnum(['ACTIVE', 'REVOKED'])
  verdict: 'ACTIVE' | 'REVOKED';
}

export class CreateOffenseDto {
  @IsString()
  @IsNotEmpty()
  code: string;

  @IsString()
  @IsNotEmpty()
  name: string;

  @IsNumber()
  @IsNotEmpty()
  points: number;

  @IsNumber()
  @IsNotEmpty()
  amount: number;

  @IsBoolean()
  @IsNotEmpty()
  isCourtCase: boolean;
}

export class UpdateOffenseDto {
  @IsString()
  @IsOptional()
  name?: string;

  @IsNumber()
  @IsOptional()
  points?: number;

  @IsNumber()
  @IsOptional()
  amount?: number;

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
