# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PlayBridgeService, '#execute', feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:downstream_project) { create(:project) }
  let_it_be(:user) { create(:user, maintainer_of: [project, downstream_project]) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let(:bridge) { create(:ci_bridge, :playable, pipeline: pipeline, downstream: downstream_project) }
  let(:instance) { described_class.new(project, user) }

  subject(:execute_service) { instance.execute(bridge) }

  context 'when user can run the bridge' do
    it 'marks the bridge pending' do
      execute_service

      expect(bridge.reload).to be_pending
    end

    it "updates bridge's user" do
      execute_service

      expect(bridge.reload.user).to eq(user)
    end

    it 'enqueues Ci::CreateDownstreamPipelineWorker' do
      expect(::Ci::CreateDownstreamPipelineWorker).to receive(:perform_async).with(bridge.id)

      execute_service
    end

    context 'when a subsequent job is skipped' do
      let!(:job) { create(:ci_build, :skipped, pipeline: pipeline, stage_idx: bridge.stage_idx + 1) }

      before do
        create(:ci_build_need, build: job, name: bridge.name)
      end

      it 'marks the subsequent job as processable' do
        expect { execute_service }.to change { job.reload.status }.from('skipped').to('created')
      end
    end

    context 'when bridge is not playable' do
      let(:bridge) { create(:ci_bridge, :failed, pipeline: pipeline, downstream: downstream_project) }

      it 'raises StateMachines::InvalidTransition' do
        expect { execute_service }.to raise_error StateMachines::InvalidTransition
      end
    end
  end

  context 'when user can not run the bridge' do
    let_it_be(:user) { create(:user, developer_of: project) }

    it 'allows user with developer role to play a bridge' do
      expect { execute_service }.to raise_error Gitlab::Access::AccessDeniedError
    end
  end
end
