# frozen_string_literal: true

require 'spec_helper'
require_migration!('remove_bad_dependency_proxy_manifests')

RSpec.describe RemoveBadDependencyProxyManifests, schema: 20210128140157 do
  let_it_be(:namespaces) { table(:namespaces) }
  let_it_be(:dependency_proxy_manifests) { table(:dependency_proxy_manifests) }
  let_it_be(:group) { namespaces.create!(type: 'Group', name: 'test', path: 'test') }

  let_it_be(:dependency_proxy_manifest_with_content_type) do
    dependency_proxy_manifests.create!(group_id: group.id, file: 'foo', file_name: 'foo', digest: 'asdf1234', content_type: 'content-type' )
  end

  let_it_be(:dependency_proxy_manifest_without_content_type) do
    dependency_proxy_manifests.create!(group_id: group.id, file: 'bar', file_name: 'bar', digest: 'fdsa6789')
  end

  it 'removes the dependency_proxy_manifests with a content_type', :aggregate_failures do
    expect(dependency_proxy_manifest_with_content_type).to be_present
    expect(dependency_proxy_manifest_without_content_type).to be_present

    expect { migrate! }.to change { dependency_proxy_manifests.count }.from(2).to(1)

    expect(dependency_proxy_manifests.where.not(content_type: nil)).to be_empty
    expect(dependency_proxy_manifest_without_content_type.reload).to be_present
  end
end
