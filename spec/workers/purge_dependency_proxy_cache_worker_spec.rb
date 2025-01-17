# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PurgeDependencyProxyCacheWorker, type: :worker, feature_category: :virtual_registry do
  let_it_be(:user) { create(:admin) }
  let_it_be_with_refind(:blob) { create(:dependency_proxy_blob) }
  let_it_be_with_reload(:group) { blob.group }
  let_it_be_with_refind(:manifest) { create(:dependency_proxy_manifest, group: group) }
  let_it_be(:group_id) { group.id }

  subject { described_class.new.perform(user.id, group_id) }

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :delayed

  it 'has :until_executing deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executing)
  end

  describe '#perform' do
    shared_examples 'not expiring blobs and manifests' do
      it 'does not expire blobs and manifests', :aggregate_failures do
        expect { subject }.not_to change { blob.status }
        expect { subject }.not_to change { manifest.status }
        expect(subject).to be_nil
      end
    end

    context 'an admin user' do
      context 'when admin mode is enabled', :enable_admin_mode do
        it_behaves_like 'an idempotent worker' do
          let(:job_args) { [user.id, group_id] }

          it 'marks the blobs as pending_destruction and returns ok', :aggregate_failures do
            subject

            expect(blob).to be_pending_destruction
            expect(manifest).to be_pending_destruction
          end
        end
      end

      context 'when admin mode is disabled' do
        it_behaves_like 'not expiring blobs and manifests'
      end
    end

    context 'a non-admin user' do
      let(:user) { create(:user) }

      it_behaves_like 'not expiring blobs and manifests'
    end

    context 'an invalid user id' do
      let(:user) { double('User', id: 99999) }

      it_behaves_like 'not expiring blobs and manifests'
    end

    context 'an invalid group' do
      let(:group_id) { 99999 }

      it_behaves_like 'not expiring blobs and manifests'
    end
  end
end
