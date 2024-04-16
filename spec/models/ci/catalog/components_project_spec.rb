# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::ComponentsProject, feature_category: :pipeline_composition do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project, :catalog_resource_with_components) }
  let_it_be(:catalog_resource) { create(:ci_catalog_resource, project: project) }

  let(:components_project) { described_class.new(project, project.commit.sha) }

  describe '#fetch_component_paths' do
    context 'when there are invalid paths' do
      let(:project) do
        create(:project, :small_repo, description: 'description',
          files: { 'templates/secrets.yml' => '',
                   'tests/test.yml' => 'this is invalid',
                   'README.md' => 'this is not ok' }
        )
      end

      it 'does not retrieve the invalid path(s) and only retrieves the valid one(s)' do
        paths = components_project.fetch_component_paths(project.default_branch)

        expect(paths).to contain_exactly('templates/secrets.yml')
      end
    end

    it 'retrieves all the valid paths for components' do
      paths = components_project.fetch_component_paths(project.default_branch)

      expect(paths).to contain_exactly(
        'templates/blank-yaml.yml', 'templates/dast/template.yml', 'templates/secret-detection.yml',
        'templates/template.yml'
      )
    end

    it 'does not fetch more paths than the limit' do
      paths = components_project.fetch_component_paths(project.default_branch, limit: 1)

      expect(paths.size).to eq(1)
    end
  end

  describe '#extract_component_name' do
    context 'with invalid component path' do
      it 'raises an error' do
        expect(components_project.extract_component_name('not-template/this-is-wrong.yml')).to be_nil
      end
    end

    context 'with valid component paths' do
      where(:path, :name) do
        'templates/secret-detection.yml'         | 'secret-detection'
        'templates/secret_detection.yml'         | 'secret_detection'
        'templates/secret_detection123.yml'      | 'secret_detection123'
        'templates/secret-detection-123.yml'     | 'secret-detection-123'
        'templates/dast/template.yml'            | 'dast'
        'templates/d-a-s_t/template.yml'         | 'd-a-s_t'
        'templates/template.yml'                 | 'template'
        'templates/blank-yaml.yml'               | 'blank-yaml'
      end

      with_them do
        it 'extracts the component name from the path' do
          expect(components_project.extract_component_name(path)).to eq(name)
        end
      end
    end
  end

  describe '#extract_spec' do
    context 'with a valid spec' do
      it 'extracts the spec from a blob' do
        blob = "spec:\n inputs:\n  website:\n---\nimage: alpine_1"

        expect(components_project.extract_spec(blob)).to eq({ inputs: { website: nil } })
      end
    end

    context 'with an invalid spec' do
      it 'raises InvalidFormatError' do
        blob = "spec:\n inputs:\n  website:\n---\nsome: invalid: string"

        expect do
          components_project.extract_spec(blob)
        end.to raise_error(::Gitlab::Config::Loader::FormatError,
          /mapping values are not allowed in this context/)
      end
    end
  end

  describe '#fetch_component' do
    where(:component_name, :content, :path) do
      'secret-detection' | "spec:\n inputs:\n  website:\n---\nimage: alpine_1" | 'templates/secret-detection.yml'
      'dast'             | 'image: alpine_2'                                   | 'templates/dast/template.yml'
      'template'         | 'image: alpine_3'                                   | 'templates/template.yml'
      'blank-yaml'       | ''                                                  | 'templates/blank-yaml.yml'
      'non/exist'        | nil                                                 | nil
    end

    with_them do
      it 'fetches the content for a component' do
        data = components_project.fetch_component(component_name)

        expect(data.path).to eq(path)
        expect(data.content).to eq(content)
      end
    end
  end

  describe '#find_catalog_component' do
    let_it_be(:version) do
      release = create(:release, project: project, tag: '2.0.0', sha: project.commit.sha)
      create(:ci_catalog_resource_version, catalog_resource: catalog_resource, release: release, semver: release.tag)
    end

    let_it_be(:dast_component) { create(:ci_catalog_resource_component, version: version, name: 'dast') }
    let(:component_name) { 'dast' }

    subject(:catalog_component) { components_project.find_catalog_component(component_name) }

    context 'when the component exists in the CI catalog' do
      it 'returns the catalog resource component' do
        expect(catalog_component).to eq(dast_component)
      end

      context 'when there is more than one catalog resource version with the given sha' do
        before_all do
          old_release = create(:release, project: project, tag: '1.0.0', sha: project.commit.sha)
          old_version = create(:ci_catalog_resource_version, catalog_resource: catalog_resource,
            release: old_release, semver: old_release.tag)

          create(:ci_catalog_resource_component, version: old_version, name: 'dast')
        end

        it 'returns the catalog resource component of the latest version' do
          expect(catalog_component).to eq(dast_component)
        end
      end
    end

    context 'when the component does not exist in the CI catalog' do
      let(:component_name) { 'secret-detection' }

      it 'returns nil' do
        expect(catalog_component).to be_nil
      end
    end
  end
end
