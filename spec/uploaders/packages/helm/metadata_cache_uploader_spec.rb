# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Helm::MetadataCacheUploader, feature_category: :package_registry do
  subject(:uploader) { described_class.new(helm_metadata_cache, :file) }

  let(:object_storage_key) { 'object/storage/key' }
  let(:helm_metadata_cache) { build_stubbed(:helm_metadata_cache, object_storage_key: object_storage_key) }

  it { is_expected.to include_module(Packages::GcsSignedUrlMetadata) }

  describe '#filename' do
    it 'returns index.yaml' do
      expect(uploader.filename).to eq('index.yaml')
    end
  end

  context 'with object storage enabled' do
    let(:helm_metadata_cache) { create(:helm_metadata_cache, :object_storage) }

    before do
      stub_object_storage_uploader(
        config: Gitlab.config.packages.object_store,
        uploader: described_class
      )
    end

    it_behaves_like 'augmenting GCS signed URL with metadata'
  end
end
