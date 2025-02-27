# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PlayBridgeService, '#execute', feature_category: :continuous_integration do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:downstream_project) { create(:project) }
  let(:bridge) { create(:ci_bridge, :playable, pipeline: pipeline, downstream: downstream_project) }
  let(:instance) { described_class.new(project, user) }

  subject(:execute_service) { instance.execute(bridge) }

  context 'when user can run the bridge' do
    before do
      allow(instance).to receive(:can?).with(user, :play_job, bridge).and_return(true)
    end

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
    before do
      allow(instance).to receive(:can?).with(user, :play_job, bridge).and_return(false)
    end

    it 'allows user with developer role to play a bridge' do
      expect { execute_service }.to raise_error Gitlab::Access::AccessDeniedError
    end
  end
end
