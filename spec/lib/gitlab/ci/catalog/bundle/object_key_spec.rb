# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Catalog::Bundle::ObjectKey, feature_category: :pipeline_composition do
  subject(:object_key) { described_class.new(component) }

  let(:server_fqdn) { 'cell.example.com' }
  let(:full_path) { 'acme/widgets' }
  let(:component_name) { 'deploy' }
  let(:semver) { '1.2.3' }

  let(:bundled_resource) do
    build(:ci_catalog_bundled_resource, server_fqdn: server_fqdn, full_path: full_path)
  end

  let(:version) do
    build(:ci_catalog_bundled_resource_version, bundled_resource: bundled_resource, semver: semver)
  end

  let(:component) do
    build(:ci_catalog_bundled_resource_component,
      bundled_resource: bundled_resource, version: version, name: component_name)
  end

  it 'derives the key from the identifying fields', :aggregate_failures do
    expect(object_key.dir).to eq('catalog/bundles/cell.example.com/acme/widgets/1.2.3')
    expect(object_key.filename).to eq('deploy.yml')
  end

  context 'when the fields the database indexes under lower() vary in case' do
    let(:server_fqdn) { 'Cell.Example.COM' }
    let(:full_path) { 'ACME/Widgets' }

    it 'derives the same directory as their lowercase equivalents' do
      expect(object_key.dir).to eq('catalog/bundles/cell.example.com/acme/widgets/1.2.3')
    end
  end

  context 'when the fields the database indexes case-sensitively vary in case' do
    let(:component_name) { 'Deploy' }
    let(:semver) { '1.2.3-RC1' }

    it 'preserves their case so distinct rows derive distinct keys', :aggregate_failures do
      expect(object_key.dir).to eq('catalog/bundles/cell.example.com/acme/widgets/1.2.3-RC1')
      expect(object_key.filename).to eq('Deploy.yml')
    end
  end
end
