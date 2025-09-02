import { Module } from '@nestjs/common';
import { MilestonesController } from './milestones.controller';
import { MilestonesService } from './milestones.service';
import { SupabaseModule } from '../supabase/supabase.module';

@Module({
  imports: [SupabaseModule],
  controllers: [MilestonesController],
  providers: [MilestonesService],
  exports: [MilestonesService]
})
export class MilestonesModule {}