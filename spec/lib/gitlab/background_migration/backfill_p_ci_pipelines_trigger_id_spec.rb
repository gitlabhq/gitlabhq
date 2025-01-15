# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPCiPipelinesTriggerId,
  migration: :gitlab_ci, feature_category: :continuous_integration do
  let(:migration) do
    described_class.new(
      batch_table: :ci_trigger_requests,
      batch_column: :id,
      job_arguments: [nil],
      sub_batch_size: 2,
      pause_ms: 2,
      connection: ci_pipeline.connection
    )
  end

  let(:ci_pipeline) { table(:p_ci_pipelines, primary_key: :id) }
  let(:ci_build) { table(:p_ci_builds, primary_key: :id) }
  let(:ci_trigger) { table(:ci_triggers) }
  let(:ci_trigger_request) { table(:ci_trigger_requests) }

  let!(:trigger1) { ci_trigger.create!(owner_id: 1) }
  let!(:trigger2) { ci_trigger.create!(owner_id: 1) }
  let!(:trigger3) { ci_trigger.create!(owner_id: 1) }
  let!(:trigger4) { ci_trigger.create!(owner_id: 1) }
  let!(:pipeline1) { ci_pipeline.create!(partition_id: 100, project_id: 1) }
  let!(:pipeline2) { ci_pipeline.create!(partition_id: 100, project_id: 1) }
  let!(:pipeline3) { ci_pipeline.create!(partition_id: 100, project_id: 1) }

  let!(:build1) { ci_build.create!(partition_id: pipeline1.partition_id, commit_id: pipeline1.id, project_id: 1) }
  let!(:build11) { ci_build.create!(partition_id: pipeline1.partition_id, commit_id: pipeline1.id, project_id: 1) }
  let!(:build2) { ci_build.create!(partition_id: pipeline2.partition_id, commit_id: pipeline2.id, project_id: 1) }
  let!(:build22) { ci_build.create!(partition_id: pipeline2.partition_id, commit_id: pipeline2.id, project_id: 1) }
  let!(:build3) { ci_build.create!(partition_id: pipeline3.partition_id, commit_id: pipeline3.id, project_id: 1) }
  let!(:build33) { ci_build.create!(partition_id: pipeline3.partition_id, commit_id: pipeline3.id, project_id: 1) }

  context 'when ci_trigger_requests belongs to only one pipeline' do
    before do
      ci_trigger_request.create!(commit_id: pipeline1.id, trigger_id: trigger1.id)
      ci_trigger_request.create!(commit_id: pipeline2.id, trigger_id: trigger2.id)
      ci_trigger_request.create!(commit_id: pipeline3.id, trigger_id: trigger3.id)
      ci_trigger_request.create!(commit_id: nil, trigger_id: trigger4.id)
    end

    it 'updates p_ci_pipelines.trigger_id' do
      expect { migration.perform }
        .to change { pipeline1.reload.trigger_id }.from(nil).to(trigger1.id)
        .and change { pipeline2.reload.trigger_id }.from(nil).to(trigger2.id)
        .and change { pipeline3.reload.trigger_id }.from(nil).to(trigger3.id)
    end

    context 'when pipeline has incorrect trigger_id' do
      let!(:pipeline1) { ci_pipeline.create!(partition_id: 100, project_id: 1, trigger_id: trigger3.id) }
      let!(:pipeline2) { ci_pipeline.create!(partition_id: 100, project_id: 1, trigger_id: trigger1.id) }

      it 'updates p_ci_pipelines.trigger_id' do
        expect { migration.perform }
          .to change { pipeline1.reload.trigger_id }.from(trigger3.id).to(trigger1.id)
          .and change { pipeline2.reload.trigger_id }.from(trigger1.id).to(trigger2.id)
          .and change { pipeline3.reload.trigger_id }.from(nil).to(trigger3.id)
      end
    end
  end

  context 'when ci_trigger_requests belongs to multiple pipelines' do
    before do
      ci_trigger_request.create!(commit_id: pipeline1.id, trigger_id: trigger1.id)
      ci_trigger_request.create!(commit_id: pipeline1.id, trigger_id: trigger1.id)
      ci_trigger_request.create!(commit_id: pipeline1.id, trigger_id: trigger1.id)
      ci_trigger_request.create!(commit_id: pipeline2.id, trigger_id: trigger2.id)
      ci_trigger_request.create!(commit_id: pipeline3.id, trigger_id: trigger3.id)
      ci_trigger_request.create!(commit_id: nil, trigger_id: trigger4.id)
    end

    it 'updates p_ci_pipelines.trigger_id' do
      expect { migration.perform }
        .to change { pipeline1.reload.trigger_id }.from(nil).to(trigger1.id)
        .and change { pipeline2.reload.trigger_id }.from(nil).to(trigger2.id)
        .and change { pipeline3.reload.trigger_id }.from(nil).to(trigger3.id)
    end
  end
end
