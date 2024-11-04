# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::Pipeline::Chain::Limit::Size, feature_category: :pipeline_composition do
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:project, reload: true) { create(:project, :repository, namespace: namespace) }
  let_it_be(:default_plan) { create(:default_plan) }
  let_it_be(:user) { create(:user) }

  let(:pipeline) { build(:ci_pipeline, project: project) }

  let(:command) do
    instance_double(::Gitlab::Ci::Pipeline::Chain::Command,
      project: project,
      current_user: user,
      pipeline_seed: instance_double(::Gitlab::Ci::Pipeline::Seed::Pipeline, size: 1))
  end

  let(:step) { described_class.new(pipeline, command) }

  subject(:perform_step) { step.perform! }

  context 'when pipeline size limit is exceeded' do
    before do
      create(:plan_limits, plan: default_plan, ci_pipeline_size: 1)
    end

    context 'when saving incomplete pipelines' do
      let(:command) do
        instance_double(::Gitlab::Ci::Pipeline::Chain::Command,
          project: project,
          current_user: user,
          save_incompleted: true,
          pipeline_seed: instance_double(::Gitlab::Ci::Pipeline::Seed::Pipeline, size: 2))
      end

      it 'drops the pipeline' do
        perform_step

        expect(pipeline.reload).to be_failed
      end

      it 'persists the pipeline' do
        perform_step

        expect(pipeline).to be_persisted
      end

      it 'breaks the chain' do
        perform_step

        expect(step.break?).to be true
      end

      it 'sets a valid failure reason' do
        perform_step

        expect(pipeline.size_limit_exceeded?).to be true
      end

      it 'appends validation error' do
        perform_step

        expect(pipeline.errors.to_a)
          .to include "The number of jobs has exceeded the limit of 1. " \
            "Try splitting the configuration with parent-child-pipelines " \
            "http://localhost/help/ci/debugging.md#pipeline-with-many-jobs-fails-to-start"
      end

      it 'logs the error' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
          instance_of(Gitlab::Ci::Limit::LimitExceededError),
          {
            jobs_count: pipeline.statuses.count,
            project_id: project.id, plan: namespace.actual_plan_name,
            project_full_path: project.full_path, pipeline_source: pipeline.source
          }
        )

        perform_step
      end
    end

    context 'when not saving incomplete pipelines' do
      let(:command) do
        instance_double(::Gitlab::Ci::Pipeline::Chain::Command,
          project: project,
          current_user: user,
          save_incompleted: false,
          pipeline_seed: instance_double(::Gitlab::Ci::Pipeline::Seed::Pipeline, size: 2),
          increment_pipeline_failure_reason_counter: true)
      end

      it 'fails but does not persist the pipeline' do
        perform_step

        expect(pipeline).not_to be_persisted
        expect(pipeline).to be_size_limit_exceeded
        expect(pipeline).to be_failed
      end

      it 'breaks the chain' do
        perform_step

        expect(step.break?).to be true
      end

      it 'increments the error metric' do
        expect(command).to receive(:increment_pipeline_failure_reason_counter).with(:size_limit_exceeded)

        perform_step
      end
    end
  end

  context 'when pipeline size limit is not exceeded' do
    before do
      create(:plan_limits, plan: default_plan, ci_pipeline_size: 100)
    end

    it 'does not break the chain' do
      perform_step

      expect(step.break?).to be false
    end

    it 'does not persist the pipeline' do
      perform_step

      expect(pipeline).not_to be_persisted
    end

    it 'does not log any error' do
      expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

      perform_step
    end
  end

  context 'when pipeline size limit is disabled' do
    before do
      create(:plan_limits, plan: default_plan, ci_pipeline_size: 0)
    end

    context 'when global pipeline size limit is exceeded' do
      let(:command) do
        instance_double(::Gitlab::Ci::Pipeline::Chain::Command,
          project: project,
          current_user: user,
          pipeline_seed: instance_double(::Gitlab::Ci::Pipeline::Seed::Pipeline, size: 2001))
      end

      it 'logs the pipeline' do
        expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
          instance_of(Gitlab::Ci::Limit::LimitExceededError),
          {
            jobs_count: pipeline.statuses.count,
            project_id: project.id, plan: namespace.actual_plan_name,
            project_full_path: project.full_path, pipeline_source: pipeline.source
          }
        )

        perform_step
      end
    end
  end
end
