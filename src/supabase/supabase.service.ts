import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class SupabaseService {
  private readonly logger = new Logger(SupabaseService.name);
  private supabase: SupabaseClient;
  private supabaseAdmin: SupabaseClient;

  constructor(private configService: ConfigService) {
    const supabaseUrl = this.configService.get<string>('SUPABASE_URL');
    const supabaseAnonKey = this.configService.get<string>('SUPABASE_ANON_KEY');
    const supabaseServiceKey = this.configService.get<string>('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !supabaseAnonKey || !supabaseServiceKey) {
      this.logger.error('Missing Supabase configuration');
      throw new Error('Missing Supabase configuration');
    }

    // 일반 클라이언트 (RLS 적용됨)
    this.supabase = createClient(supabaseUrl, supabaseAnonKey);

    // 관리자 클라이언트 (RLS 우회, 서버사이드 전용)
    this.supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    this.logger.log('Supabase clients initialized successfully');
  }

  /**
   * 일반 Supabase 클라이언트 (RLS 적용)
   * 사용자 컨텍스트가 필요한 작업에 사용
   */
  getClient(): SupabaseClient {
    return this.supabase;
  }

  /**
   * 관리자 Supabase 클라이언트 (RLS 우회)
   * 서버사이드 로직, 관리자 작업에 사용
   */
  getAdminClient(): SupabaseClient {
    return this.supabaseAdmin;
  }

  /**
   * JWT 토큰으로 사용자 인증된 클라이언트 반환
   */
  getAuthenticatedClient(accessToken: string): SupabaseClient {
    // Note: Supabase-js v2에서는 setAuth 대신 다른 방법 사용
    const authenticatedClient = createClient(
      this.configService.get<string>('SUPABASE_URL')!,
      this.configService.get<string>('SUPABASE_ANON_KEY')!,
      {
        global: {
          headers: {
            Authorization: `Bearer ${accessToken}`,
          },
        },
      }
    );
    return authenticatedClient;
  }

  /**
   * 연결 테스트
   */
  async testConnection(): Promise<boolean> {
    try {
      // 더 간단한 연결 테스트: users 테이블에서 첫 번째 행만 조회
      const { data, error } = await this.supabaseAdmin
        .from('users')
        .select('id')
        .limit(1);

      if (error) {
        // 테이블이 없을 수도 있으므로 warning으로 처리
        this.logger.warn('Supabase connection test warning:', error.message);
        
        // 테이블이 없는 경우에도 연결 자체는 성공으로 처리
        if (error.message.includes('relation "public.users" does not exist')) {
          this.logger.log('Supabase connection successful (users table not yet created)');
          return true;
        }
        return false;
      }

      this.logger.log('Supabase connection test successful');
      return true;
    } catch (err) {
      this.logger.error('Supabase connection test error:', err.message);
      return false;
    }
  }
}