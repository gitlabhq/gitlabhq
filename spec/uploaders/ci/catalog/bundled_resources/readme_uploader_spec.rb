# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::BundledResources::ReadmeUploader, feature_category: :pipeline_composition do
  let_it_be(:bundled_resource) do
    create(:ci_catalog_bundled_resource, server_fqdn: 'Cell.Example.com', full_path: 'ACME/Widgets')
  end

  let_it_be_with_reload(:version) do
    create(:ci_catalog_bundled_resource_version, bundled_resource: bundled_resource, semver: '1.2.3')
  end

  it 'stores the readme at the downcased derived key' do
    version.update!(readme: '# Widgets')

    expect(version.send(:external_storage_uploader).path)
      .to end_with('catalog/bundles/cell.example.com/acme/widgets/1.2.3/readme.json')
  end

  it 'shares a directory with the component documents of the same version' do
    component = create(:ci_catalog_bundled_resource_component,
      bundled_resource: bundled_resource, version: version, name: 'deploy')

    expect(version.send(:external_storage_uploader).store_dir).to eq(component.file.store_dir)
  end
end
