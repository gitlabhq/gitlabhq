# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::BaseMetadataCacheUploader, feature_category: :package_registry do
  let(:test_uploader_class) do
    Class.new(described_class) do
      def filename
        'test_file.json'
      end
    end
  end

  let(:model) { double(object_storage_key: object_storage_key) } # rubocop:disable RSpec/VerifiedDoubles -- abstract uploader works with model having object_storage_key
  let(:uploader) { test_uploader_class.new(model, :file) }
  let(:object_storage_key) { 'some/key/path' }

  describe '#store_dir' do
    it 'uses the object_storage_key' do
      expect(uploader.store_dir).to eq(object_storage_key)
    end

    context 'without the object_storage_key' do
      let(:object_storage_key) { nil }

      it 'raises the error' do
        expect { uploader.store_dir }.to raise_error(
          described_class::ObjectNotReadyError, "#{model.class} model not ready"
        )
      end
    end
  end

  describe '#filename' do
    it 'returns defined filename' do
      expect(uploader.filename).to eq('test_file.json')
    end

    context 'when #filename is not implemented' do
      let(:test_uploader_class) { Class.new(described_class) }

      it 'raises NotImplementedError error' do
        expect { uploader.filename }.to raise_error(NotImplementedError)
      end
    end
  end
end
