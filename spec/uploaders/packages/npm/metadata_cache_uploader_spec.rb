# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Npm::MetadataCacheUploader, feature_category: :package_registry do
  let(:object_storage_key) { 'object/storage/key' }
  let(:npm_metadata_cache) { build_stubbed(:npm_metadata_cache, object_storage_key: object_storage_key) }
  let(:uploader) { described_class.new(npm_metadata_cache, :file) }

  subject { uploader }

  it { is_expected.to include_module(Packages::GcsSignedUrlMetadata) }

  describe '#filename' do
    it 'returns metadata.json' do
      expect(subject.filename).to eq('metadata.json')
    end
  end

  describe '#store_dir' do
    it 'uses the object_storage_key' do
      expect(subject.store_dir).to eq(object_storage_key)
    end

    context 'without the object_storage_key' do
      let(:object_storage_key) { nil }

      it 'raises the error' do
        expect { subject.store_dir }
          .to raise_error(
            described_class::ObjectNotReadyError,
            'Packages::Npm::MetadataCache model not ready'
          )
      end
    end
  end

  context 'with object storage enabled' do
    let(:npm_metadata_cache) { create(:npm_metadata_cache, :object_storage) }

    before do
      stub_object_storage_uploader(
        config: Gitlab.config.packages.object_store,
        uploader: described_class
      )
    end

    it_behaves_like 'augmenting GCS signed URL with metadata'
  end
end
