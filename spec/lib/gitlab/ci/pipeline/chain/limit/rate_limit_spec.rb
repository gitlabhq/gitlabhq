# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::Pipeline::Chain::Limit::RateLimit, :freeze_time, :clean_gitlab_redis_rate_limiting, feature_category: :ci_pipeline do
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
      save_incompleted: save_incompleted,
      origin_ref: project.default_branch_or_main
    )
  end

  let(:pipeline) { build(:ci_pipeline, project: project, source: source) }
  let(:source) { 'push' }
  let(:step) { described_class.new(pipeline, command) }

  def exceed_rate_limit
    2.times { step.perform! }
  end

  shared_context 'with duo_workflow pipeline' do |workflow_def:|
    let(:source) { 'duo_workflow' }

    before do
      command.duo_workflow_definition = workflow_def
    end
  end

  shared_examples 'excluded from rate limits' do
    it 'does not break the chain' do
      exceed_rate_limit

      expect(step.break?).to be_falsey
    end

    it 'does not invalidate the pipeline' do
      exceed_rate_limit

      expect(pipeline.errors).to be_empty
    end

    it 'does not log anything' do
      expect(Gitlab::AppJsonLogger).not_to receive(:info)

      exceed_rate_limit
    end
  end

  shared_examples 'not excluded from rate limits' do
    it 'still enforces rate limits' do
      exceed_rate_limit

      expect(pipeline.errors).not_to be_empty
    end
  end

  shared_examples 'exceeded rate limit' do
    it 'does not persist the pipeline' do
      exceed_rate_limit

      expect(pipeline).not_to be_persisted
      expect(pipeline.errors.added?(:base, throttle_message)).to be_truthy
    end

    it 'breaks the chain' do
      exceed_rate_limit

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
          throttle_override: false,
          message: message
        )
      )

      exceed_rate_limit
    end

    context 'with child pipelines' do
      let(:source) { 'parent_pipeline' }

      it_behaves_like 'excluded from rate limits'
    end

    context 'with creating_policy_pipeline? is true', feature_category: :security_policy_management do
      before do
        allow(command).to receive_message_chain(:pipeline_policy_context, :pipeline_execution_context,
          :creating_policy_pipeline?).and_return(true)
      end

      it_behaves_like 'excluded from rate limits'
    end

    context 'with SAST FP detection duo_workflow pipelines' do
      include_context 'with duo_workflow pipeline', workflow_def: 'sast_fp_detection/v1'

      it_behaves_like 'excluded from rate limits'
    end

    context 'with resolve SAST vulnerability duo_workflow pipelines' do
      include_context 'with duo_workflow pipeline', workflow_def: 'resolve_sast_vulnerability/v1'

      it_behaves_like 'excluded from rate limits'
    end

    context 'with non-excluded duo_workflow pipelines' do
      include_context 'with duo_workflow pipeline', workflow_def: 'other_workflow/v1'

      it_behaves_like 'not excluded from rate limits'
    end

    context 'with duo_workflow pipelines when workflow definition is nil' do
      let(:source) { 'duo_workflow' }

      it_behaves_like 'not excluded from rate limits'
    end

    context 'when saving incomplete pipelines' do
      let(:save_incompleted) { true }

      it 'does not persist the pipeline' do
        exceed_rate_limit

        expect(pipeline).not_to be_persisted
        expect(pipeline.errors.added?(:base, throttle_message)).to be_truthy
      end

      it 'breaks the chain' do
        exceed_rate_limit

        expect(step.break?).to be_truthy
      end
    end

    context 'when ci_enforce_throttle_pipelines_creation_override is enabled' do
      before do
        stub_feature_flags(ci_enforce_throttle_pipelines_creation_override: true)
      end

      it 'does not break the chain' do
        exceed_rate_limit

        expect(step.break?).to be_falsey
      end

      it 'does not invalidate the pipeline' do
        exceed_rate_limit

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

        exceed_rate_limit
      end
    end
  end

  context 'when pipeline_limit_per_project_user_sha is exceeded' do
    before do
      stub_application_setting(pipeline_limit_per_project_user_sha: 1)
      stub_feature_flags(ci_enforce_throttle_pipelines_creation_override: false)
    end

    it_behaves_like 'exceeded rate limit' do
      let(:message) do
        'Pipeline rate limit exceeded for pipelines_create'
      end
    end
  end

  context 'when pipelines_created_per_user is exceeded' do
    before do
      stub_application_setting(pipeline_limit_per_user: 1)
      stub_feature_flags(ci_enforce_throttle_pipelines_creation_override: false)
    end

    it_behaves_like 'exceeded rate limit' do
      let(:message) do
        'Pipeline rate limit exceeded for pipelines_created_per_user'
      end
    end
  end

  context 'when pipelines_created_per_user and pipelines_create are exceeded' do
    before do
      stub_application_setting(pipeline_limit_per_user: 1)
      stub_application_setting(pipeline_limit_per_project_user_sha: 1)
      stub_feature_flags(ci_enforce_throttle_pipelines_creation_override: false)
    end

    it_behaves_like 'exceeded rate limit' do
      let(:message) do
        'Pipeline rate limit exceeded for pipelines_create and pipelines_created_per_user'
      end
    end
  end

  context 'when the limit is not exceeded' do
    it 'does not break the chain' do
      exceed_rate_limit

      expect(step.break?).to be_falsey
    end

    it 'does not invalidate the pipeline' do
      exceed_rate_limit

      expect(pipeline.errors).to be_empty
    end

    it 'does not log anything' do
      expect(Gitlab::AppJsonLogger).not_to receive(:info)

      exceed_rate_limit
    end
  end
end
