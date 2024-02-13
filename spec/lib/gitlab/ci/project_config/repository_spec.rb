# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::ProjectConfig::Repository, feature_category: :continuous_integration do
  let(:project) { create(:project, :custom_repo, files: files) }
  let(:sha) { project.repository.head_commit.sha }
  let(:files) { { 'README.md' => 'hello' } }

  subject(:config) do
    described_class.new(project, sha, nil, nil, nil,
      nil)
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

    it { is_expected.to eq(:repository_source) }
  end

  describe '#internal_include_prepended?' do
    subject { config.internal_include_prepended? }

    it { is_expected.to eq(true) }
  end
end
