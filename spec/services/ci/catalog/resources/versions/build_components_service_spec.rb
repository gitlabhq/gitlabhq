# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::Versions::BuildComponentsService, feature_category: :pipeline_composition do
  describe '#execute from passed data' do
    let_it_be_with_reload(:project) { create(:project, :small_repo) }
    let_it_be_with_reload(:catalog_resource) { create(:ci_catalog_resource, project: project) }
    let_it_be(:release) { create(:release, tag: '1.2.0', project: project, sha: project.repository.root_ref_sha) }
    let_it_be(:version) { create(:ci_catalog_resource_version, release: release, catalog_resource: catalog_resource) }

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
        { 'inputs' => { 'website' => nil }, 'inputs_order' => ['website'] },
        { 'inputs' => { 'environment' => nil }, 'inputs_order' => ['environment'] }
      )
    end

    context 'when a spec has multiple inputs' do
      let(:components_data) do
        [
          {
            name: 'deploy',
            spec: {
              'inputs' => {
                'bazbazbaz' => nil,
                'foo' => { 'default' => 'production', 'description' => 'Where to deploy' },
                'barbar' => { 'type' => 'array' }
              }
            },
            component_type: 'template'
          }
        ]
      end

      it 'records the order of the inputs and leaves their configuration untouched' do
        expect(execute).to be_success

        expect(execute.payload.first.spec).to eq(
          'inputs' => {
            'bazbazbaz' => nil,
            'foo' => { 'default' => 'production', 'description' => 'Where to deploy' },
            'barbar' => { 'type' => 'array' }
          },
          'inputs_order' => %w[bazbazbaz foo barbar]
        )
      end
    end

    context 'when a spec already contains inputs_order' do
      let(:components_data) do
        [
          {
            name: 'deploy',
            spec: {
              'inputs' => { 'bazbazbaz' => nil, 'foo' => nil },
              'inputs_order' => ['made-up']
            },
            component_type: 'template'
          }
        ]
      end

      it 'replaces the value with the server-computed order' do
        expect(execute).to be_success

        expect(execute.payload.first.spec['inputs_order']).to eq(%w[bazbazbaz foo])
      end
    end

    context 'when a spec contains inputs_order but inputs is not a hash' do
      let(:components_data) do
        [
          { name: 'deploy', spec: { 'inputs_order' => ['made-up'] }, component_type: 'template' }
        ]
      end

      it 'drops inputs_order' do
        expect(execute).to be_success

        expect(execute.payload.first.spec).to eq({})
      end
    end

    context 'when there are more than 100 components' do
      let(:components_data) do
        num_components = 101
        (0...num_components).map { |i| { name: "component_#{i}", spec: {}, component_type: 'template' } }
      end

      it 'raises an error' do
        response = execute

        expect(response).to be_error
        expect(response.message).to include('Release cannot contain more than 100 components')
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
        { 'inputs' => { 'website' => nil }, 'inputs_order' => ['website'] },
        { 'inputs' => { 'environment' => nil }, 'inputs_order' => ['environment'] }
      )
    end

    context 'when a spec has multiple inputs' do
      let(:files) do
        {
          'templates/deploy.yml' =>
            "spec:\n inputs:\n  bazbazbaz:\n  foo:\n   default: production\n  barbar:\n   type: array\n---\n" \
            'image: alpine'
        }
      end

      it 'records the order of the inputs and leaves their configuration untouched' do
        expect(execute).to be_success

        expect(execute.payload.first.spec).to eq(
          'inputs' => {
            'bazbazbaz' => nil,
            'foo' => { 'default' => 'production' },
            'barbar' => { 'type' => 'array' }
          },
          'inputs_order' => %w[bazbazbaz foo barbar]
        )
      end
    end

    context 'when a spec already contains inputs_order' do
      let(:files) do
        {
          'templates/deploy.yml' =>
            "spec:\n inputs:\n  bazbazbaz:\n  foo:\n inputs_order:\n  - made-up\n---\nimage: alpine"
        }
      end

      it 'replaces the value with the server-computed order' do
        expect(execute).to be_success

        expect(execute.payload.first.spec['inputs_order']).to eq(%w[bazbazbaz foo])
      end
    end

    context 'when there are more than 100 components' do
      let(:files) do
        num_components = 101
        components = (0..num_components).map { |i| "templates/secret#{i}.yml" }
        components << 'README.md'

        components.index_with { |_file| '' }
      end

      it 'raises an error' do
        response = execute

        expect(response).to be_error
        expect(response.message).to include('Release cannot contain more than 100 components')
      end
    end

    context 'with invalid data' do
      let_it_be(:files) do
        {
          'templates/secret-detection.yml' => 'some: invalid: syntax',
          'README.md' => 'Read me'
        }
      end

      it 'returns an error with filename' do
        response = execute

        expect(response).to be_error
        expect(response.message).to include('templates/secret-detection.yml')
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
