# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Config::Content, feature_category: :continuous_integration do
  let(:project) { create(:project, ci_config_path: ci_config_path) }
  let(:pipeline) { build(:ci_pipeline, project: project) }
  let(:content) { nil }
  let(:source) { :push }
  let(:command) { Gitlab::Ci::Pipeline::Chain::Command.new(project: project, content: content, source: source) }

  subject { described_class.new(pipeline, command) }

  describe '#perform!' do
    context 'when bridge job is passed in as parameter' do
      let(:ci_config_path) { nil }
      let(:bridge) { create(:ci_bridge) }

      before do
        command.bridge = bridge
        allow(bridge).to receive(:yaml_for_downstream).and_return('the-yaml')
      end

      it 'returns the content already available in command' do
        subject.perform!

        expect(pipeline.config_source).to eq 'bridge_source'
        expect(command.config_content).to eq 'the-yaml'
        expect(command.pipeline_config.internal_include_prepended?).to eq(true)
      end
    end

    context 'when config is defined in a custom path in the repository' do
      let(:ci_config_path) { 'path/to/config.yml' }
      let(:config_content_result) do
        <<~EOY
          ---
          include:
          - local: #{ci_config_path}
        EOY
      end

      before do
        expect(project.repository)
          .to receive(:blob_at)
          .with(pipeline.sha, ci_config_path)
          .and_return(instance_double(Blob, empty?: false))
      end

      it 'builds root config including the local custom file' do
        subject.perform!

        expect(pipeline.config_source).to eq 'repository_source'
        expect(pipeline.pipeline_config.content).to eq(config_content_result)
        expect(command.config_content).to eq(config_content_result)
        expect(command.pipeline_config.internal_include_prepended?).to eq(true)
      end
    end

    context 'when config is defined remotely' do
      let(:ci_config_path) { 'http://example.com/path/to/ci/config.yml' }
      let(:config_content_result) do
        <<~EOY
          ---
          include:
          - remote: #{ci_config_path}
        EOY
      end

      it 'builds root config including the remote config' do
        subject.perform!

        expect(pipeline.config_source).to eq 'remote_source'
        expect(pipeline.pipeline_config.content).to eq(config_content_result)
        expect(command.config_content).to eq(config_content_result)
        expect(command.pipeline_config.internal_include_prepended?).to eq(true)
      end
    end

    context 'when config is defined in a separate repository' do
      let(:ci_config_path) { 'path/to/.gitlab-ci.yml@another-group/another-repo' }
      let(:config_content_result) do
        <<~EOY
          ---
          include:
          - project: another-group/another-repo
            file: path/to/.gitlab-ci.yml
        EOY
      end

      it 'builds root config including the path to another repository' do
        subject.perform!

        expect(pipeline.config_source).to eq 'external_project_source'
        expect(pipeline.pipeline_config.content).to eq(config_content_result)
        expect(command.config_content).to eq(config_content_result)
        expect(command.pipeline_config.internal_include_prepended?).to eq(true)
      end

      context 'when path specifies a refname' do
        let(:ci_config_path) { 'path/to/.gitlab-ci.yml@another-group/another-repo:refname' }
        let(:config_content_result) do
          <<~EOY
            ---
            include:
            - project: another-group/another-repo
              file: path/to/.gitlab-ci.yml
              ref: refname
          EOY
        end

        it 'builds root config including the path and refname to another repository' do
          subject.perform!

          expect(pipeline.config_source).to eq 'external_project_source'
          expect(pipeline.pipeline_config.content).to eq(config_content_result)
          expect(command.config_content).to eq(config_content_result)
          expect(command.pipeline_config.internal_include_prepended?).to eq(true)
        end
      end
    end

    context 'when config is defined in the default .gitlab-ci.yml' do
      let(:ci_config_path) { nil }
      let(:config_content_result) do
        <<~EOY
          ---
          include:
          - local: ".gitlab-ci.yml"
        EOY
      end

      before do
        expect(project.repository)
          .to receive(:blob_at)
          .with(pipeline.sha, '.gitlab-ci.yml')
          .and_return(instance_double(Blob, empty?: false))
      end

      it 'builds root config including the canonical CI config file' do
        subject.perform!

        expect(pipeline.config_source).to eq 'repository_source'
        expect(pipeline.pipeline_config.content).to eq(config_content_result)
        expect(command.config_content).to eq(config_content_result)
        expect(command.pipeline_config.internal_include_prepended?).to eq(true)
      end
    end

    context 'when config is the Auto-Devops template' do
      let(:ci_config_path) { nil }
      let(:config_content_result) do
        <<~EOY
          ---
          include:
          - template: Auto-DevOps.gitlab-ci.yml
        EOY
      end

      before do
        expect(project).to receive(:auto_devops_enabled?).and_return(true)
      end

      it 'builds root config including the auto-devops template' do
        subject.perform!

        expect(pipeline.config_source).to eq 'auto_devops_source'
        expect(pipeline.pipeline_config.content).to eq(config_content_result)
        expect(command.config_content).to eq(config_content_result)
        expect(command.pipeline_config.internal_include_prepended?).to eq(true)
      end
    end

    context 'when config is passed as a parameter' do
      let(:source) { :ondemand_dast_scan }
      let(:ci_config_path) { nil }
      let(:content) do
        <<~EOY
          ---
          stages:
          - dast
        EOY
      end

      it 'uses the parameter content' do
        subject.perform!

        expect(pipeline.config_source).to eq 'parameter_source'
        expect(pipeline.pipeline_config.content).to eq(content)
        expect(command.config_content).to eq(content)
        expect(command.pipeline_config.internal_include_prepended?).to eq(false)
      end
    end

    context 'when config is not defined anywhere' do
      let(:ci_config_path) { nil }

      before do
        expect(project).to receive(:auto_devops_enabled?).and_return(false)
      end

      it 'builds root config including the auto-devops template' do
        subject.perform!

        expect(pipeline.config_source).to eq('unknown_source')
        expect(pipeline.pipeline_config).to be_nil
        expect(command.config_content).to be_nil
        expect(command.pipeline_config).to be_nil
        expect(pipeline.errors.full_messages).to include('Missing CI config file')
      end
    end
  end
end
