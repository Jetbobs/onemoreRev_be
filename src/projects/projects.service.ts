import { Injectable, Logger } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class ProjectsService {
  private readonly logger = new Logger(ProjectsService.name);

  constructor(private supabaseService: SupabaseService) {}

  /**
   * 모든 프로젝트 조회 (디버그용)
   */
  async getAllProjects() {
    try {
      const supabase = this.supabaseService.getClient();
      
      const { data: projects, error } = await supabase
        .from('projects')
        .select(`
          *,
          client:users!client_id(id, email, name, company),
          designer:users!designer_id(id, email, name)
        `)
        .order('created_at', { ascending: false });

      if (error) {
        this.logger.error('Database error:', error);
        throw error;
      }

      this.logger.log(`Found ${projects?.length || 0} total projects`);
      
      // 각 프로젝트의 상태별 통계 로그
      const statusCount = projects?.reduce((acc, project) => {
        acc[project.status] = (acc[project.status] || 0) + 1;
        return acc;
      }, {}) || {};
      
      this.logger.log('Projects by status:', statusCount);

      return projects || [];
    } catch (error) {
      this.logger.error('Failed to get all projects:', error.message);
      throw error;
    }
  }

  /**
   * 승인된 프로젝트만 조회
   */
  async getActiveProjects() {
    try {
      const supabase = this.supabaseService.getClient();
      
      const { data: projects, error } = await supabase
        .from('projects')
        .select(`
          *,
          client:users!client_id(id, email, name, company),
          designer:users!designer_id(id, email, name)
        `)
        .eq('status', 'active')
        .order('created_at', { ascending: false });

      if (error) {
        this.logger.error('Database error:', error);
        throw error;
      }

      this.logger.log(`Found ${projects?.length || 0} active projects`);

      return projects || [];
    } catch (error) {
      this.logger.error('Failed to get active projects:', error.message);
      throw error;
    }
  }

  /**
   * 모든 제안서 조회 (디버그용)
   */
  async getAllProposals() {
    try {
      const supabase = this.supabaseService.getClient();
      
      const { data: proposals, error } = await supabase
        .from('proposals')
        .select(`
          id, project_id, designer_id, title, description, 
          proposed_budget, additional_modification_fee,
          estimated_duration, approach, deliverables, 
          timeline_description, sample_works, status,
          created_at, updated_at, responded_at,
          project:projects(*),
          designer:users!designer_id(id, email, name)
        `)
        .order('created_at', { ascending: false });

      if (error) {
        this.logger.error('Database error:', error);
        throw error;
      }

      this.logger.log(`Found ${proposals?.length || 0} total proposals`);

      return proposals || [];
    } catch (error) {
      this.logger.error('Failed to get all proposals:', error.message);
      throw error;
    }
  }

  /**
   * 사용자별 프로젝트 조회
   */
  async getUserProjects(userId: string, userEmail: string, userRole: string) {
    try {
      const supabase = this.supabaseService.getClient();
      
      let query = supabase
        .from('projects')
        .select(`
          *,
          client:users!client_id(id, email, name, company),
          designer:users!designer_id(id, email, name)
        `);

      // 사용자 역할에 따라 필터링
      if (userRole === 'client') {
        query = query.or(`client_id.eq.${userId},client_email.eq.${userEmail}`);
      } else if (userRole === 'designer') {
        query = query.eq('designer_id', userId);
      }

      const { data: projects, error } = await query
        .neq('status', 'archived')
        .order('created_at', { ascending: false });

      if (error) {
        this.logger.error('Database error:', error);
        throw error;
      }

      this.logger.log(`Found ${projects?.length || 0} projects for user ${userId} (${userRole})`);

      return projects || [];
    } catch (error) {
      this.logger.error('Failed to get user projects:', error.message);
      throw error;
    }
  }
}