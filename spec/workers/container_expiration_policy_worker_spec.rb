# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerExpirationPolicyWorker, feature_category: :container_registry do
  include ExclusiveLeaseHelpers

  let(:worker) { described_class.new }
  let(:started_at) { nil }

  describe '#perform' do
    subject { worker.perform }

    context 'process cleanups' do
      it 'calls the limited capacity worker' do
        expect(ContainerExpirationPolicies::CleanupContainerRepositoryWorker).to receive(:perform_with_capacity)

        subject
      end

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

    context 'process stale ongoing cleanups' do
      let_it_be(:stuck_cleanup1) { create(:container_repository, :cleanup_ongoing, expiration_policy_started_at: 1.day.ago) }
      let_it_be(:stuck_cleanup2) { create(:container_repository, :cleanup_ongoing, expiration_policy_started_at: nil) }
      let_it_be(:container_repository1) { create(:container_repository, :cleanup_scheduled) }
      let_it_be(:container_repository2) { create(:container_repository, :cleanup_unfinished) }

      it 'set them as unfinished' do
        expect { subject }
          .to change { ContainerRepository.cleanup_ongoing.count }.from(2).to(0)
          .and change { ContainerRepository.cleanup_unfinished.count }.from(1).to(3)
        expect(stuck_cleanup1.reload).to be_cleanup_unfinished
        expect(stuck_cleanup2.reload).to be_cleanup_unfinished
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
        it 'reads the counts from the replica' do
          expect(Gitlab::Database::LoadBalancing::SessionMap.current(ContainerRepository.load_balancer))
            .to receive(:use_replicas_for_read_queries).and_call_original

          subject
        end
      end
    end
  end
end
