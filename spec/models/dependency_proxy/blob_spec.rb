# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DependencyProxy::Blob, type: :model, feature_category: :dependency_proxy do
  it_behaves_like 'ttl_expirable'
  it_behaves_like 'destructible', factory: :dependency_proxy_blob

  it_behaves_like 'updates namespace statistics' do
    let(:statistic_source) { build(:dependency_proxy_blob, size: 10) }
  end

  describe 'relationships' do
    it { is_expected.to belong_to(:group) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:group) }
    it { is_expected.to validate_presence_of(:file) }
    it { is_expected.to validate_presence_of(:file_name) }
  end

  describe '.total_size' do
    it 'returns 0 if no files' do
      expect(described_class.total_size).to eq(0)
    end

    it 'returns a correct sum of all files sizes' do
      create(:dependency_proxy_blob, size: 10)
      create(:dependency_proxy_blob, size: 20)

      expect(described_class.total_size).to eq(30)
    end
  end

  describe '.find_or_build' do
    let!(:blob) { create(:dependency_proxy_blob) }

    it 'builds new instance if not found' do
      expect(described_class.find_or_build('foo.gz')).not_to be_persisted
    end

    it 'finds an existing blob' do
      expect(described_class.find_or_build(blob.file_name)).to eq(blob)
    end
  end

  describe 'file is being stored' do
    subject { create(:dependency_proxy_blob) }

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
end
