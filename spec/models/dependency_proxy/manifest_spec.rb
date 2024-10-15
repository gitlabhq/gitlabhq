# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DependencyProxy::Manifest, type: :model, feature_category: :dependency_proxy do
  it_behaves_like 'ttl_expirable'
  it_behaves_like 'destructible', factory: :dependency_proxy_manifest

  it_behaves_like 'updates namespace statistics' do
    let(:statistic_source) { build(:dependency_proxy_manifest, size: 10) }
  end

  describe 'relationships' do
    it { is_expected.to belong_to(:group) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:file) }
    it { is_expected.to validate_presence_of(:file_name) }
    it { is_expected.to validate_presence_of(:digest) }
  end

  describe 'scopes' do
    let_it_be(:manifest_one) { create(:dependency_proxy_manifest) }
    let_it_be(:manifest_two) { create(:dependency_proxy_manifest) }
    let_it_be(:manifests) { [manifest_one, manifest_two] }
    let_it_be(:ids) { manifests.map(&:id) }

    it 'order_id_desc' do
      expect(described_class.where(id: ids).order_id_desc.to_a).to eq [manifest_two, manifest_one]
    end
  end

  describe 'file is being stored' do
    subject { create(:dependency_proxy_manifest) }

    context 'when existing object has local store' do
      it_behaves_like 'mounted file in local store'
    end

    context 'when direct upload is enabled' do
      before do
        stub_dependency_proxy_object_storage(direct_upload: true)
      end

      it_behaves_like 'mounted file in object store'
    end
  end

  describe '.find_by_file_name_or_digest' do
    let_it_be(:file_name) { 'foo' }
    let_it_be(:digest) { 'bar' }

    subject { described_class.find_by_file_name_or_digest(file_name: file_name, digest: digest) }

    context 'no manifest exists' do
      it { is_expected.to be_nil }
    end

    context 'manifest exists and matches file_name' do
      let_it_be(:dependency_proxy_manifest) { create(:dependency_proxy_manifest) }
      let_it_be(:file_name) { dependency_proxy_manifest.file_name }

      it { is_expected.to eq(dependency_proxy_manifest) }
    end

    context 'manifest exists and matches digest' do
      let_it_be(:dependency_proxy_manifest) { create(:dependency_proxy_manifest) }
      let_it_be(:digest) { dependency_proxy_manifest.digest }

      it { is_expected.to eq(dependency_proxy_manifest) }
    end
  end
end
