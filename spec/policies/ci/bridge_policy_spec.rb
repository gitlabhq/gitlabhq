# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BridgePolicy, feature_category: :continuous_integration do
  let_it_be(:user, reload: true) { create(:user) }
  let_it_be(:project, reload: true) { create(:project) }
  let_it_be(:downstream_project, reload: true) { create(:project, :repository) }
  let_it_be(:pipeline, reload: true) { create(:ci_empty_pipeline, project: project) }
  let_it_be(:bridge, refind: true) { create(:ci_bridge, pipeline: pipeline, downstream: downstream_project) }

  let(:policy) do
    described_class.new(user, bridge)
  end

  it_behaves_like 'a deployable job policy', :ci_bridge do
    before do
      downstream_project.add_maintainer(user)
      allow(job).to receive(:downstream_project).at_least(:once).and_return(downstream_project)
    end
  end

  describe '#play_job' do
    context 'when downstream project exists' do
      before do
        project.add_developer(user) if can_update_job
        fake_access = double('Gitlab::UserAccess')
        allow(fake_access).to receive(:can_update_branch?).with('master').and_return(can_update_branch)
        allow(Gitlab::UserAccess).to receive(:new).with(user, container: downstream_project).and_return(fake_access)
      end

      context 'when user can update the job and the downstream branch' do
        let(:can_update_branch) { true }
        let(:can_update_job) { true }

        it 'allows' do
          expect(policy).to be_allowed :play_job
        end

        describe 'rules for archived jobs' do
          # :erase_build is not applicable to Ci::Bridge and :update_build is not used in Ci::Bridge
          let(:cleanup_permissions) { ::ProjectPolicy::CLEANUP_JOB_PERMISSIONS - [:erase_build] }
          let(:update_permissions) { ::ProjectPolicy::UPDATE_JOB_PERMISSIONS - [:update_build] }

          context 'when job is not archived' do
            it 'allows update and cleanup job permissions' do
              update_permissions.each do |perm|
                expect(policy).to be_allowed(perm)
              end

              cleanup_permissions.each do |perm|
                expect(policy).to be_allowed(perm)
              end
            end
          end

          context 'when job is archived' do
            before do
              allow(bridge).to receive(:archived?).and_return(true)
            end

            it 'prevents update job permissions while allowing cleanup job permissions' do
              update_permissions.each do |perm|
                expect(policy).to be_disallowed(perm)
              end

              cleanup_permissions.each do |perm|
                expect(policy).to be_allowed(perm)
              end
            end
          end
        end
      end

      context 'when user can update the downstream branch but not the job' do
        let(:can_update_branch) { true }
        let(:can_update_job) { false }

        it 'does not allow' do
          expect(policy).not_to be_allowed :play_job
        end
      end

      context 'when user can update the job but not the downstream branch' do
        let(:can_update_branch) { false }
        let(:can_update_job) { true }

        it 'does not allow' do
          expect(policy).not_to be_allowed :play_job
        end
      end

      context 'when user can update neither the job nor the downstream branch' do
        let(:can_update_branch) { false }
        let(:can_update_job) { false }

        it 'does not allow' do
          expect(policy).not_to be_allowed :play_job
        end
      end
    end

    context 'when downstream project does not exist' do
      before do
        project.add_developer(user)
        allow(bridge).to receive(:options).and_return({ trigger: { project: 'deleted-project' } })
      end

      it 'does not allow' do
        expect(policy).not_to be_allowed :play_job
      end
    end
  end
end
