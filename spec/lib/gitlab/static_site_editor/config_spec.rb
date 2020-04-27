# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::StaticSiteEditor::Config do
  subject(:config) { described_class.new(repository, ref, file_path, return_url) }

  let(:project) { create(:project, :public, :repository, name: 'project', namespace: namespace) }
  let(:namespace) { create(:namespace, name: 'namespace') }
  let(:repository) { project.repository }
  let(:ref) { 'master' }
  let(:file_path) { 'README.md' }
  let(:return_url) { 'http://example.com' }

  describe '#payload' do
    subject { config.payload }

    it 'returns data for the frontend component' do
      is_expected.to eq(
        branch: 'master',
        commit_id: repository.commit.id,
        namespace: 'namespace',
        path: 'README.md',
        project: 'project',
        project_id: project.id,
        return_url: 'http://example.com',
        is_supported_content: 'true'
      )
    end

    context 'when branch is not master' do
      let(:ref) { 'my-branch' }

      it { is_expected.to include(is_supported_content: 'false') }
    end

    context 'when file does not have a markdown extension' do
      let(:file_path) { 'README.txt' }

      it { is_expected.to include(is_supported_content: 'false') }
    end

    context 'when file does not have an extension' do
      let(:file_path) { 'README' }

      it { is_expected.to include(is_supported_content: 'false') }
    end

    context 'when file does not exist' do
      let(:file_path) { 'UNKNOWN.md' }

      it { is_expected.to include(is_supported_content: 'false') }
    end

    context 'when repository is empty' do
      let(:project) { create(:project_empty_repo) }

      it { is_expected.to include(is_supported_content: 'false') }
    end
  end
end
