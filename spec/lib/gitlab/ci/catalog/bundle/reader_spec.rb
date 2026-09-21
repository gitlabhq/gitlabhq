# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Catalog::Bundle::Reader, feature_category: :pipeline_composition do
  let_it_be(:resource) do
    create(:ci_catalog_bundled_resource, server_fqdn: 'gitlab.com', full_path: 'components/sast')
  end

  let_it_be(:bundled_version) do
    create(:ci_catalog_bundled_resource_version, bundled_resource: resource, semver: '5.2.0')
  end

  let(:server_fqdn) { 'gitlab.com' }
  let(:full_path) { 'components/sast' }
  let(:semver) { '5.2.0' }
  let(:component_name) { 'scan' }

  subject(:reader) do
    described_class.new(
      server_fqdn: server_fqdn, full_path: full_path, semver: semver, component_name: component_name
    )
  end

  before do
    stub_object_storage_uploader(
      config: Gitlab.config.ci_catalog_bundles.object_store,
      uploader: ::Ci::Catalog::BundledResources::ComponentUploader
    )

    create(:ci_catalog_bundled_resource_component, :remote_store, version: bundled_version, name: 'scan',
      file: ::CarrierWaveStringFile.new_file(
        file_content: 'flattened: yaml', filename: 'scan', content_type: 'application/x-yaml'
      ))
  end

  shared_examples 'a readable bundle' do
    it 'reports itself available' do
      expect(reader.available?).to be(true)
    end

    it 'returns the stored document' do
      expect(reader.content).to eq('flattened: yaml')
    end
  end

  shared_examples 'an unreadable bundle' do
    it 'reports itself unavailable' do
      expect(reader.available?).to be(false)
    end

    it 'returns no content' do
      expect(reader.content).to be_nil
    end
  end

  context 'when the component is bundled on this cell' do
    it_behaves_like 'a readable bundle'
  end

  context 'when the resource is not bundled on this cell' do
    let(:full_path) { 'components/unknown' }

    it_behaves_like 'an unreadable bundle'
  end

  context 'when the requested version is not bundled' do
    let(:semver) { '9.9.9' }

    it_behaves_like 'an unreadable bundle'
  end

  context 'when the component is not in the bundle' do
    let(:component_name) { 'missing' }

    it_behaves_like 'an unreadable bundle'
  end

  context 'when the row exists but has no stored document' do
    let(:component_name) { 'fileless' }

    before do
      create(:ci_catalog_bundled_resource_component, version: bundled_version, name: 'fileless')
    end

    it_behaves_like 'an unreadable bundle'
  end

  context 'when the row points at an object that is not in the bucket' do
    let(:component_name) { 'orphaned' }

    before do
      create(:ci_catalog_bundled_resource_component, :remote_store, version: bundled_version, name: 'orphaned')
        .update_column(:file, 'orphaned')
    end

    it_behaves_like 'an unreadable bundle'
  end

  describe 'reference normalization' do
    context 'when the version is v-prefixed' do
      let(:semver) { 'v5.2.0' }

      it_behaves_like 'a readable bundle'
    end

    context 'when the natural key differs in case' do
      let(:server_fqdn) { 'GitLab.com' }
      let(:full_path) { 'Components/SAST' }

      it_behaves_like 'a readable bundle'
    end
  end
end
