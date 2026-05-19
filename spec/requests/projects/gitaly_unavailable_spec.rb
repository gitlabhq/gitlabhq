# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Gitaly unavailable graceful degradation', feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user) { create(:user) }

  before_all do
    project.add_maintainer(user)
  end

  before do
    sign_in(user)
  end

  describe 'Projects::BlobController' do
    describe '#show' do
      let(:make_request) { get project_blob_path(project, 'master/README.md') }

      let(:allow_gitaly_to_raise_error) do
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:blob_at)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      it_behaves_like 'handles Gitaly errors for request specs'

      context 'with JSON format' do
        let(:make_request) { get project_blob_path(project, 'master/README.md', format: :json) }

        it_behaves_like 'handles Gitaly errors for json format'
      end
    end

    describe '#new' do
      let(:make_request) { get project_new_blob_path(project, 'master') }

      let(:allow_gitaly_to_raise_error) do
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:commit)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      it_behaves_like 'handles Gitaly errors for request specs'
    end

    describe '#edit' do
      let(:make_request) do
        get namespace_project_edit_blob_path(
          namespace_id: project.namespace,
          project_id: project,
          id: 'master/README.md'
        )
      end

      let(:allow_gitaly_to_raise_error) do
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:blob_at)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      it_behaves_like 'handles Gitaly errors for request specs'
    end

    describe '#diff' do
      let(:make_request) do
        get namespace_project_blob_diff_path(
          namespace_id: project.namespace,
          project_id: project,
          id: 'master/CHANGELOG',
          since: 1,
          to: 5,
          offset: 10
        )
      end

      let(:allow_gitaly_to_raise_error) do
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:blob_at)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      it_behaves_like 'handles Gitaly errors for request specs'
    end

    describe '#preview' do
      let(:make_request) do
        post namespace_project_preview_blob_path(
          namespace_id: project.namespace,
          project_id: project,
          id: 'master/README.md'
        ), params: { content: 'test' }
      end

      let(:allow_gitaly_to_raise_error) do
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:blob_at)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      it_behaves_like 'handles Gitaly errors for request specs'
    end
  end

  describe 'Projects::CommitController' do
    let(:commit) { project.commit('master') }

    describe '#show' do
      let(:allow_gitaly_to_raise_error) do
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:commit_by)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      context 'with rapid_diffs_on_commit_show disabled (legacy view)' do
        before do
          stub_feature_flags(rapid_diffs_on_commit_show: false)
        end

        let(:make_request) { get project_commit_path(project, commit.id) }

        it_behaves_like 'handles Gitaly errors for request specs'

        context 'with JSON format' do
          let(:make_request) { get project_commit_path(project, commit.id, format: :json) }

          it_behaves_like 'handles Gitaly errors for json format'
        end
      end

      context 'with rapid_diffs_on_commit_show enabled (rapid diffs view)' do
        before do
          stub_feature_flags(rapid_diffs_on_commit_show: true)
        end

        let(:make_request) { get project_commit_path(project, commit.id) }

        it_behaves_like 'handles Gitaly errors for request specs'

        context 'with JSON format' do
          let(:make_request) { get project_commit_path(project, commit.id, format: :json) }

          it_behaves_like 'handles Gitaly errors for json format'
        end
      end
    end

    describe '#diff_for_path' do
      let(:make_request) do
        get diff_for_path_project_commit_path(
          project,
          commit.id,
          old_path: 'README.md',
          new_path: 'README.md',
          format: :json
        )
      end

      let(:allow_gitaly_to_raise_error) do
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:commit_by)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      it_behaves_like 'handles Gitaly errors for json format'
    end

    describe '#pipelines' do
      let(:make_request) { get pipelines_project_commit_path(project, commit.id) }

      let(:allow_gitaly_to_raise_error) do
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:commit_by)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      it_behaves_like 'handles Gitaly errors for request specs'
    end

    describe '#diff_files' do
      let(:make_request) { get diff_files_project_commit_path(project, commit.id) }

      let(:allow_gitaly_to_raise_error) do
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:commit_by)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      it_behaves_like 'handles Gitaly errors for request specs'
    end

    describe '#discussions' do
      let(:make_request) { get discussions_project_commit_path(project, commit.id, format: :json) }

      let(:allow_gitaly_to_raise_error) do
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:commit_by)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      it_behaves_like 'handles Gitaly errors for json format'
    end

    describe '#merge_requests' do
      let(:make_request) { get merge_requests_project_commit_path(project, commit.id, format: :json) }

      let(:allow_gitaly_to_raise_error) do
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:commit_by)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      it_behaves_like 'handles Gitaly errors for json format'
    end
  end

  describe 'Projects::RawController' do
    describe '#show' do
      let(:make_request) { get project_raw_path(project, 'master/README.md') }

      let(:allow_gitaly_to_raise_error) do
        allow_next_instance_of(Gitlab::Git::Repository) do |repository|
          allow(repository).to receive(:blob_at)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      it_behaves_like 'handles Gitaly errors for request specs'
    end
  end

  describe 'Projects::BlameController' do
    describe '#show' do
      let(:make_request) { get project_blame_path(project, 'master/README.md') }

      let(:allow_gitaly_to_raise_error) do
        allow(Gitlab::Git::Commit).to receive(:find)
          .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
      end

      it_behaves_like 'handles Gitaly errors for request specs'
    end

    describe '#streaming' do
      let(:make_request) do
        get namespace_project_blame_streaming_path(
          namespace_id: project.namespace,
          project_id: project,
          id: 'master/README.md'
        )
      end

      let(:allow_gitaly_to_raise_error) do
        allow(Gitlab::Git::Commit).to receive(:find)
          .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
      end

      it_behaves_like 'handles Gitaly errors for request specs'
    end

    describe '#page' do
      let(:make_request) do
        get namespace_project_blame_page_path(
          namespace_id: project.namespace,
          project_id: project,
          id: 'master/README.md'
        )
      end

      let(:allow_gitaly_to_raise_error) do
        allow(Gitlab::Git::Commit).to receive(:find)
          .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
      end

      it_behaves_like 'handles Gitaly errors for request specs'
    end
  end

  describe 'Projects::CommitsController' do
    describe '#show' do
      let(:allow_gitaly_to_raise_error) do
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:commits)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      context 'with HTML format' do
        let(:make_request) { get project_commits_path(project, 'master') }

        it_behaves_like 'handles Gitaly errors for request specs'
      end

      context 'with JSON format' do
        let(:make_request) { get project_commits_path(project, 'master', format: :json) }

        it_behaves_like 'handles Gitaly errors for json format'
      end

      context 'with Atom format' do
        let(:make_request) { get project_commits_path(project, 'master', format: :atom) }

        it_behaves_like 'handles Gitaly errors for request specs'
      end
    end

    describe '#signatures' do
      let(:make_request) do
        get namespace_project_signatures_path(namespace_id: project.namespace, project_id: project, id: 'master',
          format: :json)
      end

      let(:allow_gitaly_to_raise_error) do
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:commits)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      it_behaves_like 'handles Gitaly errors for json format'
    end
  end

  describe 'Projects::TreeController' do
    describe '#show' do
      let(:make_request) { get project_tree_path(project, 'master') }

      let(:allow_gitaly_to_raise_error) do
        allow(Gitlab::Git::Commit).to receive(:find)
          .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
      end

      it_behaves_like 'handles Gitaly errors for request specs'
    end
  end

  describe 'Projects::BranchesController' do
    describe '#index' do
      let(:allow_gitaly_to_raise_error) do
        allow_next_instance_of(Gitlab::GitalyClient::RefService) do |ref_service|
          allow(ref_service).to receive(:local_branches)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      context 'with HTML format' do
        let(:make_request) { get project_branches_path(project) }

        it_behaves_like 'handles Gitaly errors for request specs'
      end

      context 'with JSON format' do
        let(:make_request) { get project_branches_path(project, format: :json) }

        it_behaves_like 'handles Gitaly errors for json format'
      end
    end

    describe '#diverging_commit_counts' do
      let(:make_request) do
        get diverging_commit_counts_namespace_project_branches_path(
          namespace_id: project.namespace,
          project_id: project,
          names: %w[fix],
          format: :json
        )
      end

      let(:allow_gitaly_to_raise_error) do
        allow_next_instance_of(Gitlab::Git::Finders::RefsFinder) do |finder|
          allow(finder).to receive(:execute)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      it_behaves_like 'handles Gitaly errors for json format'
    end
  end

  describe 'Projects::TagsController' do
    describe '#index' do
      let(:allow_gitaly_to_raise_error) do
        allow_next_instance_of(TagsFinder) do |finder|
          allow(finder).to receive(:execute)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      context 'with HTML format' do
        let(:make_request) { get project_tags_path(project) }

        it_behaves_like 'handles Gitaly errors for request specs'
      end

      context 'with Atom format' do
        let(:make_request) { get project_tags_path(project, format: :atom) }

        it_behaves_like 'handles Gitaly errors for request specs'
      end
    end

    describe '#show' do
      let(:make_request) { get project_tag_path(project, 'v1.0.0') }

      let(:allow_gitaly_to_raise_error) do
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:find_tag)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      it_behaves_like 'handles Gitaly errors for request specs'
    end
  end

  describe 'Projects::CompareController' do
    describe '#show' do
      let(:make_request) { get project_compare_path(project, from: 'master', to: 'feature') }

      let(:allow_gitaly_to_raise_error) do
        allow_next_instance_of(CompareService) do |service|
          allow(service).to receive(:execute)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      it_behaves_like 'handles Gitaly errors for request specs'

      it 'renders the gitaly unavailable error message' do
        allow_gitaly_to_raise_error

        make_request

        expect(response.body).to include('Unable to compare revisions')
        expect(response.body).to include('The git server, Gitaly, is not available at this time')
      end

      context 'when error is raised from Repository level' do
        let(:allow_gitaly_to_raise_error) do
          allow_next_instance_of(Repository) do |repository|
            allow(repository).to receive(:compare_source_branch)
              .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
          end
        end

        it 'still renders the gitaly unavailable error message' do
          allow_gitaly_to_raise_error

          make_request

          expect(response).to have_gitlab_http_status(:service_unavailable)
          expect(response.body).to include('Unable to compare revisions')
        end
      end

      context 'when Gitaly health check fails (compare returns nil)' do
        let(:allow_gitaly_to_raise_error) do
          # Simulate CompareService returning nil (as it does when Commit.find swallows errors)
          allow_next_instance_of(CompareService) do |service|
            allow(service).to receive(:execute).and_return(nil)
          end

          # Simulate Gitaly health check failing
          allow_next_instance_of(Gitlab::GitalyClient::HealthCheckService) do |service|
            allow(service).to receive(:check).and_return({ success: false, message: 'Gitaly unavailable' })
          end
        end

        it 'renders the gitaly unavailable error message' do
          allow_gitaly_to_raise_error

          make_request

          expect(response).to have_gitlab_http_status(:service_unavailable)
          expect(response.body).to include('Unable to compare revisions')
        end
      end
    end

    describe '#signatures' do
      let(:make_request) do
        get signatures_namespace_project_compare_index_path(namespace_id: project.namespace, project_id: project,
          from: 'master', to: 'feature', format: :json)
      end

      let(:allow_gitaly_to_raise_error) do
        allow_next_instance_of(CompareService) do |service|
          allow(service).to receive(:execute)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      it_behaves_like 'handles Gitaly errors for json format'
    end

    describe '#diff_for_path' do
      let(:make_request) do
        get diff_for_path_namespace_project_compare_index_path(
          namespace_id: project.namespace,
          project_id: project,
          from: 'master',
          to: 'feature',
          old_path: 'README.md',
          new_path: 'README.md',
          format: :json
        )
      end

      let(:allow_gitaly_to_raise_error) do
        allow_next_instance_of(CompareService) do |service|
          allow(service).to receive(:execute)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      it_behaves_like 'handles Gitaly errors for json format'
    end
  end

  describe 'Projects::GraphsController' do
    describe '#show' do
      let(:make_request) do
        get namespace_project_graph_path(namespace_id: project.namespace, project_id: project, id: 'master')
      end

      let(:allow_gitaly_to_raise_error) do
        allow(Gitlab::Git::Commit).to receive(:find)
          .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
      end

      it_behaves_like 'handles Gitaly errors for request specs'

      context 'with JSON format' do
        let(:make_request) do
          get namespace_project_graph_path(
            namespace_id: project.namespace, project_id: project, id: 'master', format: :json
          )
        end

        it_behaves_like 'handles Gitaly errors for json format'
      end
    end

    describe '#charts' do
      let(:make_request) do
        get charts_namespace_project_graph_path(namespace_id: project.namespace, project_id: project, id: 'master')
      end

      let(:allow_gitaly_to_raise_error) do
        allow(Gitlab::Git::Commit).to receive(:find)
          .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
      end

      it_behaves_like 'handles Gitaly errors for request specs'
    end
  end
end
