import {
  Controller,
  Get,
  Post,
  UseGuards,
  Request,
  Logger,
  Query,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ProjectsService } from './projects.service';
import { SupabaseService } from '../supabase/supabase.service';

@Controller('projects')
export class ProjectsController {
  private readonly logger = new Logger(ProjectsController.name);

  constructor(
    private projectsService: ProjectsService,
    private supabaseService: SupabaseService,
  ) {}

  /**
   * 모든 프로젝트 조회 (디버그용 - 인증 불필요)
   */
  @Get('debug/all')
  async getAllProjectsDebug() {
    try {
      this.logger.log(`Getting all projects for debugging (no auth)`);

      const projects = await this.projectsService.getAllProjects();

      return {
        success: true,
        data: projects,
        count: projects.length,
        message: 'All projects retrieved successfully (debug mode)',
      };
    } catch (error) {
      this.logger.error('Get all projects debug error:', error.message);
      throw new HttpException(
        'Failed to get projects (debug)',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * 모든 프로젝트 조회 (디버그용)
   */
  @Get('all')
  @UseGuards(JwtAuthGuard)
  async getAllProjects(@Request() req) {
    try {
      this.logger.log(`Getting all projects for debugging`);

      const projects = await this.projectsService.getAllProjects();

      return {
        success: true,
        data: projects,
        count: projects.length,
        message: 'All projects retrieved successfully',
      };
    } catch (error) {
      this.logger.error('Get all projects error:', error.message);
      throw new HttpException(
        'Failed to get projects',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * 승인된 프로젝트만 조회
   */
  @Get('active')
  @UseGuards(JwtAuthGuard)
  async getActiveProjects(@Request() req) {
    try {
      this.logger.log(`Getting active projects`);

      const projects = await this.projectsService.getActiveProjects();

      return {
        success: true,
        data: projects,
        count: projects.length,
        message: 'Active projects retrieved successfully',
      };
    } catch (error) {
      this.logger.error('Get active projects error:', error.message);
      throw new HttpException(
        'Failed to get active projects',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * 제안서 데이터 조회 (디버그용)
   */
  @Get('debug/proposals')
  async getAllProposalsDebug() {
    try {
      this.logger.log(`Getting all proposals for debugging (no auth)`);

      const proposals = await this.projectsService.getAllProposals();

      return {
        success: true,
        data: proposals,
        count: proposals.length,
        message: 'All proposals retrieved successfully (debug mode)',
      };
    } catch (error) {
      this.logger.error('Get all proposals debug error:', error.message);
      throw new HttpException(
        'Failed to get proposals (debug)',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * 사용자별 프로젝트 조회
   */
  @Get('my')
  @UseGuards(JwtAuthGuard)
  async getMyProjects(@Request() req) {
    try {
      this.logger.log(`Getting projects for user: ${req.user.id} (${req.user.role})`);

      const projects = await this.projectsService.getUserProjects(
        req.user.id,
        req.user.email,
        req.user.role,
      );

      return {
        success: true,
        data: projects,
        count: projects.length,
        message: 'User projects retrieved successfully',
      };
    } catch (error) {
      this.logger.error('Get user projects error:', error.message);
      throw new HttpException(
        'Failed to get user projects',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * 마이그레이션 실행 (개발용)
   */
  @Post('debug/migrate')
  async runMigration() {
    try {
      this.logger.log('Running additional_modification_fee migration');

      const migrationSql = 'ALTER TABLE proposals ADD COLUMN additional_modification_fee INTEGER DEFAULT 0;';
      
      // Raw SQL 실행을 위한 간단한 방법
      const supabaseAdmin = this.supabaseService.getAdminClient();
      const { data, error } = await supabaseAdmin
        .from('proposals')
        .select('id')
        .limit(1); // 테스트 쿼리

      if (error && error.message.includes('additional_modification_fee')) {
        // 이미 컬럼이 있음
        return {
          success: true,
          message: 'Column already exists',
        };
      }

      // 실제 마이그레이션은 Supabase 대시보드에서 수행해야 함
      return {
        success: false,
        message: 'Please run migration in Supabase dashboard SQL editor',
        sql: migrationSql,
      };
    } catch (error) {
      this.logger.error('Migration error:', error.message);
      throw new HttpException(
        'Migration failed',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}