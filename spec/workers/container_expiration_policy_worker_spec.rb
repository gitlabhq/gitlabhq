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
      let_it_be(:container_repository1) { create(:container_repository, :cleanup_scheduled) }
      let_it_be(:container_repository2) { create(:container_repository, :cleanup_unfinished) }

      it 'set them as unfinished' do
        expect { subject }
          .to change { ContainerRepository.cleanup_ongoing.count }.from(1).to(0)
          .and change { ContainerRepository.cleanup_unfinished.count }.from(1).to(2)
        expect(stuck_cleanup.reload).to be_cleanup_unfinished
      end
    end

    context 'policies without container repositories' do
      let_it_be(:container_expiration_policy1) { create(:container_expiration_policy, enabled: true) }
      let_it_be(:container_repository1) { create(:container_repository, project_id: container_expiration_policy1.project_id) }
      let_it_be(:container_expiration_policy2) { create(:container_expiration_policy, enabled: true) }
      let_it_be(:container_repository2) { create(:container_repository, project_id: container_expiration_policy2.project_id) }
      let_it_be(:container_expiration_policy3) { create(:container_expiration_policy, enabled: true) }

      it 'disables them' do
        expect { subject }
          .to change { ::ContainerExpirationPolicy.active.count }.from(3).to(2)
        expect(container_expiration_policy3.reload.enabled).to be false
      end
    end

    context 'counts logging' do
      let_it_be(:container_repository1) { create(:container_repository, :cleanup_scheduled) }
      let_it_be(:container_repository2) { create(:container_repository, :cleanup_unfinished) }
      let_it_be(:container_repository3) { create(:container_repository, :cleanup_unfinished) }

      before do
        ContainerExpirationPolicy.update_all(enabled: true)
        container_repository1.project.container_expiration_policy.update_column(:next_run_at, 5.minutes.ago)
      end

      it 'logs all the counts' do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:cleanup_required_count, 1)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:cleanup_unfinished_count, 2)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:cleanup_total_count, 3)

        subject
      end

      context 'with load balancing enabled' do
        before do
          allow(Gitlab::Database::LoadBalancing).to receive(:enable?).and_return(true)
        end

        it 'reads the counts from the replica' do
          expect(Gitlab::Database::LoadBalancing::Session.current).to receive(:use_replicas_for_read_queries).and_call_original

          subject
        end
      end
    end
  end
end
