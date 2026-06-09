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
import { FinesService } from './fines.service';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import {
  IsString,
  IsNotEmpty,
  IsArray,
  IsEnum,
  IsOptional,
} from 'class-validator';

export interface AuthRequest {
  user: { id: string };
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
}
