# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPCiPipelineVariablesFromCiTriggerRequests,
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
  let(:ci_trigger_request) { table(:ci_trigger_requests) { |klass| klass.serialize :variables } }
  let(:ci_pipeline_variable) do
    table(:p_ci_pipeline_variables, primary_key: :id) do |klass|
      klass.include(::Ci::HasVariable)
      klass.include(::Ci::RawVariable)
    end
  end

  let!(:trigger1) { ci_trigger.create!(owner_id: 1) }

  let!(:pipeline1) { ci_pipeline.create!(partition_id: 100, project_id: 1) }

  context 'when one pipeline has one ci_trigger_requests' do
    let!(:trigger2) { ci_trigger.create!(owner_id: 1) }
    let!(:trigger3) { ci_trigger.create!(owner_id: 1) }

    let!(:pipeline2) { ci_pipeline.create!(partition_id: 100, project_id: 1) }

    before do
      ci_trigger_request.create!(commit_id: pipeline1.id, trigger_id: trigger1.id, variables: { ENV1: true })
      ci_trigger_request.create!(commit_id: pipeline2.id, trigger_id: trigger2.id, variables: { ENV2: false })
      ci_trigger_request.create!(commit_id: nil, trigger_id: trigger3.id)
    end

    it 'upserts p_ci_pipeline_variables' do
      expect { migration.perform }
        .to change { ci_pipeline_variable.count }.from(0).to(2)
      expect(ci_pipeline_variable.first).to have_attributes(
        pipeline_id: pipeline1.id,
        partition_id: pipeline1.partition_id,
        key: 'ENV1',
        value: 'true',
        encrypted_value: an_instance_of(String),
        encrypted_value_salt: an_instance_of(String),
        encrypted_value_iv: an_instance_of(String),
        variable_type: 'env_var',
        raw: false
      )
      expect(ci_pipeline_variable.last).to have_attributes(
        pipeline_id: pipeline2.id,
        partition_id: pipeline2.partition_id,
        key: 'ENV2',
        value: 'false',
        encrypted_value: an_instance_of(String),
        encrypted_value_salt: an_instance_of(String),
        encrypted_value_iv: an_instance_of(String),
        variable_type: 'env_var',
        raw: false
      )
    end
  end

  context 'when one pipeline has multiple ci_trigger_requests' do
    before do
      ci_trigger_request.create!(commit_id: pipeline1.id, trigger_id: trigger1.id,
        variables: { ENV1: true, VAR1_ONLY: true })
      ci_trigger_request.create!(commit_id: pipeline1.id, trigger_id: trigger1.id,
        variables: { ENV1: false, VAR2_ONLY: false })
    end

    it 'upserts p_ci_pipeline_variables' do
      expect { migration.perform }
        .to change { ci_pipeline_variable.count }.from(0).to(3)
      expect(ci_pipeline_variable.first).to have_attributes(
        pipeline_id: pipeline1.id,
        partition_id: pipeline1.partition_id,
        key: 'ENV1',
        value: 'true',
        encrypted_value: an_instance_of(String),
        encrypted_value_salt: an_instance_of(String),
        encrypted_value_iv: an_instance_of(String),
        variable_type: 'env_var',
        raw: false
      )
      expect(ci_pipeline_variable.second).to have_attributes(
        pipeline_id: pipeline1.id,
        partition_id: pipeline1.partition_id,
        key: 'VAR1_ONLY',
        value: 'true',
        encrypted_value: an_instance_of(String),
        encrypted_value_salt: an_instance_of(String),
        encrypted_value_iv: an_instance_of(String),
        variable_type: 'env_var',
        raw: false
      )
      expect(ci_pipeline_variable.last).to have_attributes(
        pipeline_id: pipeline1.id,
        partition_id: pipeline1.partition_id,
        key: 'VAR2_ONLY',
        value: 'false',
        encrypted_value: an_instance_of(String),
        encrypted_value_salt: an_instance_of(String),
        encrypted_value_iv: an_instance_of(String),
        variable_type: 'env_var',
        raw: false
      )
    end
  end
end
