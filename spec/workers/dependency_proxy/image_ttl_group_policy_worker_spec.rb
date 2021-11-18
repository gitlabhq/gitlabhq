# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DependencyProxy::ImageTtlGroupPolicyWorker do
  let(:worker) { described_class.new }

  describe '#perform' do
    let_it_be(:policy) { create(:image_ttl_group_policy) }
    let_it_be(:group) { policy.group }

    subject { worker.perform }

    context 'when there are images to expire' do
      let_it_be_with_reload(:old_blob) { create(:dependency_proxy_blob, group: group, read_at: 1.year.ago) }
      let_it_be_with_reload(:old_manifest) { create(:dependency_proxy_manifest, group: group, read_at: 1.year.ago) }
      let_it_be_with_reload(:new_blob) { create(:dependency_proxy_blob, group: group) }
      let_it_be_with_reload(:new_manifest) { create(:dependency_proxy_manifest, group: group) }

      it 'calls the limited capacity workers', :aggregate_failures do
        expect(DependencyProxy::CleanupBlobWorker).to receive(:perform_with_capacity)
        expect(DependencyProxy::CleanupManifestWorker).to receive(:perform_with_capacity)

        subject
      end

      it 'updates the old images to expired' do
        expect { subject }
          .to change { old_blob.reload.status }.from('default').to('expired')
          .and change { old_manifest.reload.status }.from('default').to('expired')
          .and not_change { new_blob.reload.status }
          .and not_change { new_manifest.reload.status }
      end
    end

    context 'when there are no images to expire' do
      it 'does not do anything', :aggregate_failures do
        expect(DependencyProxy::CleanupBlobWorker).not_to receive(:perform_with_capacity)
        expect(DependencyProxy::CleanupManifestWorker).not_to receive(:perform_with_capacity)

        subject
      end
    end

    context 'counts logging' do
      let_it_be(:expired_blob) { create(:dependency_proxy_blob, :expired, group: group) }
      let_it_be(:expired_blob2) { create(:dependency_proxy_blob, :expired, group: group) }
      let_it_be(:expired_manifest) { create(:dependency_proxy_manifest, :expired, group: group) }
      let_it_be(:processing_blob) { create(:dependency_proxy_blob, status: :processing, group: group) }
      let_it_be(:processing_manifest) { create(:dependency_proxy_manifest, status: :processing, group: group) }
      let_it_be(:error_blob) { create(:dependency_proxy_blob, status: :error, group: group) }
      let_it_be(:error_manifest) { create(:dependency_proxy_manifest, status: :error, group: group) }

      it 'logs all the counts', :aggregate_failures do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:expired_dependency_proxy_blob_count, 2)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:expired_dependency_proxy_manifest_count, 1)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:processing_dependency_proxy_blob_count, 1)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:processing_dependency_proxy_manifest_count, 1)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:error_dependency_proxy_blob_count, 1)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:error_dependency_proxy_manifest_count, 1)

        subject
      end

      context 'with load balancing enabled', :db_load_balancing do
        it 'reads the counts from the replica' do
          expect(Gitlab::Database::LoadBalancing::Session.current).to receive(:use_replicas_for_read_queries).and_call_original

          subject
        end
      end
    end
  end
end
