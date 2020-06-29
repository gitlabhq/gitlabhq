# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::StaticSiteEditor::Config do
  subject(:config) { described_class.new(repository, ref, file_path, return_url) }

  let_it_be(:namespace) { create(:namespace, name: 'namespace') }
  let_it_be(:root_group) { create(:group, name: 'group') }
  let_it_be(:subgroup) { create(:group, name: 'subgroup', parent: root_group) }
  let_it_be(:project) { create(:project, :public, :repository, name: 'project', namespace: namespace) }
  let_it_be(:project_with_subgroup) { create(:project, :public, :repository, name: 'project', group: subgroup) }
  let_it_be(:repository) { project.repository }

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
        is_supported_content: 'true',
        base_url: '/namespace/project/-/sse/master%2FREADME.md'
      )
    end

    context 'when namespace is a subgroup' do
      let(:repository) { project_with_subgroup.repository }

      it 'returns data for the frontend component' do
        is_expected.to include(
          namespace: 'group/subgroup',
          project: 'project',
          base_url: '/group/subgroup/project/-/sse/master%2FREADME.md'
        )
      end
    end

    context 'when file has .md.erb extension' do
      let(:file_path) { 'README.md.erb' }

      before do
        repository.create_file(
          project.creator,
          file_path,
          '',
          message: 'message',
          branch_name: 'master'
        )
      end

      it { is_expected.to include(is_supported_content: 'true') }
    end

    context 'when file path is nested' do
      let(:file_path) { 'lib/README.md' }

      it { is_expected.to include(base_url: '/namespace/project/-/sse/master%2Flib%2FREADME.md') }
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
      let(:repository) { create(:project_empty_repo).repository }

      it { is_expected.to include(is_supported_content: 'false') }
    end

    context 'when return_url is not a valid URL' do
      let(:return_url) { 'example.com' }

      it { is_expected.to include(return_url: nil) }
    end

    context 'when return_url has a javascript scheme' do
      let(:return_url) { 'javascript:alert(document.domain)' }

      it { is_expected.to include(return_url: nil) }
    end

    context 'when return_url is missing' do
      let(:return_url) { nil }

      it { is_expected.to include(return_url: nil) }
    end
  end
end
