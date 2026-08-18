# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::BundledResources::ComponentUploader, feature_category: :pipeline_composition do
  let_it_be(:bundled_resource) do
    create(:ci_catalog_bundled_resource, server_fqdn: 'Cell.Example.com', full_path: 'ACME/Widgets')
  end

  let_it_be(:version) do
    create(:ci_catalog_bundled_resource_version, bundled_resource: bundled_resource, semver: '1.2.3')
  end

  let_it_be_with_reload(:component) do
    create(:ci_catalog_bundled_resource_component,
      bundled_resource: bundled_resource, version: version, name: 'deploy')
  end

  it 'stores content at the downcased derived key and reads it back', :aggregate_failures do
    file = Tempfile.new('bundle')
    file.write('bundle-content')
    file.rewind

    component.file = file
    component.save!

    expect(component.file.path).to end_with('catalog/bundles/cell.example.com/acme/widgets/1.2.3/deploy.yml')
    expect(component.file.read).to eq('bundle-content')
  ensure
    file.close!
  end
end
