# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillNullProjectOnCiStagesRecords, migration: :gitlab_ci, feature_category: :database do
  let(:pipelines_table) { table(:p_ci_pipelines, primary_key: :id, database: :ci) }
  let(:stages_table) { table(:p_ci_stages, primary_key: :id, database: :ci) }

  let!(:pipeline_with_project) { pipelines_table.create!(project_id: 42, partition_id: 100) }
  let!(:stage_to_be_backfilled) do
    stages_table.create!(name: 'backfilled', pipeline_id: pipeline_with_project.id, partition_id: 100)
  end

  let!(:stage_with_project_id) { stages_table.create!(name: 'standard', project_id: 11, partition_id: 100) }
  let!(:stage_orphaned) { stages_table.create!(name: 'deleted', partition_id: 100) }

  describe '#up' do
    it 'backfills applicable records' do
      expect { migrate! }
      .to change { stage_to_be_backfilled.reload.project_id }.from(nil).to(pipeline_with_project.project_id)
      .and not_change { stage_with_project_id.reload.project_id }.from(11)
    end

    it 'deletes orphaned records' do
      expect { migrate! }.to change { stages_table.count }.by(-1)

      expect { stage_orphaned.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
