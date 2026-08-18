# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Catalog::Bundle::Compiler, feature_category: :pipeline_composition do
  include RepoHelpers

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :repository) }

  let(:sha) { project.commit.sha }

  let(:child_content) do
    <<~YAML
      spec:
        inputs:
          message:
      ---
      child_job:
        script: echo "$[[ inputs.message ]]"
    YAML
  end

  let(:project_files) { { 'child.yml' => child_content } }

  let(:root_content) do
    <<~YAML
      spec:
        inputs:
          greeting:
      ---
      include:
        - local: child.yml
          inputs:
            message: $[[ inputs.greeting ]]
      top_job:
        script: echo "$[[ inputs.greeting ]]"
    YAML
  end

  subject(:compile) do
    described_class.new(content: root_content, project: project, sha: sha, current_user: user).compile
  end

  around do |example|
    create_and_delete_files(project, project_files) do
      example.run
    end
  end

  before_all do
    project.add_developer(user)
  end

  it 'resolves includes while preserving consumer-facing input markers', :aggregate_failures do
    documents = YAML.load_stream(compile)
    spec_doc = documents.find { |doc| doc.is_a?(Hash) && doc.key?('spec') }
    body = documents.find { |doc| doc.is_a?(Hash) && !doc.key?('spec') }

    expect(spec_doc.dig('spec', 'inputs')).to have_key('greeting')
    expect(body).not_to have_key('include')
    expect(body.dig('top_job', 'script')).to eq('echo "$[[ inputs.greeting ]]"')
    expect(body.dig('child_job', 'script')).to eq('echo "$[[ inputs.greeting ]]"')
  end

  context 'when a forbidden include type is nested in a transitively-included file' do
    let(:child_content) do
      <<~YAML
        include:
          - remote: https://example.com/anything.yml
        child_job:
          script: echo "hello"
      YAML
    end

    let(:root_content) do
      <<~YAML
        include:
          - local: child.yml
        top_job:
          script: echo "hello"
      YAML
    end

    it 'rejects the compile and names the forbidden type' do
      expect { compile }.to raise_error(described_class::CompileError, /`remote` includes are not allowed/)
    end
  end

  context 'when no compile identity is given' do
    subject(:compile) do
      described_class.new(content: root_content, project: project, sha: sha, current_user: nil).compile
    end

    it 'raises a CompileError' do
      expect { compile }.to raise_error(described_class::CompileError, /identity is required/)
    end
  end

  context 'when the component uses extends and !reference' do
    let(:root_content) do
      <<~YAML
        spec:
          inputs:
            greeting:
        ---
        .setup:
          script: echo "$[[ inputs.greeting ]]"
        build:
          extends: .setup
        test:
          script:
            - !reference [.setup, script]
            - echo run
      YAML
    end

    it 'resolves extends and !reference at compile into a flattened closed unit', :aggregate_failures do
      output = compile
      body = YAML.load_stream(output).find { |doc| doc.is_a?(Hash) && !doc.key?('spec') }

      expect(output).not_to include('!reference')
      expect(body.dig('build', 'script')).to eq('echo "$[[ inputs.greeting ]]"')
      expect(body.dig('test', 'script')).to eq(['echo "$[[ inputs.greeting ]]"', 'echo run'])
    end
  end

  context 'when extends names a base that does not exist' do
    let(:root_content) do
      <<~YAML
        build:
          extends: .missing
          script: echo "hello"
      YAML
    end

    it 'raises a CompileError' do
      expect { compile }.to raise_error(described_class::CompileError, /unknown keys in `extends`/)
    end
  end

  context 'when !reference points at a location that does not exist' do
    let(:root_content) do
      <<~YAML
        test:
          script:
            - !reference [.missing, script]
      YAML
    end

    it 'raises a CompileError' do
      expect { compile }.to raise_error(described_class::CompileError, /could not be found/)
    end
  end
end
