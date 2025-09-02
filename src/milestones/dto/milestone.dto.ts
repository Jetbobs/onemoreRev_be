export class CreateMilestoneDto {
  title: string;
  description?: string;
  sequence_order: number;
  weight: number;
  status?: string;
}

export class UpdateMilestoneDto {
  title?: string;
  description?: string;
  sequence_order?: number;
  weight?: number;
  status?: string;
}