# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PurgeDependencyProxyCacheWorker do
  let_it_be(:user) { create(:admin) }
  let_it_be(:blob) { create(:dependency_proxy_blob )}
  let_it_be(:group, reload: true) { blob.group }
  let_it_be(:manifest) { create(:dependency_proxy_manifest, group: group )}
  let_it_be(:group_id) { group.id }

  subject { described_class.new.perform(user.id, group_id) }

  before do
    stub_config(dependency_proxy: { enabled: true })
    group.create_dependency_proxy_setting!(enabled: true)
  end

  describe '#perform' do
    shared_examples 'returns nil' do
      it 'returns nil', :aggregate_failures do
        expect { subject }.not_to change { group.dependency_proxy_blobs.size }
        expect { subject }.not_to change { group.dependency_proxy_manifests.size }
        expect(subject).to be_nil
      end
    end

    context 'an admin user' do
      context 'when admin mode is enabled', :enable_admin_mode do
        include_examples 'an idempotent worker' do
          let(:job_args) { [user.id, group_id] }

          it 'deletes the blobs and returns ok', :aggregate_failures do
            expect(group.dependency_proxy_blobs.size).to eq(1)
            expect(group.dependency_proxy_manifests.size).to eq(1)

            subject

            expect(group.dependency_proxy_blobs.size).to eq(0)
            expect(group.dependency_proxy_manifests.size).to eq(0)
          end
        end
      end

      context 'when admin mode is disabled' do
        it_behaves_like 'returns nil'
      end
    end

    context 'a non-admin user' do
      let(:user) { create(:user) }

      it_behaves_like 'returns nil'
    end

    context 'an invalid user id' do
      let(:user) { double('User', id: 99999 ) }

      it_behaves_like 'returns nil'
    end

    context 'an invalid group' do
      let(:group_id) { 99999 }

      it_behaves_like 'returns nil'
    end
  end
end
