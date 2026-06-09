import { ExtractJwt, Strategy } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable } from '@nestjs/common';

interface JwtPayload {
  sub: string;
  role: string;
  badgeNo?: string;
  divisionId?: string;
  headId?: string;
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
      return { id: payload.sub, role: payload.role, nic: payload.nic };
    }

    if (payload.role === 'DMT_ADMIN' || payload.role === 'POLICE_ADMIN') {
      return { id: payload.sub, role: payload.role };
    }

    return {
      id: payload.sub,
      role: payload.role,
      badgeNo: payload.badgeNo,
      divisionId: payload.divisionId,
      headId: payload.headId,
    };
  }
}
