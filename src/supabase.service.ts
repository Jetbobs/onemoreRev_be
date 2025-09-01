import { Injectable } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class SupabaseService {
  private supabase: SupabaseClient;

  constructor() {
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_ANON_KEY;

    if (!supabaseUrl || !supabaseKey) {
      throw new Error('Supabase URL and Key must be provided');
    }

    this.supabase = createClient(supabaseUrl, supabaseKey);
  }

  getClient(): SupabaseClient {
    return this.supabase;
  }

  async testConnection(): Promise<{ connected: boolean; message: string }> {
    try {
      // 단순히 supabase auth 상태를 확인
      const { data: { session }, error } = await this.supabase.auth.getSession();

      if (error) {
        return {
          connected: false,
          message: `Connection failed: ${error.message}`,
        };
      }

      return {
        connected: true,
        message: 'Successfully connected to Supabase',
      };
    } catch (error) {
      return {
        connected: false,
        message: `Connection error: ${error.message}`,
      };
    }
  }
}