import { Controller, Get, Post, Body, Param } from '@nestjs/common';
import { MilestonesService } from './milestones.service';

@Controller('milestones')
export class MilestonesController {
  constructor(private readonly milestonesService: MilestonesService) {}

  // 테스트용 간단한 마일스톤 조회
  @Get('project/:projectId')
  async getProjectMilestones(@Param('projectId') projectId: string) {
    return { message: `마일스톤 조회: ${projectId}`, data: [] };
  }

  // 기본 템플릿 생성 테스트
  @Post('project/:projectId/create-template')
  async createTemplate(
    @Param('projectId') projectId: string,
    @Body() body: { projectType?: string }
  ) {
    return this.milestonesService.createDefaultTemplate(projectId, body.projectType || 'default');
  }
}