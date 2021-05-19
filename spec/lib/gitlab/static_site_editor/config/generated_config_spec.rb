# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::StaticSiteEditor::Config::GeneratedConfig do
  subject(:config) { described_class.new(repository, ref, path, return_url) }

  let_it_be(:namespace) { create(:namespace, name: 'namespace') }
  let_it_be(:root_group) { create(:group, name: 'group') }
  let_it_be(:subgroup) { create(:group, name: 'subgroup', parent: root_group) }
  let_it_be(:project) { create(:project, :public, :repository, name: 'project', namespace: namespace) }
  let_it_be(:project_with_subgroup) { create(:project, :public, :repository, name: 'project', group: subgroup) }
  let_it_be(:repository) { project.repository }

  let(:ref) { 'master' }
  let(:path) { 'README.md' }
  let(:return_url) { 'http://example.com' }

  describe '#data' do
    subject { config.data }

    it 'returns data for the frontend component' do
      is_expected
        .to match({
                    branch: 'master',
                    commit_id: repository.commit.id,
                    namespace: 'namespace',
                    path: 'README.md',
                    project: 'project',
                    project_id: project.id,
                    return_url: 'http://example.com',
                    is_supported_content: true,
                    base_url: '/namespace/project/-/sse/master%2FREADME.md',
                    merge_requests_illustration_path: %r{illustrations/merge_requests}
                  })
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
      before do
        repository.create_file(
          project.creator,
          path,
          '',
          message: 'message',
          branch_name: ref
        )
      end

      let(:ref) { 'main' }
      let(:path) { 'README.md.erb' }

      it { is_expected.to include(branch: ref, is_supported_content: true) }
    end

    context 'when file path is nested' do
      let(:path) { 'lib/README.md' }

      it { is_expected.to include(base_url: '/namespace/project/-/sse/master%2Flib%2FREADME.md') }
    end

    context 'when branch is not master or main' do
      let(:ref) { 'my-branch' }

      it { is_expected.to include(is_supported_content: false) }
    end

    context 'when file does not have a markdown extension' do
      let(:path) { 'README.txt' }

      it { is_expected.to include(is_supported_content: false) }
    end

    context 'when file does not have an extension' do
      let(:path) { 'README' }

      it { is_expected.to include(is_supported_content: false) }
    end

    context 'when file does not exist' do
      let(:path) { 'UNKNOWN.md' }

      it { is_expected.to include(is_supported_content: false) }
    end

    context 'when repository is empty' do
      let(:repository) { create(:project_empty_repo).repository }

      it { is_expected.to include(is_supported_content: false) }
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

    context 'when a commit for the ref cannot be found' do
      let(:ref) { 'nonexistent-ref' }

      it { is_expected.to include(commit_id: nil) }
    end
  end
end
