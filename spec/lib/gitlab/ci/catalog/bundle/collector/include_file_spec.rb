# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Catalog::Bundle::Collector::IncludeFile, '#execute', feature_category: :pipeline_composition do
  using RSpec::Parameterized::TableSyntax

  let(:project) { build_stubbed(:project) }
  let(:path) { 'templates/plan.yml' }
  let(:include_matcher) do
    ::Gitlab::Ci::Config::External::Mapper::Matcher.new(
      ::Gitlab::Ci::Config::External::Context.new(project: project, sha: 'sha')
    )
  end

  subject(:result) { described_class.new(path: path, content: content, include_matcher: include_matcher).execute }

  def end_with_reasons(*reasons)
    match(reasons.map { |reason| end_with(": #{reason}") })
  end

  describe 'paths' do
    context 'with string and hash includes' do
      let(:content) do
        <<~YAML
          include:
            - templates/a.yml
            - local: /templates/b.yml
          job:
            script: echo
        YAML
      end

      it 'returns their locations without a leading slash' do
        expect(result.paths).to eq(['templates/a.yml', 'templates/b.yml'])
        expect(result.errors).to be_empty
      end
    end

    context 'with a single include that is not in a list' do
      let(:content) { "include: templates/a.yml\njob:\n  script: echo" }

      it 'returns its location' do
        expect(result.paths).to eq(['templates/a.yml'])
      end
    end

    context 'with a header and rule-guarded include' do
      let(:content) do
        <<~YAML
          spec:
            inputs:
              enable_id_tokens:
                type: boolean
                default: false
          ---
          include:
            - local: templates/base.yml
              rules:
                - if: '"$[[ inputs.enable_id_tokens ]]" == "true"'
        YAML
      end

      it 'returns the location regardless of the rule' do
        expect(result.paths).to eq(['templates/base.yml'])
      end
    end

    context 'with `rules:exists` that names a project' do
      let(:content) do
        <<~YAML
          include:
            - local: templates/test.yml
              rules:
                - exists:
                    paths:
                      - '$[[ inputs.root_dir ]]/**/*.tftest.hcl'
                    project: $CI_PROJECT_PATH
                    ref: $CI_COMMIT_SHA
                - exists:
                    regexp: '\\.tftest\\.hcl\\z'
                    project: $CI_PROJECT_PATH
        YAML
      end

      it 'returns the location' do
        expect(result.paths).to eq(['templates/test.yml'])
        expect(result.errors).to be_empty
      end
    end

    context 'with a child pipeline trigger in a job' do
      let(:content) do
        <<~YAML
          full_pipeline:
            trigger:
              include:
                - project: 'components/opentofu'
                  file: '/templates/full-pipeline.yml'
        YAML
      end

      it 'does not treat the job configuration as an include' do
        expect(result.paths).to be_empty
        expect(result.errors).to be_empty
      end
    end

    context 'with a header and no body' do
      let(:content) { "spec:\n  inputs:\n    name:\n---\n" }

      it 'returns no locations' do
        expect(result.paths).to be_empty
        expect(result.errors).to be_empty
      end
    end
  end

  describe 'errors' do
    context 'with a rejected include' do
      let(:content) { "include:\n  - remote: 'https://example.com/ci.yml'" }

      it 'names the file and the include' do
        expect(result.errors).to eq([
          "`templates/plan.yml` includes `remote: https://example.com/ci.yml`: " \
            "`remote:` includes are not allowed in a bundled component"
        ])
      end
    end

    context 'with a non-local include type' do
      where(:include_entry, :reason) do
        { component: '$CI_SERVER_FQDN/$CI_PROJECT_PATH/readme-check@$CI_COMMIT_SHA' } |
          '`component:` includes are not allowed in a bundled component'
        { remote: 'https://example.com/ci.yml' } | '`remote:` includes are not allowed in a bundled component'
        'https://example.com/ci.yml' | '`remote:` includes are not allowed in a bundled component'
        { project: 'group/project', file: 'ci.yml' } | '`project:` includes are not allowed in a bundled component'
        { template: 'Auto-DevOps.gitlab-ci.yml' } | '`template:` includes are not allowed in a bundled component'
        { artifact: 'generated.yml', job: 'build' } | '`artifact:` includes are not allowed in a bundled component'
      end

      with_them do
        let(:content) do
          entry = include_entry.is_a?(Hash) ? include_entry.stringify_keys : include_entry

          { 'include' => [entry] }.to_yaml
        end

        it 'rejects the include and does not return it' do
          expect(result.errors).to end_with_reasons(reason)
          expect(result.paths).to be_empty
        end
      end
    end

    context 'with an include that is neither a hash nor a string' do
      let(:content) { "include:\n  - 42" }

      it 'rejects the include' do
        expect(result.errors).to end_with_reasons('Each include must be a hash or a string')
      end
    end

    context 'with an include that has no known type' do
      let(:content) { "include:\n  - unknown: x.yml" }

      it 'rejects the include with the valid types' do
        expect(result.errors).to end_with_reasons(
          '`{"unknown":"x.yml"}` does not have a valid subkey for include. ' \
            'Valid subkeys are: `local`, `project`, `remote`, `template`, `artifact`, `component`'
        )
      end
    end

    context 'with a location only known when the pipeline runs' do
      where(:location) do
        ['templates/$TEMPLATE.yml', 'templates/${TEMPLATE}.yml', 'templates/$[[ inputs.lang ]].yml']
      end

      with_them do
        let(:content) { { 'include' => [{ 'local' => location }] }.to_yaml }

        it 'rejects the include' do
          expect(result.errors)
            .to end_with_reasons('the location is only known when the pipeline runs, so it cannot be collected')
        end
      end
    end

    context 'with a wildcard local location' do
      let(:content) { "include:\n  - local: 'templates/*.yml'" }

      it 'rejects the include' do
        expect(result.errors).to end_with_reasons('wildcard locations are not allowed in a bundled component')
      end
    end

    context 'with a local location without a YAML extension' do
      let(:content) { "include:\n  - local: 'README.md'" }

      it 'rejects the include' do
        expect(result.errors).to end_with_reasons('the file does not have a YAML extension')
      end
    end

    context 'with `rules:exists` that does not name a project' do
      where(:exists) do
        [
          [['tests/**/main.tftest.hcl']],
          [{ 'paths' => ['tests/**/main.tftest.hcl'] }],
          [{ 'regexp' => '\.tftest\.hcl\z' }]
        ]
      end

      with_them do
        let(:content) do
          { 'include' => [{ 'local' => 'templates/test.yml', 'rules' => [{ 'exists' => exists }] }] }.to_yaml
        end

        it 'rejects the include' do
          expect(result.errors).to end_with_reasons('`rules:exists` must name a `project:`, such as `$CI_PROJECT_PATH`')
        end
      end
    end

    context 'with a non-local include that also has `rules:exists` without a project' do
      let(:content) do
        { 'include' => [{ 'remote' => 'https://example.com/ci.yml', 'rules' => [{ 'exists' => ['a.yml'] }] }] }.to_yaml
      end

      it 'rejects only the include type' do
        expect(result.errors).to end_with_reasons('`remote:` includes are not allowed in a bundled component')
      end
    end

    context 'with `spec:include` in a header' do
      let(:content) do
        <<~YAML
          spec:
            include:
              - local: inputs.yml
          ---
          job:
            script: echo
        YAML
      end

      it 'rejects the file' do
        expect(result.errors).to end_with_reasons('`spec:include` is not allowed')
      end
    end

    context 'when the file does not exist' do
      let(:content) { nil }

      it 'rejects it' do
        expect(result.errors).to end_with_reasons('file does not exist')
        expect(result.paths).to be_empty
      end
    end

    context 'when the file is empty' do
      let(:content) { '' }

      it 'rejects it' do
        expect(result.errors).to end_with_reasons('file is empty')
      end
    end

    context 'with invalid YAML' do
      let(:content) { 'job: [unclosed' }

      it 'rejects the file' do
        expect(result.errors).to match([start_with('`templates/plan.yml`: invalid YAML:')])
      end
    end
  end
end
