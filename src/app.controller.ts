import { Controller, Get } from '@nestjs/common';
import { AppService } from './app.service';
import { SupabaseService } from './supabase/supabase.service';

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly supabaseService: SupabaseService,
  ) {}

  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  @Get('health')
  async getHealth() {
    const isSupabaseConnected = await this.supabaseService.testConnection();
    
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      services: {
        supabase: isSupabaseConnected ? 'connected' : 'disconnected',
      },
      message: 'Deegongso Backend API is running',
    };
  }

  @Get('health/supabase')
  async checkSupabaseConnection() {
    const isConnected = await this.supabaseService.testConnection();
    
    return {
      supabase: isConnected,
      message: isConnected 
        ? 'Supabase connection successful' 
        : 'Supabase connection failed',
    };
  }
}
