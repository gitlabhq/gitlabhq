# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::Versions::BuildComponentsService, feature_category: :pipeline_composition do
  describe '#execute from passed data' do
    let!(:project) { create(:project, :small_repo) }
    let!(:catalog_resource) { create(:ci_catalog_resource, project: project) }
    let!(:release) { create(:release, tag: '1.2.0', project: project, sha: project.repository.root_ref_sha) }
    let!(:version) { create(:ci_catalog_resource_version, release: release, catalog_resource: catalog_resource) }

    let(:components_data) do
      [
        { name: 'secret-detection', spec: { 'inputs' => { 'website' => nil } }, component_type: 'template' },
        { name: 'dast',             spec: {}, component_type: 'template' },
        { name: 'blank-yaml',       spec: {}, component_type: 'template' },
        { name: 'template',         spec: { 'inputs' => { 'environment' => nil } }, component_type: 'template' }
      ]
    end

    subject(:execute) { described_class.new(release, version, components_data).execute }

    it 'builds components for a release version' do
      expect(execute).to be_success

      components = execute.payload

      expect(components.size).to eq(4)
      expect(components.map(&:name)).to contain_exactly('blank-yaml', 'dast', 'secret-detection', 'template')
      expect(components.map(&:spec)).to contain_exactly(
        {},
        {},
        { 'inputs' => { 'website' => nil } },
        { 'inputs' => { 'environment' => nil } }
      )
    end

    context 'when there are more than 30 components' do
      let(:components_data) do
        num_components = 31
        (0...num_components).map { |i| { name: "component_#{i}", spec: {}, component_type: 'template' } }
      end

      it 'raises an error' do
        response = execute

        expect(response).to be_error
        expect(response.message).to include('Release cannot contain more than 30 components')
      end
    end

    context 'with invalid data' do
      let(:components_data) do
        [
          { invalid: 'data' }
        ]
      end

      it 'returns an error' do
        response = execute

        expect(response).to be_error
        expect(response.message).to include('Spec must be a valid json schema, Name can\'t be blank')
      end
    end

    context 'with no data' do
      let(:components_data) { [] }

      it 'returns success but no components' do
        response = execute

        expect(response).to be_success
        expect(response.payload).to be_empty
      end
    end

    context 'with an invalid component type' do
      let(:components_data) do
        [
          { name: 'secret-detection', spec: { 'inputs' => { 'website' => nil } }, component_type: 'invalid' }
        ]
      end

      it 'returns an error' do
        response = execute

        expect(response).to be_error
        expect(response.message).to include("'invalid' is not a valid component_type")
      end
    end
  end

  describe '#execute from fetched data (LEGACY)' do
    let(:files) do
      {
        'templates/secret-detection.yml' => "spec:\n inputs:\n  website:\n---\nimage: alpine_1",
        'templates/dast/template.yml' => 'image: alpine_2',
        'templates/blank-yaml.yml' => '',
        'templates/dast/sub-folder/template.yml' => 'image: alpine_3',
        'templates/template.yml' => "spec:\n inputs:\n  environment:\n---\nimage: alpine_6",
        'tests/test.yml' => 'image: alpine_7',
        'README.md' => 'Read me'
      }
    end

    let(:project) do
      create(
        :project, :custom_repo,
        description: 'Simple and Complex components',
        files: files
      )
    end

    let(:release) { create(:release, tag: '1.2.0', project: project, sha: project.repository.root_ref_sha) }
    let!(:catalog_resource) { create(:ci_catalog_resource, project: project) }
    let(:version) { create(:ci_catalog_resource_version, release: release, catalog_resource: catalog_resource) }

    subject(:execute) { described_class.new(release, version, nil).execute }

    it 'builds components for a release version' do
      expect(execute).to be_success

      components = execute.payload

      expect(components.size).to eq(4)
      expect(components.map(&:name)).to contain_exactly('blank-yaml', 'dast', 'secret-detection', 'template')
      expect(components.map(&:spec)).to contain_exactly(
        {},
        {},
        { 'inputs' => { 'website' => nil } },
        { 'inputs' => { 'environment' => nil } }
      )
    end

    context 'when there are more than 30 components' do
      let(:files) do
        num_components = 31
        components = (0..num_components).map { |i| "templates/secret#{i}.yml" }
        components << 'README.md'

        components.index_with { |_file| '' }
      end

      it 'raises an error' do
        response = execute

        expect(response).to be_error
        expect(response.message).to include('Release cannot contain more than 30 components')
      end
    end

    context 'with invalid data' do
      let_it_be(:files) do
        {
          'templates/secret-detection.yml' => 'some: invalid: syntax',
          'README.md' => 'Read me'
        }
      end

      it 'returns an error' do
        response = execute

        expect(response).to be_error
        expect(response.message).to include('mapping values are not allowed in this context')
      end
    end

    context 'when one or more components are invalid' do
      let_it_be(:files) do
        {
          'templates/secret-detection.yml' => "spec:\n inputs:\n  - website\n---\nimage: alpine_1",
          'README.md' => 'Read me'
        }
      end

      it 'returns an error' do
        response = execute

        expect(response).to be_error
        expect(response.message).to include('Spec must be a valid json schema')
      end
    end
  end
end
