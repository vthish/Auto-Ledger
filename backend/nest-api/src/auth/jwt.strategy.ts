import { ExtractJwt, Strategy } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable } from '@nestjs/common';

interface JwtPayload {
  sub: string;
  role: string;
  badgeNumber?: string;
  districtId?: string;
  nic?: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor() {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: process.env.JWT_SECRET || 'defaultSecretKey',
    });
  }

  validate(payload: JwtPayload) {
    if (payload.role === 'USER') {
      return {
        id: payload.sub,
        role: payload.role,
        nic: payload.nic,
      };
    }

    return {
      id: payload.sub,
      badgeNumber: payload.badgeNumber,
      role: payload.role,
      districtId: payload.districtId,
    };
  }
}
