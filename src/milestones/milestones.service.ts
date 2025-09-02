import { Injectable } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class MilestonesService {
  constructor(private readonly supabaseService: SupabaseService) {}

  // 기본 마일스톤 템플릿 생성 (간단 버전)
  async createDefaultTemplate(projectId: string, projectType?: string) {
    try {
      const templates = this.getDefaultMilestoneTemplates();
      const template = templates[projectType || 'default'] || templates['default'];

      const milestones = template.map((item, index) => ({
        project_id: projectId,
        title: item.title,
        description: item.description || '',
        sequence_order: index + 1,
        weight: item.weight,
        status: 'pending'
      }));

      const { data, error } = await this.supabaseService.getClient()
        .from('project_milestones')
        .insert(milestones)
        .select();

      if (error) {
        return {
          success: false,
          message: `템플릿 생성 실패: ${error.message}`,
          error
        };
      }

      return {
        success: true,
        data,
        message: `${projectType || 'default'} 템플릿 마일스톤 생성 완료`
      };
    } catch (err) {
      return {
        success: false,
        message: '템플릿 생성 중 오류 발생',
        error: err
      };
    }
  }

  // 기본 마일스톤 템플릿 정의
  private getDefaultMilestoneTemplates() {
    return {
      'logo_design': [
        { title: '컨셉 스케치 완성', description: '브랜드 컨셉에 맞는 스케치 작업', weight: 1.0 },
        { title: '초안 디자인 완성', description: '첫 번째 디자인 시안 완성', weight: 2.5 },
        { title: '1차 수정 완성', description: '클라이언트 피드백 반영 수정', weight: 1.5 },
        { title: '최종 완성', description: '최종 디자인 완성 및 파일 전달', weight: 1.0 }
      ],
      'default': [
        { title: '프로젝트 기획', description: '프로젝트 방향 설정 및 기획', weight: 1.0 },
        { title: '초안 작업', description: '첫 번째 디자인 시안', weight: 2.0 },
        { title: '수정 작업', description: '피드백 반영 수정', weight: 1.5 },
        { title: '최종 완성', description: '최종 디자인 완성', weight: 1.0 }
      ]
    };
  }
}