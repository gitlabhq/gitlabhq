# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Namespace::RootStorageStatistics, feature_category: :groups_and_projects do
  let(:root_storage_statistics) { create(:namespace_root_storage_statistics) }

  subject(:entity) { described_class.new(root_storage_statistics).as_json }

  it 'exposes correct attributes' do
    expect(entity.keys).to(
      include(
        :build_artifacts_size,
        :container_registry_size,
        :container_registry_size_is_estimated,
        :dependency_proxy_size,
        :lfs_objects_size,
        :packages_size,
        :pipeline_artifacts_size,
        :repository_size,
        :snippets_size,
        :storage_size,
        :uploads_size,
        :wiki_size
      )
    )
  end
end
