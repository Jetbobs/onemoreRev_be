import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { Request } from 'express';
import { AuthService, AuthUser } from '../auth.service';

@Injectable()
export class AdminGuard implements CanActivate {
  private readonly logger = new Logger(AdminGuard.name);

  constructor(private authService: AuthService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<Request>();
    const user = request.user;

    if (!user) {
      this.logger.warn('No user found in request - ensure JwtAuthGuard is applied first');
      throw new ForbiddenException('Authentication required');
    }

    if (!this.authService.isAdmin(user)) {
      this.logger.warn(`User ${user.email} attempted admin action without permission`);
      throw new ForbiddenException('Admin access required');
    }

    this.logger.debug(`Admin access granted to ${user.email}`);
    return true;
  }
}

/**
 * 역할 기반 가드 (여러 역할 허용)
 */
@Injectable()
export class RolesGuard implements CanActivate {
  private readonly logger = new Logger(RolesGuard.name);

  constructor(
    private authService: AuthService,
    private readonly allowedRoles: string[]
  ) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest<Request>();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('Authentication required');
    }

    if (!this.authService.hasRole(user, this.allowedRoles)) {
      this.logger.warn(
        `User ${user.email} (${user.role}) attempted action requiring roles: ${this.allowedRoles.join(', ')}`
      );
      throw new ForbiddenException(`Required roles: ${this.allowedRoles.join(', ')}`);
    }

    this.logger.debug(`Role-based access granted to ${user.email} (${user.role})`);
    return true;
  }
}

/**
 * 프로젝트 참여자 가드
 */
@Injectable()
export class ProjectParticipantGuard implements CanActivate {
  private readonly logger = new Logger(ProjectParticipantGuard.name);

  constructor(private authService: AuthService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request>();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('Authentication required');
    }

    // 관리자는 모든 프로젝트 접근 가능
    if (this.authService.isAdmin(user)) {
      return true;
    }

    // URL 파라미터에서 프로젝트 ID 추출
    const projectId = request.params.projectId || request.params.id;
    
    if (!projectId) {
      this.logger.warn('No project ID found in request parameters');
      throw new ForbiddenException('Project ID required');
    }

    const isParticipant = await this.authService.isProjectParticipant(user.id, projectId);
    
    if (!isParticipant) {
      this.logger.warn(`User ${user.email} attempted to access project ${projectId} without permission`);
      throw new ForbiddenException('Project access denied');
    }

    this.logger.debug(`Project access granted to ${user.email} for project ${projectId}`);
    return true;
  }
}