# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Nuget::SymbolUploader, feature_category: :package_registry do
  let(:file_path) { 'file/Path.pdb' }
  let(:object_storage_key) { 'object/storage/key' }
  let(:symbol) { build_stubbed(:nuget_symbol, object_storage_key: object_storage_key, file_path: file_path) }

  subject { described_class.new(symbol, :file) }

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
end
