import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
  Request,
  HttpStatus,
  HttpException,
  Logger,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { AdminGuard } from './guards/admin.guard';

export interface CreateUserProfileDto {
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
}

@Controller('auth')
export class AuthController {
  private readonly logger = new Logger(AuthController.name);

  constructor(private authService: AuthService) {}

  /**
   * 토큰 검증 및 사용자 정보 반환
   */
  @Get('me')
  @UseGuards(JwtAuthGuard)
  async getProfile(@Request() req) {
    try {
      return {
        success: true,
        data: req.user,
        message: 'User profile retrieved successfully',
      };
    } catch (error) {
      this.logger.error('Get profile error:', error.message);
      throw new HttpException(
        'Failed to get user profile',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * 사용자 프로필 생성 (회원가입 완료)
   */
  @Post('profile')
  async createProfile(@Body() createUserDto: CreateUserProfileDto) {
    try {
      this.logger.log(`Creating profile for user: ${createUserDto.email}`);

      const userProfile = await this.authService.createUserProfile(createUserDto);

      return {
        success: true,
        data: userProfile,
        message: 'User profile created successfully',
      };
    } catch (error) {
      this.logger.error('Create profile error:', error.message);
      throw new HttpException(
        `Failed to create user profile: ${error.message}`,
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  /**
   * 사용자 프로필 업데이트
   */
  @Post('profile/update')
  @UseGuards(JwtAuthGuard)
  async updateProfile(@Request() req, @Body() updates: Partial<CreateUserProfileDto>) {
    try {
      this.logger.log(`Updating profile for user: ${req.user.id}`);

      const updatedProfile = await this.authService.updateUserProfile(
        req.user.id,
        updates,
      );

      return {
        success: true,
        data: updatedProfile,
        message: 'User profile updated successfully',
      };
    } catch (error) {
      this.logger.error('Update profile error:', error.message);
      throw new HttpException(
        `Failed to update user profile: ${error.message}`,
        HttpStatus.BAD_REQUEST,
      );
    }
  }

  /**
   * 관리자 전용 - 모든 사용자 목록
   */
  @Get('admin/users')
  @UseGuards(JwtAuthGuard, AdminGuard)
  async getAllUsers(@Request() req) {
    try {
      this.logger.log(`Admin ${req.user.email} requesting all users`);

      // 임시로 간단한 응답 (실제로는 사용자 서비스에서 처리)
      return {
        success: true,
        message: 'Admin endpoint working',
        user: req.user,
      };
    } catch (error) {
      this.logger.error('Admin get users error:', error.message);
      throw new HttpException(
        'Failed to get users',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  /**
   * 토큰 유효성 검사
   */
  @Post('validate-token')
  async validateToken(@Body() { token }: { token: string }) {
    try {
      const user = await this.authService.validateToken(token);

      if (!user) {
        return {
          success: false,
          message: 'Invalid token',
        };
      }

      return {
        success: true,
        data: user,
        message: 'Token is valid',
      };
    } catch (error) {
      this.logger.error('Validate token error:', error.message);
      return {
        success: false,
        message: 'Token validation failed',
        error: error.message,
      };
    }
  }
}