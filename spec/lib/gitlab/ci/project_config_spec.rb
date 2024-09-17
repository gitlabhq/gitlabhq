# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::ProjectConfig, feature_category: :pipeline_composition do
  let_it_be_with_reload(:project) { create(:project, :empty_repo) }
  let(:sha) { '123456' }
  let(:content) { nil }
  let(:source) { :push }
  let(:bridge) { nil }
  let(:triggered_for_branch) { true }
  let(:ref) { 'master' }

  subject(:config) do
    described_class.new(
      project: project,
      sha: sha,
      custom_content: content,
      pipeline_source: source,
      pipeline_source_bridge: bridge,
      triggered_for_branch: triggered_for_branch,
      ref: ref
    )
  end

  before do
    project.ci_config_path = ci_config_path
  end

  context 'when bridge job is passed in as parameter' do
    let(:ci_config_path) { nil }
    let(:bridge) { build_stubbed(:ci_bridge) }

    before do
      allow(bridge).to receive(:yaml_for_downstream).and_return('the-yaml')
    end

    it 'returns the content already available in command' do
      expect(config.source).to eq(:bridge_source)
      expect(config.content).to eq('the-yaml')
      expect(config.url).to be_nil
    end
  end

  context 'when config is defined in a custom path in the repository' do
    let(:ci_config_path) { 'path/to/config.yml' }
    let(:config_content_result) do
      <<~CICONFIG
        ---
        include:
        - local: #{ci_config_path}
      CICONFIG
    end

    before do
      allow(project.repository)
        .to receive(:blob_at)
        .with(sha, ci_config_path)
        .and_return(instance_double(Blob, empty?: false))
    end

    it 'returns root config including the local custom file' do
      expect(config.source).to eq(:repository_source)
      expect(config.content).to eq(config_content_result)
      expect(config.url).to eq("localhost/#{project.full_path}//path/to/config.yml")
    end
  end

  context 'when config is defined remotely' do
    let(:ci_config_path) { 'http://example.com/path/to/ci/config.yml' }
    let(:config_content_result) do
      <<~CICONFIG
        ---
        include:
        - remote: #{ci_config_path}
      CICONFIG
    end

    it 'returns root config including the remote config' do
      expect(config.source).to eq(:remote_source)
      expect(config.content).to eq(config_content_result)
      expect(config.url).to be_nil
    end
  end

  context 'when config is defined in a separate repository' do
    let(:ci_config_path) { 'path/to/.gitlab-ci.yml@another-group/another-repo' }
    let(:config_content_result) do
      <<~CICONFIG
        ---
        include:
        - project: another-group/another-repo
          file: path/to/.gitlab-ci.yml
      CICONFIG
    end

    it 'returns root config including the path to another repository' do
      expect(config.source).to eq(:external_project_source)
      expect(config.content).to eq(config_content_result)
      expect(config.url).to be_nil
    end

    context 'when path specifies a refname' do
      let(:ci_config_path) { 'path/to/.gitlab-ci.yml@another-group/another-repo:refname' }
      let(:config_content_result) do
        <<~CICONFIG
          ---
          include:
          - project: another-group/another-repo
            file: path/to/.gitlab-ci.yml
            ref: refname
        CICONFIG
      end

      it 'returns root config including the path and refname to another repository' do
        expect(config.source).to eq(:external_project_source)
        expect(config.content).to eq(config_content_result)
      end
    end
  end

  context 'when config is defined in the default .gitlab-ci.yml' do
    let(:ci_config_path) { nil }
    let(:config_content_result) do
      <<~CICONFIG
        ---
        include:
        - local: ".gitlab-ci.yml"
      CICONFIG
    end

    before do
      allow(project.repository)
        .to receive(:blob_at)
        .with(sha, '.gitlab-ci.yml')
        .and_return(instance_double(Blob, empty?: false))
    end

    it 'returns root config including the canonical CI config file' do
      expect(config.source).to eq(:repository_source)
      expect(config.content).to eq(config_content_result)
      expect(config.url).to eq("localhost/#{project.full_path}//.gitlab-ci.yml")
    end
  end

  context 'when config is the Auto-Devops template' do
    let(:ci_config_path) { nil }
    let(:config_content_result) do
      <<~CICONFIG
        ---
        include:
        - template: Auto-DevOps.gitlab-ci.yml
      CICONFIG
    end

    before do
      allow(project).to receive(:auto_devops_enabled?).and_return(true)
    end

    it 'returns root config including the auto-devops template' do
      expect(config.source).to eq(:auto_devops_source)
      expect(config.content).to eq(config_content_result)
      expect(config.url).to be_nil
    end
  end

  context 'when config is passed as a parameter' do
    let(:source) { :ondemand_dast_scan }
    let(:ci_config_path) { nil }
    let(:content) do
      <<~CICONFIG
        ---
        stages:
        - dast
      CICONFIG
    end

    it 'returns the parameter content' do
      expect(config.source).to eq(:parameter_source)
      expect(config.content).to eq(content)
      expect(config.url).to be_nil
    end
  end

  context 'when config is not defined anywhere' do
    let(:ci_config_path) { nil }

    before do
      allow(project).to receive(:auto_devops_enabled?).and_return(false)
    end

    it 'returns nil' do
      expect(config.source).to be_nil
      expect(config.content).to be_nil
      expect(config.url).to be_nil
    end
  end
end
