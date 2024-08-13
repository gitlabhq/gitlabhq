# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::ProjectConfig::ProjectSetting, feature_category: :pipeline_composition do
  let(:project) { create(:project, :custom_repo, files: files) }
  let(:sha) { project.repository.head_commit.sha }
  let(:files) { { 'README.md' => 'hello' } }
  let(:config_path) { nil }

  before do
    project.ci_config_path = config_path
  end

  subject(:config) do
    described_class.new(project: project, sha: sha)
  end

  describe '#content' do
    subject(:content) { config.content }

    context 'when file is in repository' do
      let(:config_content_result) do
        <<~CICONFIG
        ---
        include:
        - local: ".gitlab-ci.yml"
        CICONFIG
      end

      let(:files) { { '.gitlab-ci.yml' => 'content' } }

      it { is_expected.to eq(config_content_result) }
    end

    context 'with external config' do
      let(:config_path) { 'path/to/.gitlab-ci.yml@another-group/another-project' }

      let(:config_content_result) do
        <<~CICONFIG
        ---
        include:
        - project: another-group/another-project
          file: path/to/.gitlab-ci.yml
        CICONFIG
      end

      it { is_expected.to eq(config_content_result) }
    end

    context 'with remote config' do
      let(:config_path) { 'http://example.com/path/to/ci/config.yml' }
      let(:config_content_result) do
        <<~CICONFIG
          ---
          include:
          - remote: #{config_path}
        CICONFIG
      end

      it { is_expected.to eq(config_content_result) }
    end

    context 'when file is not in repository' do
      it { is_expected.to be_nil }
    end

    context 'when Gitaly raises error' do
      before do
        allow(project.repository).to receive(:blob_at).and_raise(GRPC::Internal)
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#source' do
    subject { config.source }

    it { is_expected.to eq(nil) }

    context 'with repository config' do
      let(:files) { { '.gitlab-ci.yml' => 'content' } }

      it { is_expected.to eq(:repository_source) }
    end

    context 'with external config' do
      let(:config_path) { 'path/to/.gitlab-ci.yml@another-group/another-project' }

      it { is_expected.to eq(:external_project_source) }
    end

    context 'with remote config' do
      let(:config_path) { 'http://example.com/path/to/ci/config.yml' }

      it { is_expected.to eq(:remote_source) }
    end
  end

  describe '#internal_include_prepended?' do
    subject { config.internal_include_prepended? }

    it { is_expected.to eq(true) }
  end
end
