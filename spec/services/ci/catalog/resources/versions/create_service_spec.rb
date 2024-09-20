# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::Versions::CreateService, feature_category: :pipeline_composition do
  describe '#execute from passed data' do
    let_it_be_with_refind(:project) { create(:project, :small_repo) }
    let_it_be_with_refind(:catalog_resource) { create(:ci_catalog_resource, project: project) }

    let(:release) do
      create(:release,
        tag: '1.2.0',
        project: project, sha: project.repository.root_ref_sha, author: project.first_owner
      )
    end

    let(:user) { project.first_owner }

    let(:metadata) do
      {
        components: [
          { name: 'secret-detection', spec: { 'inputs' => { 'website' => nil } }, component_type: 'template' },
          { name: 'dast',             spec: {}, component_type: 'template' },
          { name: 'blank-yaml',       spec: {}, component_type: 'template' },
          { name: 'template',         spec: { 'inputs' => { 'environment' => nil } }, component_type: 'template' }
        ]
      }
    end

    subject(:execute) { described_class.new(release, user, metadata).execute }

    context 'when the catalog resource has different types of components and a release' do
      it 'creates a version for the release and marks the catalog resource as published' do
        response = execute

        version = Ci::Catalog::Resources::Version.last

        expect(response).to be_success
        expect(response.payload[:version]).to eq(version)
        expect(version.release).to eq(release)
        expect(version.semver.to_s).to eq(release.tag)
        expect(version.catalog_resource).to eq(catalog_resource)
        expect(version.catalog_resource.project).to eq(project)
        expect(catalog_resource.reload.state).to eq('published')
      end

      it 'bulk inserts all the components' do
        expect(Ci::Catalog::Resources::Component).to receive(:bulk_insert!).and_call_original

        execute
      end

      it 'creates components for the catalog resource' do
        expect(project.ci_components.count).to eq(0)
        response = execute

        expect(response).to be_success

        version = Ci::Catalog::Resources::Version.last

        components = project.ci_components.order(:name)

        expect(components.count).to eq(4)
        expect(components[0].name).to eq('blank-yaml')
        expect(components[0].project).to eq(version.project)
        expect(components[0].spec).to eq({})
        expect(components[0].catalog_resource).to eq(version.catalog_resource)
        expect(components[0].version).to eq(version)
        expect(components[1].name).to eq('dast')
        expect(components[1].project).to eq(version.project)
        expect(components[1].spec).to eq({})
        expect(components[1].catalog_resource).to eq(version.catalog_resource)
        expect(components[1].version).to eq(version)
        expect(components[2].name).to eq('secret-detection')
        expect(components[2].project).to eq(version.project)
        expect(components[2].spec).to eq({ 'inputs' => { 'website' => nil } })
        expect(components[2].catalog_resource).to eq(version.catalog_resource)
        expect(components[2].version).to eq(version)
        expect(components[3].name).to eq('template')
        expect(components[3].project).to eq(version.project)
        expect(components[3].spec).to eq({ 'inputs' => { 'environment' => nil } })
        expect(components[3].catalog_resource).to eq(version.catalog_resource)
        expect(components[3].version).to eq(version)
      end
    end

    context 'when there are at max 30 components' do
      let(:metadata) do
        num_components = 30
        {
          components: (0...num_components).map { |i| { name: "component_#{i}", spec: {}, component_type: 'template' } }
        }
      end

      it 'creates the components' do
        response = execute

        expect(response).to be_success
        expect(project.ci_components.count).to eq(30)
      end
    end

    context 'when there are more than 30 components' do
      let(:metadata) do
        num_components = 31
        {
          components: (0..num_components).map { |i| { name: "component_#{i}", spec: {}, component_type: 'template' } }
        }
      end

      it 'raises an error' do
        response = execute

        expect(response).to be_error
        expect(response.message).to include('Release cannot contain more than 30 components')
        expect(project.ci_components.count).to eq(0)
      end
    end

    context 'when the project is not a catalog resource' do
      let(:release) { create(:release, tag: '1.2.1') }

      it 'does not create a version' do
        response = execute

        expect(response).to be_error
        expect(response.message).to include('Project is not a catalog resource')
      end
    end

    context 'with invalid data' do
      let(:metadata) do
        {
          components: [
            { invalid: 'data' }
          ]
        }
      end

      it 'returns an error' do
        response = execute

        expect(response).to be_error
        expect(response.message).to include('Spec must be a valid json schema, Name can\'t be blank')
      end
    end

    context 'when the user is not the author of the release' do
      let_it_be(:user) { create(:user) }

      before_all do
        project.add_maintainer(user)
      end

      it 'returns an error and does not create a version' do
        response = execute

        expect(Ci::Catalog::Resources::Version.count).to be(0)
        expect(response).to be_error
        expect(response.message).to include('Published by must be the same as the release author')
      end
    end

    context 'with no data' do
      let(:metadata) { {} }

      it 'saves the version with no component' do
        response = execute

        expect(response).to be_success
        expect(project.ci_components.count).to eq(0)

        version = Ci::Catalog::Resources::Version.last

        expect(version.release).to eq(release)
        expect(version.semver.to_s).to eq(release.tag)
        expect(version.catalog_resource).to eq(catalog_resource)
        expect(version.catalog_resource.project).to eq(project)
        expect(catalog_resource.reload.state).to eq('published')
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

    let(:release) do
      create(:release,
        tag: '1.2.0',
        project: project, sha: project.repository.root_ref_sha, author: project.first_owner
      )
    end

    let(:user) { project.first_owner }

    let!(:catalog_resource) { create(:ci_catalog_resource, project: project) }

    subject(:execute) { described_class.new(release, user, nil).execute }

    context 'when the project is not a catalog resource' do
      let(:release) { create(:release, tag: '1.2.1') }

      it 'does not create a version' do
        response = execute

        expect(response).to be_error
        expect(response.message).to include('Project is not a catalog resource')
      end
    end

    context 'when the catalog resource has different types of components and a release' do
      it 'creates a version for the release and marks the catalog resource as published' do
        response = execute

        version = Ci::Catalog::Resources::Version.last

        expect(response).to be_success
        expect(response.payload[:version]).to eq(version)
        expect(version.release).to eq(release)
        expect(version.semver.to_s).to eq(release.tag)
        expect(version.catalog_resource).to eq(catalog_resource)
        expect(version.catalog_resource.project).to eq(project)
        expect(catalog_resource.reload.state).to eq('published')
      end

      it 'bulk inserts all the components' do
        expect(Ci::Catalog::Resources::Component).to receive(:bulk_insert!).and_call_original

        execute
      end

      it 'creates components for the catalog resource' do
        expect(project.ci_components.count).to eq(0)
        response = execute

        expect(response).to be_success

        version = Ci::Catalog::Resources::Version.last

        expect(project.ci_components.count).to eq(4)
        expect(project.ci_components.first.name).to eq('blank-yaml')
        expect(project.ci_components.first.project).to eq(version.project)
        expect(project.ci_components.first.spec).to eq({})
        expect(project.ci_components.first.catalog_resource).to eq(version.catalog_resource)
        expect(project.ci_components.first.version).to eq(version)
        expect(project.ci_components.second.name).to eq('dast')
        expect(project.ci_components.second.project).to eq(version.project)
        expect(project.ci_components.second.spec).to eq({})
        expect(project.ci_components.second.catalog_resource).to eq(version.catalog_resource)
        expect(project.ci_components.second.version).to eq(version)
        expect(project.ci_components.third.name).to eq('secret-detection')
        expect(project.ci_components.third.project).to eq(version.project)
        expect(project.ci_components.third.spec).to eq({ 'inputs' => { 'website' => nil } })
        expect(project.ci_components.third.catalog_resource).to eq(version.catalog_resource)
        expect(project.ci_components.third.version).to eq(version)
        expect(project.ci_components.fourth.name).to eq('template')
        expect(project.ci_components.fourth.project).to eq(version.project)
        expect(project.ci_components.fourth.spec).to eq({ 'inputs' => { 'environment' => nil } })
        expect(project.ci_components.fourth.catalog_resource).to eq(version.catalog_resource)
        expect(project.ci_components.fourth.version).to eq(version)
      end
    end

    context 'when there are at max 30 components' do
      let(:files) do
        num_components = 30
        components = (0...num_components).map { |i| "templates/secret#{i}.yml" }
        components << 'README.md'

        components.index_with { |_file| '' }
      end

      it 'creates the components' do
        response = execute

        expect(response).to be_success
        expect(project.ci_components.count).to eq(30)
      end
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
        expect(project.ci_components.count).to eq(0)
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

    context 'when the user is not the author of the release' do
      let(:user) { create(:user) }

      before do
        project.add_maintainer(user)
      end

      it 'returns an error and does not create a version' do
        response = execute

        expect(Ci::Catalog::Resources::Version.count).to be(0)
        expect(response).to be_error
        expect(response.message).to include('Published by must be the same as the release author')
      end
    end

    context 'with no data' do
      let(:files) do
        {
          'README.md' => 'Read me'
        }
      end

      it 'saves the version with no component' do
        response = execute

        expect(response).to be_success
        expect(project.ci_components.count).to eq(0)

        version = Ci::Catalog::Resources::Version.last

        expect(version.release).to eq(release)
        expect(version.semver.to_s).to eq(release.tag)
        expect(version.catalog_resource).to eq(catalog_resource)
        expect(version.catalog_resource.project).to eq(project)
        expect(catalog_resource.reload.state).to eq('published')
      end
    end
  end
end
