# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BridgePolicy do
  let_it_be(:user, reload: true) { create(:user) }
  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:downstream_project, reload: true) { create(:project, :repository) }
  let_it_be(:pipeline, reload: true) { create(:ci_empty_pipeline, project: project) }
  let_it_be(:bridge, reload: true) { create(:ci_bridge, pipeline: pipeline, downstream: downstream_project) }

  let(:policy) do
    described_class.new(user, bridge)
  end

  it_behaves_like 'a deployable job policy', :ci_bridge

  describe '#play_job' do
    context 'when downstream project exists' do
      before do
        fake_access = double('Gitlab::UserAccess')
        expect(fake_access).to receive(:can_update_branch?).with('master').and_return(can_update_branch)
        expect(Gitlab::UserAccess).to receive(:new).with(user, container: downstream_project).and_return(fake_access)
      end

      context 'when user can update the downstream branch' do
        let(:can_update_branch) { true }

        it 'allows' do
          expect(policy).to be_allowed :play_job
        end
      end

      context 'when user can not update the downstream branch' do
        let(:can_update_branch) { false }

        it 'does not allow' do
          expect(policy).not_to be_allowed :play_job
        end
      end
    end

    context 'when downstream project does not exist' do
      before do
        bridge.update!(options: { trigger: { project: 'deleted-project' } })
      end

      it 'does not allow' do
        expect(policy).not_to be_allowed :play_job
      end
    end
  end
end
