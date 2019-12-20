# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Pipeline::Chain::Config::Content do
  let(:project) { create(:project, ci_config_path: ci_config_path) }
  let(:pipeline) { build(:ci_pipeline, project: project) }
  let(:command) { Gitlab::Ci::Pipeline::Chain::Command.new(project: project) }

  subject { described_class.new(pipeline, command) }

  describe '#perform!' do
    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(ci_root_config_content: false)
      end

      context 'when config is defined in a custom path in the repository' do
        let(:ci_config_path) { 'path/to/config.yml' }

        before do
          expect(project.repository)
            .to receive(:gitlab_ci_yml_for)
            .with(pipeline.sha, ci_config_path)
            .and_return('the-content')
        end

        it 'returns the content of the YAML file' do
          subject.perform!

          expect(pipeline.config_source).to eq 'repository_source'
          expect(command.config_content).to eq('the-content')
        end
      end

      context 'when config is defined remotely' do
        let(:ci_config_path) { 'http://example.com/path/to/ci/config.yml' }

        it 'does not support URLs and default to AutoDevops' do
          subject.perform!

          expect(pipeline.config_source).to eq 'auto_devops_source'
          template = Gitlab::Template::GitlabCiYmlTemplate.find('Auto-DevOps')
          expect(command.config_content).to eq(template.content)
        end
      end

      context 'when config is defined in a separate repository' do
        let(:ci_config_path) { 'path/to/.gitlab-ci.yml@another-group/another-repo' }

        it 'does not support YAML from external repository and default to AutoDevops' do
          subject.perform!

          expect(pipeline.config_source).to eq 'auto_devops_source'
          template = Gitlab::Template::GitlabCiYmlTemplate.find('Auto-DevOps')
          expect(command.config_content).to eq(template.content)
        end
      end

      context 'when config is defined in the default .gitlab-ci.yml' do
        let(:ci_config_path) { nil }

        before do
          expect(project.repository)
            .to receive(:gitlab_ci_yml_for)
            .with(pipeline.sha, '.gitlab-ci.yml')
            .and_return('the-content')
        end

        it 'returns the content of the canonical config file' do
          subject.perform!

          expect(pipeline.config_source).to eq 'repository_source'
          expect(command.config_content).to eq('the-content')
        end
      end

      context 'when config is the Auto-Devops template' do
        let(:ci_config_path) { nil }

        before do
          expect(project).to receive(:auto_devops_enabled?).and_return(true)
        end

        it 'returns the content of AutoDevops template' do
          subject.perform!

          expect(pipeline.config_source).to eq 'auto_devops_source'
          template = Gitlab::Template::GitlabCiYmlTemplate.find('Auto-DevOps')
          expect(command.config_content).to eq(template.content)
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
          expect(command.config_content).to be_nil
          expect(pipeline.errors.full_messages).to include('Missing CI config file')
        end
      end
    end

    context 'when config is defined in a custom path in the repository' do
      let(:ci_config_path) { 'path/to/config.yml' }

      before do
        expect(project.repository)
          .to receive(:gitlab_ci_yml_for)
          .with(pipeline.sha, ci_config_path)
          .and_return('the-content')
      end

      it 'builds root config including the local custom file' do
        subject.perform!

        expect(pipeline.config_source).to eq 'repository_source'
        expect(command.config_content).to eq(<<~EOY)
          ---
          include:
          - local: #{ci_config_path}
        EOY
      end
    end

    context 'when config is defined remotely' do
      let(:ci_config_path) { 'http://example.com/path/to/ci/config.yml' }

      it 'builds root config including the remote config' do
        subject.perform!

        expect(pipeline.config_source).to eq 'remote_source'
        expect(command.config_content).to eq(<<~EOY)
          ---
          include:
          - remote: #{ci_config_path}
        EOY
      end
    end

    context 'when config is defined in a separate repository' do
      let(:ci_config_path) { 'path/to/.gitlab-ci.yml@another-group/another-repo' }

      it 'builds root config including the path to another repository' do
        subject.perform!

        expect(pipeline.config_source).to eq 'external_project_source'
        expect(command.config_content).to eq(<<~EOY)
          ---
          include:
          - project: another-group/another-repo
            file: path/to/.gitlab-ci.yml
        EOY
      end
    end

    context 'when config is defined in the default .gitlab-ci.yml' do
      let(:ci_config_path) { nil }

      before do
        expect(project.repository)
          .to receive(:gitlab_ci_yml_for)
          .with(pipeline.sha, '.gitlab-ci.yml')
          .and_return('the-content')
      end

      it 'builds root config including the canonical CI config file' do
        subject.perform!

        expect(pipeline.config_source).to eq 'repository_source'
        expect(command.config_content).to eq(<<~EOY)
          ---
          include:
          - local: ".gitlab-ci.yml"
        EOY
      end
    end

    context 'when config is the Auto-Devops template' do
      let(:ci_config_path) { nil }

      before do
        expect(project).to receive(:auto_devops_enabled?).and_return(true)
      end

      it 'builds root config including the auto-devops template' do
        subject.perform!

        expect(pipeline.config_source).to eq 'auto_devops_source'
        expect(command.config_content).to eq(<<~EOY)
          ---
          include:
          - template: Auto-DevOps.gitlab-ci.yml
        EOY
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
        expect(command.config_content).to be_nil
        expect(pipeline.errors.full_messages).to include('Missing CI config file')
      end
    end
  end
end
