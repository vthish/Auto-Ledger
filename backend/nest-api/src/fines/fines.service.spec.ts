import { Test, TestingModule } from '@nestjs/testing';
import { FinesService } from './fines.service';

describe('FinesService', () => {
  let service: FinesService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [FinesService],
    }).compile();

    service = module.get<FinesService>(FinesService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
