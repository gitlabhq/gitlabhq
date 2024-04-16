# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::Versions::CreateService, feature_category: :pipeline_composition do
  describe '#execute' do
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

    context 'when the project is not a catalog resource' do
      it 'does not create a version' do
        project = create(:project, :repository)
        release =  create(:release, tag: '1.2.1', project: project, sha: project.repository.root_ref_sha)

        response = described_class.new(release).execute

        expect(response).to be_error
        expect(response.message).to include('Project is not a catalog resource')
      end
    end

    context 'when the catalog resource has different types of components and a release' do
      it 'creates a version for the release' do
        response = described_class.new(release).execute

        expect(response).to be_success

        version = Ci::Catalog::Resources::Version.last

        expect(version.release).to eq(release)
        expect(version.semver.to_s).to eq(release.tag)
        expect(version.catalog_resource).to eq(catalog_resource)
        expect(version.catalog_resource.project).to eq(project)
      end

      it 'marks the catalog resource as published' do
        described_class.new(release).execute

        expect(catalog_resource.reload.state).to eq('published')
      end

      context 'when the ci_catalog_create_metadata feature flag is disabled' do
        before do
          stub_feature_flags(ci_catalog_create_metadata: false)
        end

        it 'does not create components' do
          expect(Ci::Catalog::Resources::Component).not_to receive(:bulk_insert!).and_call_original
          expect(project.ci_components.count).to eq(0)

          response = described_class.new(release).execute

          expect(response).to be_success
          expect(project.ci_components.count).to eq(0)
        end
      end

      context 'when the ci_catalog_create_metadata feature flag is enabled' do
        context 'when there are at max 30 components' do
          let(:files) do
            num_components = 30
            components = (0...num_components).map { |i| "templates/secret#{i}.yml" }
            components << 'README.md'

            components.index_with { |_file| '' }
          end

          it 'creates the components' do
            response = described_class.new(release).execute

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
            response = described_class.new(release).execute

            expect(response).to be_error
            expect(response.message).to include('Release cannot contain more than 30 components')
            expect(project.ci_components.count).to eq(0)
          end
        end

        it 'bulk inserts all the components' do
          expect(Ci::Catalog::Resources::Component).to receive(:bulk_insert!).and_call_original

          described_class.new(release).execute
        end

        it 'creates components for the catalog resource' do
          expect(project.ci_components.count).to eq(0)
          response = described_class.new(release).execute

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
    end

    context 'with invalid data' do
      let_it_be(:files) do
        {
          'templates/secret-detection.yml' => 'some: invalid: syntax',
          'README.md' => 'Read me'
        }
      end

      it 'returns an error' do
        response = described_class.new(release).execute

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
        response = described_class.new(release).execute

        expect(response).to be_error
        expect(response.message).to include('Spec must be a valid json schema')
      end
    end
  end
end
