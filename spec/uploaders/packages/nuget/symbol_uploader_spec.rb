# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::SymbolUploader, feature_category: :package_registry do
  let(:file_path) { 'file/Path.pdb' }
  let(:object_storage_key) { 'object/storage/key' }
  let(:symbol) { build_stubbed(:nuget_symbol, object_storage_key: object_storage_key, file_path: file_path) }
  let(:uploader) { described_class.new(symbol, :symbol_file) }

  subject { uploader }

  it { is_expected.to include_module(Packages::GcsSignedUrlMetadata) }

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
            'Packages::Nuget::Symbol model not ready'
          )
      end
    end
  end

  context 'with object storage enabled' do
    let(:symbol) { create(:nuget_symbol, :object_storage) }

    before do
      stub_object_storage_uploader(
        config: Gitlab.config.packages.object_store,
        uploader: described_class
      )
    end

    it_behaves_like 'augmenting GCS signed URL with metadata'
  end
end
