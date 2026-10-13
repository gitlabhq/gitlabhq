# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::Bundle::CollectService, feature_category: :pipeline_composition do
  let_it_be(:child_content) { "child-job:\n  script: echo \"héllo ✅\"" }
  let_it_be(:main_content) do
    <<~YAML
      include:
        - local: /templates/child.yml
      main-job:
        script: echo main
    YAML
  end

  let_it_be_with_reload(:project) do
    create(:project, :custom_repo, files: {
      'templates/child.yml' => child_content,
      'templates/main.yml' => main_content
    })
  end

  let_it_be(:release) { create(:release, project: project, sha: project.repository.root_ref_sha) }
  let_it_be_with_reload(:catalog_resource) { create(:ci_catalog_resource, project: project) }
  let_it_be(:version) do
    create(:ci_catalog_resource_version, release: release, catalog_resource: catalog_resource, semver: 'v1.2.0')
  end

  subject(:execute) { described_class.new(version).execute }

  def bundle_for(name)
    Gitlab::Json::SafeParser.parse(execute.payload[:components].find { |component| component[:name] == name }[:content])
  end

  it 'collects every component into a bundle', :aggregate_failures do
    expect(execute).to be_success
    expect(execute.payload[:components].pluck(:name)).to match_array(%w[child main])
  end

  it 'records the metadata and the files each component includes, as authored' do
    expect(bundle_for('main')).to eq(
      'format_version' => 1,
      'name' => 'main',
      'version' => 'v1.2.0',
      'sha' => version.sha,
      'entry_path' => 'templates/main.yml',
      'files' => { 'templates/main.yml' => main_content, 'templates/child.yml' => child_content }
    )
  end

  context 'when collection rejects components' do
    let_it_be_with_reload(:project) do
      create(:project, :custom_repo, files: {
        'templates/main.yml' => "include:\n  - component: example.com/group/project/other@1.0.0",
        'templates/other.yml' => "include:\n  - local: 'templates/*.yml'"
      })
    end

    let_it_be(:release) { create(:release, project: project, sha: project.repository.root_ref_sha) }
    let_it_be_with_reload(:catalog_resource) { create(:ci_catalog_resource, project: project) }
    let_it_be(:version) do
      create(:ci_catalog_resource_version, release: release, catalog_resource: catalog_resource, semver: 'v1.2.0')
    end

    it 'returns every rejection, naming the component', :aggregate_failures do
      expect(execute).to be_error
      expect(execute.reason).to eq(:collect_failed)
      expect(execute.payload[:errors]).to contain_exactly(
        'Component `main`: `templates/main.yml` includes `component: example.com/group/project/other@1.0.0`: ' \
          '`component:` includes are not allowed in a bundled component',
        'Component `other`: `templates/other.yml` includes `local: templates/*.yml`: ' \
          'wildcard locations are not allowed in a bundled component'
      )
      expect(execute.message).to eq(execute.payload[:errors].join('; '))
    end
  end
end
