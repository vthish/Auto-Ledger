import { Test, TestingModule } from '@nestjs/testing';
import { FinesController } from './fines.controller';

describe('FinesController', () => {
  let controller: FinesController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [FinesController],
    }).compile();

    controller = module.get<FinesController>(FinesController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });
});
