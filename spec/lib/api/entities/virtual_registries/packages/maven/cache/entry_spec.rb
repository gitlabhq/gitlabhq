# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::VirtualRegistries::Packages::Maven::Cache::Entry, feature_category: :virtual_registry do
  let(:cache_entry) { build_stubbed(:virtual_registries_packages_maven_cache_entry) }

  subject { described_class.new(cache_entry).as_json }

  it 'has the expected attributes' do
    is_expected.to include(:id, :group_id, :upstream_id, :upstream_checked_at, :created_at, :updated_at,
      :file, :file_md5, :file_sha1, :size, :relative_path, :upstream_etag, :content_type)
  end
end
