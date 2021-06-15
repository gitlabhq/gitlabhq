# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerExpirationPolicyWorker do
  include ExclusiveLeaseHelpers

  let(:worker) { described_class.new }
  let(:started_at) { nil }

  describe '#perform' do
    subject { worker.perform }

    shared_examples 'not executing any policy' do
      it 'does not run any policy' do
        expect(ContainerExpirationPolicyService).not_to receive(:new)

        subject
      end
    end

    shared_examples 'handling a taken exclusive lease' do
      context 'with exclusive lease taken' do
        before do
          stub_exclusive_lease_taken(worker.lease_key, timeout: 5.hours)
        end

        it 'does not do anything' do
          expect(ContainerExpirationPolicies::CleanupContainerRepositoryWorker).not_to receive(:perform_with_capacity)
          expect(worker).not_to receive(:runnable_policies)

          expect { subject }.not_to change { ContainerRepository.cleanup_scheduled.count }
        end
      end
    end

    context 'with throttling enabled' do
      before do
        stub_feature_flags(container_registry_expiration_policies_throttling: true)
      end

      it 'calls the limited capacity worker' do
        expect(ContainerExpirationPolicies::CleanupContainerRepositoryWorker).to receive(:perform_with_capacity)

        subject
      end

      it_behaves_like 'handling a taken exclusive lease'
    end

    context 'with throttling disabled' do
      before do
        stub_feature_flags(container_registry_expiration_policies_throttling: false)
      end

      context 'with no container expiration policies' do
        it_behaves_like 'not executing any policy'
      end

      context 'with container expiration policies' do
        let_it_be(:container_expiration_policy, reload: true) { create(:container_expiration_policy, :runnable) }
        let_it_be(:container_repository) { create(:container_repository, project: container_expiration_policy.project) }
        let_it_be(:user) { container_expiration_policy.project.owner }

        context 'a valid policy' do
          it 'runs the policy' do
            expect(ContainerExpirationPolicyService)
              .to receive(:new).with(container_expiration_policy.project, user).and_call_original
            expect(CleanupContainerRepositoryWorker).to receive(:perform_async).once.and_call_original

            expect { subject }.not_to raise_error
          end
        end

        context 'a disabled policy' do
          before do
            container_expiration_policy.disable!
          end

          it_behaves_like 'not executing any policy'
        end

        context 'a policy that is not due for a run' do
          before do
            container_expiration_policy.update_column(:next_run_at, 2.minutes.from_now)
          end

          it_behaves_like 'not executing any policy'
        end

        context 'a policy linked to no container repository' do
          before do
            container_expiration_policy.container_repositories.delete_all
          end

          it_behaves_like 'not executing any policy'
        end

        context 'an invalid policy' do
          before do
            container_expiration_policy.update_column(:name_regex, '*production')
          end

          it 'disables the policy and tracks an error' do
            expect(ContainerExpirationPolicyService).not_to receive(:new).with(container_expiration_policy, user)
            expect(Gitlab::ErrorTracking).to receive(:log_exception).with(instance_of(described_class::InvalidPolicyError), container_expiration_policy_id: container_expiration_policy.id)

            expect { subject }.to change { container_expiration_policy.reload.enabled }.from(true).to(false)
          end
        end
      end
    end

    context 'process stale ongoing cleanups' do
      let_it_be(:stuck_cleanup) { create(:container_repository, :cleanup_ongoing, expiration_policy_started_at: 1.day.ago) }
      let_it_be(:container_repository) { create(:container_repository, :cleanup_scheduled) }
      let_it_be(:container_repository) { create(:container_repository, :cleanup_unfinished) }

      it 'set them as unfinished' do
        expect { subject }
          .to change { ContainerRepository.cleanup_ongoing.count }.from(1).to(0)
          .and change { ContainerRepository.cleanup_unfinished.count }.from(1).to(2)
        expect(stuck_cleanup.reload).to be_cleanup_unfinished
      end
    end
  end
end
