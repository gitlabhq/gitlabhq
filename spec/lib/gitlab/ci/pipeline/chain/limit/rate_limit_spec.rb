# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::Pipeline::Chain::Limit::RateLimit, :freeze_time, :clean_gitlab_redis_rate_limiting do
  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:namespace) }
  let_it_be(:project, reload: true) { create(:project, namespace: namespace) }

  let(:save_incompleted) { false }
  let(:throttle_message) do
    'Too many pipelines created in the last minute. Try again later.'
  end

  let(:command) do
    Gitlab::Ci::Pipeline::Chain::Command.new(
      project: project,
      current_user: user,
      save_incompleted: save_incompleted
    )
  end

  let(:pipeline) { build(:ci_pipeline, project: project, source: source) }
  let(:source) { 'push' }
  let(:step) { described_class.new(pipeline, command) }

  def perform(count: 2)
    count.times { step.perform! }
  end

  context 'when the limit is exceeded' do
    before do
      stub_application_setting(pipeline_limit_per_project_user_sha: 1)
      stub_feature_flags(ci_enforce_throttle_pipelines_creation_override: false)
    end

    it 'does not persist the pipeline' do
      perform

      expect(pipeline).not_to be_persisted
      expect(pipeline.errors.added?(:base, throttle_message)).to be_truthy
    end

    it 'breaks the chain' do
      perform

      expect(step.break?).to be_truthy
    end

    it 'creates a log entry' do
      expect(Gitlab::AppJsonLogger).to receive(:info).with(
        a_hash_including(
          class: described_class.name,
          project_id: project.id,
          subscription_plan: project.actual_plan_name,
          commit_sha: command.sha,
          throttled: true,
          throttle_override: false
        )
      )

      perform
    end

    shared_examples_for 'excluded from rate limits' do
      it 'does not break the chain' do
        perform

        expect(step.break?).to be_falsey
      end

      it 'does not invalidate the pipeline' do
        perform

        expect(pipeline.errors).to be_empty
      end

      it 'does not log anything' do
        expect(Gitlab::AppJsonLogger).not_to receive(:info)

        perform
      end
    end

    context 'with child pipelines' do
      let(:source) { 'parent_pipeline' }

      it_behaves_like 'excluded from rate limits'
    end

    context 'with creating_policy_pipeline? is true', feature_category: :security_policy_management do
      before do
        allow(command).to receive_message_chain(:pipeline_policy_context, :creating_policy_pipeline?).and_return(true)
      end

      it_behaves_like 'excluded from rate limits'
    end

    context 'when saving incompleted pipelines' do
      let(:save_incompleted) { true }

      it 'does not persist the pipeline' do
        perform

        expect(pipeline).not_to be_persisted
        expect(pipeline.errors.added?(:base, throttle_message)).to be_truthy
      end

      it 'breaks the chain' do
        perform

        expect(step.break?).to be_truthy
      end
    end

    context 'when ci_enforce_throttle_pipelines_creation is disabled' do
      before do
        stub_feature_flags(ci_enforce_throttle_pipelines_creation: false)
      end

      it 'does not break the chain' do
        perform

        expect(step.break?).to be_falsey
      end

      it 'does not invalidate the pipeline' do
        perform

        expect(pipeline.errors).to be_empty
      end

      it 'creates a log entry' do
        expect(Gitlab::AppJsonLogger).to receive(:info).with(
          a_hash_including(
            class: described_class.name,
            project_id: project.id,
            subscription_plan: project.actual_plan_name,
            commit_sha: command.sha,
            throttled: false,
            throttle_override: false
          )
        )

        perform
      end
    end

    context 'when ci_enforce_throttle_pipelines_creation_override is enabled' do
      before do
        stub_feature_flags(ci_enforce_throttle_pipelines_creation_override: true)
      end

      it 'does not break the chain' do
        perform

        expect(step.break?).to be_falsey
      end

      it 'does not invalidate the pipeline' do
        perform

        expect(pipeline.errors).to be_empty
      end

      it 'creates a log entry' do
        expect(Gitlab::AppJsonLogger).to receive(:info).with(
          a_hash_including(
            class: described_class.name,
            project_id: project.id,
            subscription_plan: project.actual_plan_name,
            commit_sha: command.sha,
            throttled: false,
            throttle_override: true
          )
        )

        perform
      end
    end
  end

  context 'when the limit is not exceeded' do
    it 'does not break the chain' do
      perform

      expect(step.break?).to be_falsey
    end

    it 'does not invalidate the pipeline' do
      perform

      expect(pipeline.errors).to be_empty
    end

    it 'does not log anything' do
      expect(Gitlab::AppJsonLogger).not_to receive(:info)

      perform
    end
  end
end
