import { Test, TestingModule } from '@nestjs/testing';
import { LicenseController } from './license.controller';

describe('LicenseController', () => {
  let controller: LicenseController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [LicenseController],
    }).compile();

    controller = module.get<LicenseController>(LicenseController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
