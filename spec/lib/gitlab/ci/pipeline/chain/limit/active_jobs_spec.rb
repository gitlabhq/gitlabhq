# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::Pipeline::Chain::Limit::ActiveJobs do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:project) { create(:project, namespace: namespace) }
  let_it_be(:user) { create(:user) }
  let_it_be(:default_plan) { create(:default_plan) }

  let(:command) do
    instance_double(
      ::Gitlab::Ci::Pipeline::Chain::Command,
      project: project,
      current_user: user,
      save_incompleted: true,
      pipeline_seed: pipeline_seed_double
    )
  end

  let(:pipeline_seed_double) do
    instance_double(::Gitlab::Ci::Pipeline::Seed::Pipeline, size: 5)
  end

  let(:pipeline) do
    create(:ci_pipeline, project: project)
  end

  let(:existing_pipeline) { create(:ci_pipeline, project: project) }
  let(:step) { described_class.new(pipeline, command) }
  let(:limit) { 10 }

  subject { step.perform! }

  before do
    create(:plan_limits, plan: default_plan, ci_active_jobs: limit)
    namespace.clear_memoization(:actual_plan)
  end

  shared_examples 'successful step' do
    it 'doest not fail the pipeline and does not interrupt the chain' do
      subject

      expect(pipeline).not_to be_failed
      expect(step).not_to be_break
    end
  end

  context 'when active jobs limit is exceeded' do
    before do
      create_list(:ci_build, 3, pipeline: existing_pipeline)
      create_list(:ci_bridge, 3, pipeline: existing_pipeline)
    end

    it 'fails the pipeline with an error', :aggregate_failures do
      subject

      expect(pipeline).to be_failed
      expect(pipeline).to be_job_activity_limit_exceeded
      expect(pipeline.errors.full_messages).to include(described_class::MESSAGE)
    end

    it 'logs the failure' do
      allow(Gitlab::AppLogger).to receive(:info)

      subject

      expect(Gitlab::AppLogger).to have_received(:info).with(
        class: described_class.name,
        message: described_class::MESSAGE,
        project_id: project.id,
        plan: default_plan.name,
        project_path: project.path,
        jobs_in_alive_pipelines_count: step.send(:count_jobs_in_alive_pipelines)
      )
    end

    it 'breaks the chain' do
      subject

      expect(step).to be_break
    end

    context 'when active jobs limit not enabled' do
      let(:limit) { 0 }

      it_behaves_like 'successful step'
    end
  end

  context 'when active jobs limit is not exceeded' do
    before do
      create_list(:ci_build, 3, pipeline: existing_pipeline)
      create_list(:ci_bridge, 1, pipeline: existing_pipeline)
    end

    it_behaves_like 'successful step'
  end
end
