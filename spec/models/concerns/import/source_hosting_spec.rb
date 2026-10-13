# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::SourceHosting, feature_category: :importers do
  describe '#gitea_self_hosted_import?' do
    it 'is false for gitea.com' do
      project = build(:project, import_type: 'gitea', import_url: 'https://gitea.com/user/repo')
      expect(project.gitea_self_hosted_import?).to be false
    end

    it 'is false for a gitea.com subdomain' do
      project = build(:project, import_type: 'gitea', import_url: 'https://try.gitea.com/user/repo')
      expect(project.gitea_self_hosted_import?).to be false
    end

    it 'is true for a self-hosted gitea host' do
      project = build(:project, import_type: 'gitea', import_url: 'https://gitea.example.com/user/repo')
      expect(project.gitea_self_hosted_import?).to be true
    end

    it 'is false when import_type is not gitea' do
      project = build(:project, import_type: 'github', import_url: 'https://gitea.example.com/user/repo')
      expect(project.gitea_self_hosted_import?).to be false
    end

    it 'is false when the import URL is missing' do
      project = build(:project, import_type: 'gitea')
      expect(project.gitea_self_hosted_import?).to be false
    end

    it 'is false when the import URL cannot be parsed' do
      project = build(:project, import_type: 'gitea', import_url: 'https://gitea.com/user/repo')
      allow(project).to receive(:safe_import_url).and_return('http://[invalid')
      expect(project.gitea_self_hosted_import?).to be false
    end
  end

  describe '#source_hosting' do
    subject { build(:project, import_type: import_type, import_url: import_url).source_hosting }

    context 'when the github API endpoint' do
      let(:import_type) { 'github' }
      let(:import_url) { 'https://api.github.com/user/repo' }

      it { is_expected.to eq(described_class::CLOUD) }
    end

    context 'when github.com' do
      let(:import_type) { 'github' }
      let(:import_url) { 'https://github.com/user/repo' }

      it { is_expected.to eq(described_class::CLOUD) }
    end

    context 'when a github.com subdomain' do
      let(:import_type) { 'github' }
      let(:import_url) { 'https://assets.github.com/user/repo' }

      it { is_expected.to eq(described_class::CLOUD) }
    end

    context 'when github enterprise' do
      let(:import_type) { 'github' }
      let(:import_url) { 'https://ghe.example.com/user/repo' }

      it { is_expected.to eq(described_class::SELF_HOSTED) }
    end

    context 'when gitea.com' do
      let(:import_type) { 'gitea' }
      let(:import_url) { 'https://gitea.com/user/repo' }

      it { is_expected.to eq(described_class::CLOUD) }
    end

    context 'when a gitea.com subdomain' do
      let(:import_type) { 'gitea' }
      let(:import_url) { 'https://try.gitea.com/user/repo' }

      it { is_expected.to eq(described_class::CLOUD) }
    end

    context 'when self-hosted gitea' do
      let(:import_type) { 'gitea' }
      let(:import_url) { 'https://gitea.example.com/user/repo' }

      it { is_expected.to eq(described_class::SELF_HOSTED) }
    end

    context 'when github import without an import URL' do
      let(:import_type) { 'github' }
      let(:import_url) { nil }

      it { is_expected.to be_nil }
    end

    context 'when import URL cannot be parsed' do
      let(:project) { build(:project, import_type: 'github', import_url: 'https://github.com/user/repo') }

      subject { project.source_hosting }

      before do
        allow(project).to receive(:safe_import_url).and_return('http://[invalid')
      end

      it { is_expected.to be_nil }
    end

    context 'when a non-github/gitea importer' do
      let(:import_type) { 'bitbucket' }
      let(:import_url) { 'https://bitbucket.org/user/repo' }

      it { is_expected.to be_nil }
    end

    context 'when the project has no import' do
      subject { build(:project).source_hosting }

      it { is_expected.to be_nil }
    end
  end
end
