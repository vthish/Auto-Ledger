/* eslint-disable @typescript-eslint/no-unsafe-argument */
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { AppModule } from './../src/app.module';

describe('Auto-Ledger API E2E Tests', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  it('/ (GET) - Health Check should return 200', () => {
    return request(app.getHttpServer()).get('/').expect(200);
  });

  it('/auth/login (POST) - Divisional Head should login successfully', () => {
    return request(app.getHttpServer())
      .post('/auth/login')
      .send({
        badgeNumber: 'HEAD-GALLE-01',
        password: 'headpassword123',
      })
      .expect(201)
      .then((response) => {
        const body = response.body as {
          accessToken: string;
          officer: { role: string };
        };
        expect(body).toHaveProperty('accessToken');
        expect(body).toHaveProperty('officer');
        expect(body.officer.role).toEqual('DIVISIONAL_HEAD');
      });
  });

  it('/auth/login (POST) - Invalid credentials should return 401', () => {
    return request(app.getHttpServer())
      .post('/auth/login')
      .send({
        badgeNumber: 'HEAD-GALLE-01',
        password: 'wrongpassword',
      })
      .expect(401);
  });

  afterAll(async () => {
    await app.close();
  });
});
