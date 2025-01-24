# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::VirtualRegistries::Cache::EntryUploader, feature_category: :virtual_registry do
  let(:object_storage_key) { 'object/storage/key' }
  let(:cache_entry) do
    build_stubbed(
      :virtual_registries_packages_maven_cache_entry,
      object_storage_key: object_storage_key,
      relative_path: 'relative/path/test.txt'
    )
  end

  let(:uploader) { described_class.new(cache_entry, :file) }

  describe 'inclusions' do
    subject { uploader }

    it { is_expected.to include_module(::ObjectStorage::Concern) }
  end

  describe '#store_dir' do
    subject { uploader.store_dir }

    it { is_expected.to eq(object_storage_key) }
  end

  describe '#check_remote_file_existence_on_upload?' do
    subject { uploader.check_remote_file_existence_on_upload? }

    it { is_expected.to be(false) }
  end

  describe '#sync_model_object_store?' do
    subject { uploader.sync_model_object_store? }

    it { is_expected.to be(true) }
  end
end
