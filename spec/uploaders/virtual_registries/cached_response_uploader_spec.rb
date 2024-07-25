# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::VirtualRegistries::CachedResponseUploader, feature_category: :virtual_registry do
  let(:object_storage_key) { 'object/storage/key' }
  let(:cached_response) do
    build_stubbed(
      :virtual_registries_packages_maven_cached_response,
      object_storage_key: object_storage_key,
      relative_path: 'relative/path/test.txt'
    )
  end

  subject(:uploader) { described_class.new(cached_response, :file) }

  it { is_expected.to include_module(::ObjectStorage::Concern) }

  describe '#store_dir' do
    it 'uses the object_storage_key' do
      expect(uploader.store_dir).to eq(object_storage_key)
    end
  end
end
