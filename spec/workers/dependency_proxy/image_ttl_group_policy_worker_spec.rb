# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DependencyProxy::ImageTtlGroupPolicyWorker, type: :worker, feature_category: :virtual_registry do
  let(:worker) { described_class.new }

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :sticky

  it 'has :until_executing deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executing)
  end

  describe '#perform' do
    let_it_be(:policy) { create(:image_ttl_group_policy) }
    let_it_be(:group) { policy.group }

    subject { worker.perform }

    context 'when there are images to expire' do
      let_it_be_with_reload(:old_blob) { create(:dependency_proxy_blob, group: group, read_at: 1.year.ago) }
      let_it_be_with_reload(:old_manifest) { create(:dependency_proxy_manifest, group: group, read_at: 1.year.ago) }
      let_it_be_with_reload(:new_blob) { create(:dependency_proxy_blob, group: group) }
      let_it_be_with_reload(:new_manifest) { create(:dependency_proxy_manifest, group: group) }

      it 'updates the old images to pending_destruction' do
        expect { subject }
          .to change { old_blob.reload.status }.from('default').to('pending_destruction')
          .and change { old_manifest.reload.status }.from('default').to('pending_destruction')
          .and not_change { new_blob.reload.status }
          .and not_change { new_manifest.reload.status }
      end
    end

    context 'counts logging' do
      let_it_be(:expired_blob) { create(:dependency_proxy_blob, :pending_destruction, group: group) }
      let_it_be(:expired_blob2) { create(:dependency_proxy_blob, :pending_destruction, group: group) }
      let_it_be(:expired_manifest) { create(:dependency_proxy_manifest, :pending_destruction, group: group) }
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
    end
  end
end
