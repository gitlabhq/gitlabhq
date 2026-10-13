# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Catalog::Bundle::Collector, feature_category: :pipeline_composition do
  include RepoHelpers

  let_it_be_with_reload(:project) { create(:project, :repository) }

  let(:sha) { project.commit.sha }
  let(:entry_path) { 'templates/plan.yml' }

  let(:entry_content) do
    <<~YAML
      spec:
        inputs:
          enable_id_tokens:
            type: boolean
            default: false
      ---
      include:
        - local: '/templates/__internal_id_tokens_base_job.yml'
          inputs:
            as: '.id_tokens'
          rules:
            - if: '"$[[ inputs.enable_id_tokens ]]" == "true"'
      plan:
        script: tofu plan
    YAML
  end

  let(:base_job_content) do
    <<~YAML
      spec:
        inputs:
          as:
      ---
      '$[[ inputs.as ]]':
        id_tokens:
          GITLAB_OIDC_TOKEN:
            aud: $CI_SERVER_URL
    YAML
  end

  let(:project_files) do
    {
      entry_path => entry_content,
      'templates/__internal_id_tokens_base_job.yml' => base_job_content
    }
  end

  subject(:collect) { described_class.new(project: project, sha: sha, entry_path: entry_path).collect }

  around do |example|
    create_and_delete_files(project, project_files) do
      example.run
    end
  end

  def collect_errors
    collect
  rescue described_class::CollectError => e
    e.errors
  end

  it 'collects the entry file and its rule-guarded local include, as authored, keyed without a leading slash' do
    expect(collect).to eq(
      entry_path => entry_content,
      'templates/__internal_id_tokens_base_job.yml' => base_job_content
    )
  end

  context 'when the entry path has a leading slash' do
    subject(:collect) { described_class.new(project: project, sha: sha, entry_path: "/#{entry_path}").collect }

    it 'keys the entry file without it' do
      expect(collect.keys).to contain_exactly(entry_path, 'templates/__internal_id_tokens_base_job.yml')
    end
  end

  context 'with non-ASCII content' do
    let(:project_files) { { entry_path => "# Résumé du job\njob:\n  script: echo café\n" } }

    it 'returns it as UTF-8, byte for byte' do
      content = collect[entry_path]

      expect(content).to eq(project_files[entry_path])
      expect(content.encoding).to eq(Encoding::UTF_8)
    end
  end

  context 'with nested local includes' do
    let(:project_files) do
      {
        entry_path => "include: templates/a.yml\nroot_job:\n  script: echo",
        'templates/a.yml' => "include:\n  local: templates/b.yml\na_job:\n  script: echo",
        'templates/b.yml' => "b_job:\n  script: echo"
      }
    end

    it 'collects every level, including string and hash include forms' do
      expect(collect.keys).to contain_exactly(entry_path, 'templates/a.yml', 'templates/b.yml')
    end
  end

  context 'with an include cycle' do
    let(:project_files) do
      {
        entry_path => "include: templates/a.yml\nroot_job:\n  script: echo",
        'templates/a.yml' => "include: #{entry_path}\na_job:\n  script: echo"
      }
    end

    it 'collects each file once' do
      expect(collect.keys).to contain_exactly(entry_path, 'templates/a.yml')
    end
  end

  describe 'errors' do
    context 'when a missing file is included from two levels' do
      let(:project_files) do
        {
          entry_path => "include:\n  - local: templates/missing.yml\n  - local: templates/a.yml",
          'templates/a.yml' => "include:\n  - local: templates/missing.yml"
        }
      end

      it 'reports it once' do
        expect(collect_errors).to eq(['`templates/missing.yml`: file does not exist'])
      end
    end

    context 'when the entry file is missing' do
      let(:project_files) { { 'templates/other.yml' => "job:\n  script: echo" } }

      it 'rejects it' do
        expect(collect_errors).to eq(["`#{entry_path}`: file does not exist"])
      end
    end

    context 'with several errors across files' do
      let(:project_files) do
        {
          entry_path => "include:\n  - local: templates/a.yml\n  - component: example.com/group/project/c@1.0",
          'templates/a.yml' => "include:\n  - remote: 'https://example.com/ci.yml'"
        }
      end

      it 'reports all of them in one error, naming the file and the include' do
        expect { collect }.to raise_error(described_class::CollectError) do |error|
          expect(error.message).to eq(
            "`#{entry_path}` includes `component: example.com/group/project/c@1.0`: " \
              "`component:` includes are not allowed in a bundled component; " \
              "`templates/a.yml` includes `remote: https://example.com/ci.yml`: " \
              "`remote:` includes are not allowed in a bundled component"
          )
        end
      end
    end

    context 'when the collected files are larger than the total YAML size limit' do
      let(:project_files) do
        {
          entry_path => "include:\n  - local: templates/a.yml",
          'templates/a.yml' => "a:\n  script: echo #{'x' * 100}"
        }
      end

      before do
        stub_application_setting(ci_max_total_yaml_size_bytes: 100)
      end

      it 'rejects the component' do
        expect(collect_errors).to eq(["`#{entry_path}`: includes more than 100 bytes of YAML"])
      end
    end

    context 'when the component includes more files than the limit' do
      let(:project_files) do
        {
          entry_path => "include:\n  - local: templates/a.yml\n  - local: templates/b.yml",
          'templates/a.yml' => "a:\n  script: echo",
          'templates/b.yml' => "b:\n  script: echo"
        }
      end

      before do
        stub_application_setting(ci_max_includes: 2)
      end

      it 'rejects the component' do
        expect(collect_errors).to eq(["`#{entry_path}`: includes more than 2 files"])
      end
    end
  end
end
