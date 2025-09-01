import { Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { User } from '@supabase/supabase-js';

export interface AuthUser {
  id: string;
  email: string;
  name: string;
  role: 'client' | 'designer' | 'admin';
  phone?: string;
  company?: string;
  department?: string;
  experience?: string;
  user_metadata?: any;
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(private supabaseService: SupabaseService) {}

  /**
   * JWT 토큰으로 사용자 인증
   */
  async validateToken(token: string): Promise<AuthUser | null> {
    try {
      // 관리자 클라이언트로 토큰 검증
      const supabaseAdmin = this.supabaseService.getAdminClient();
      
      // JWT 토큰 검증
      const { data: { user }, error } = await supabaseAdmin.auth.getUser(token);

      if (error || !user) {
        this.logger.warn('Token validation failed:', error?.message);
        return null;
      }

      // 사용자 프로필 정보 조회
      const { data: profile, error: profileError } = await supabaseAdmin
        .from('users')
        .select('id, email, name, role, phone, company, department, experience')
        .eq('id', user.id)
        .single();

      if (profileError || !profile) {
        this.logger.warn('User profile not found:', profileError?.message);
        return null;
      }

      return {
        id: (profile as any).id,
        email: (profile as any).email,
        name: (profile as any).name,
        role: (profile as any).role as 'client' | 'designer' | 'admin',
        phone: (profile as any).phone,
        company: (profile as any).company,
        department: (profile as any).department,
        experience: (profile as any).experience,
        user_metadata: user.user_metadata,
      };
    } catch (error) {
      this.logger.error('Token validation error:', error.message);
      return null;
    }
  }

  /**
   * 사용자 권한 체크
   */
  hasRole(user: AuthUser, requiredRoles: string[]): boolean {
    return requiredRoles.includes(user.role);
  }

  /**
   * 관리자 권한 체크
   */
  isAdmin(user: AuthUser): boolean {
    return user.role === 'admin';
  }

  /**
   * 프로젝트 참여자 권한 체크
   */
  async isProjectParticipant(userId: string, projectId: string): Promise<boolean> {
    try {
      const { data, error } = await this.supabaseService
        .getAdminClient()
        .from('projects')
        .select('client_id, designer_id')
        .eq('id', projectId)
        .single();

      if (error || !data) {
        return false;
      }

      return (data as any).client_id === userId || (data as any).designer_id === userId;
    } catch (error) {
      this.logger.error('Project participant check error:', error.message);
      return false;
    }
  }

  /**
   * 사용자 생성 (회원가입 완료 후)
   */
  async createUserProfile(userData: {
    id: string;
    email: string;
    name: string;
    role: 'client' | 'designer';
    phone?: string;
    company?: string;
    department?: string;
    title?: string;
    experience?: string;
    specialization?: string[];
    portfolio_url?: string;
    bio?: string;
  }) {
    try {
      const { data, error } = await this.supabaseService
        .getAdminClient()
        .from('users')
        .insert(userData as any)
        .select()
        .single();

      if (error) {
        this.logger.error('User profile creation failed:', error.message);
        throw new Error(`Failed to create user profile: ${error.message}`);
      }

      return data;
    } catch (error) {
      this.logger.error('Create user profile error:', error.message);
      throw error;
    }
  }

  /**
   * 사용자 프로필 업데이트
   */
  async updateUserProfile(userId: string, updates: Partial<AuthUser>) {
    try {
      const { data, error } = await this.supabaseService
        .getAdminClient()
        .from('users')
        .update(updates as any)
        .eq('id', userId)
        .select()
        .single();

      if (error) {
        this.logger.error('User profile update failed:', error.message);
        throw new Error(`Failed to update user profile: ${error.message}`);
      }

      return data;
    } catch (error) {
      this.logger.error('Update user profile error:', error.message);
      throw error;
    }
  }
}