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
      include_context 'when Repository#blob_at raises Gitaly error'

      let(:make_request) { get project_blob_path(project, 'master/README.md') }

      it_behaves_like 'handles Gitaly errors for request specs'

      context 'with JSON format' do
        let(:make_request) { get project_blob_path(project, 'master/README.md', format: :json) }

        it_behaves_like 'handles Gitaly errors for json format'
      end
    end

    describe '#new' do
      let(:make_request) { get project_new_blob_path(project, 'master') }

      # Unique stub: uses Repository#commit instead of #blob_at
      let(:allow_gitaly_to_raise_error) do
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:commit)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      it_behaves_like 'handles Gitaly errors for request specs'
    end

    describe '#edit' do
      include_context 'when Repository#blob_at raises Gitaly error'

      let(:make_request) do
        get namespace_project_edit_blob_path(
          namespace_id: project.namespace,
          project_id: project,
          id: 'master/README.md'
        )
      end

      it_behaves_like 'handles Gitaly errors for request specs'
    end

    describe '#diff' do
      include_context 'when Repository#blob_at raises Gitaly error'

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

      it_behaves_like 'handles Gitaly errors for request specs'
    end

    describe '#preview' do
      include_context 'when Repository#blob_at raises Gitaly error'

      let(:make_request) do
        post namespace_project_preview_blob_path(
          namespace_id: project.namespace,
          project_id: project,
          id: 'master/README.md'
        ), params: { content: 'test' }
      end

      it_behaves_like 'handles Gitaly errors for request specs'
    end
  end

  describe 'Projects::CommitController' do
    include_context 'when Repository#commit_by raises Gitaly error'

    let(:commit) { project.commit('master') }

    describe '#show' do
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

      it_behaves_like 'handles Gitaly errors for json format'
    end

    describe '#pipelines' do
      let(:make_request) { get pipelines_project_commit_path(project, commit.id) }

      it_behaves_like 'handles Gitaly errors for request specs'
    end

    describe '#diff_files' do
      let(:make_request) { get diff_files_project_commit_path(project, commit.id) }

      it_behaves_like 'handles Gitaly errors for request specs'
    end

    describe '#discussions' do
      let(:make_request) { get discussions_project_commit_path(project, commit.id, format: :json) }

      it_behaves_like 'handles Gitaly errors for json format'
    end

    describe '#merge_requests' do
      let(:make_request) { get merge_requests_project_commit_path(project, commit.id, format: :json) }

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

  describe 'Projects::AvatarsController' do
    include_context 'when Repository#blob_at_branch raises Gitaly error'

    describe '#show' do
      let(:make_request) do
        get namespace_project_avatar_path(namespace_id: project.namespace, project_id: project)
      end

      it_behaves_like 'handles Gitaly errors for request specs'
    end
  end

  describe 'Projects::BlameController' do
    include_context 'when Gitlab::Git::Commit.find raises Gitaly error'

    describe '#show' do
      let(:make_request) { get project_blame_path(project, 'master/README.md') }

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

      it_behaves_like 'handles Gitaly errors for request specs'
    end
  end

  describe 'Projects::CommitsController' do
    include_context 'when Repository#commits raises Gitaly error'

    describe '#show' do
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

      it_behaves_like 'handles Gitaly errors for json format'
    end
  end

  describe 'Projects::TreeController' do
    include_context 'when Gitlab::Git::Commit.find raises Gitaly error'

    describe '#show' do
      let(:make_request) { get project_tree_path(project, 'master') }

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
      include_context 'when CompareService#execute raises Gitaly error'

      let(:make_request) { get project_compare_path(project, from: 'master', to: 'feature') }

      it_behaves_like 'handles Gitaly errors for request specs'

      it 'renders the gitaly unavailable error message' do
        allow_gitaly_to_raise_error

        make_request

        expect(response.body).to include('Unable to compare revisions')
        expect(response.body).to include('The git server, Gitaly, is not available at this time')
      end

      context 'when error is raised from Repository level' do
        # Unique stub: uses Repository#compare_source_branch
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
        # Unique stub: complex multi-service stub for health check scenario
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
      include_context 'when CompareService#execute raises Gitaly error'

      let(:make_request) do
        get signatures_namespace_project_compare_index_path(namespace_id: project.namespace, project_id: project,
          from: 'master', to: 'feature', format: :json)
      end

      it_behaves_like 'handles Gitaly errors for json format'
    end

    describe '#diff_for_path' do
      include_context 'when CompareService#execute raises Gitaly error'

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

      it_behaves_like 'handles Gitaly errors for json format'
    end
  end

  describe 'Projects::GraphsController' do
    include_context 'when Gitlab::Git::Commit.find raises Gitaly error'

    describe '#show' do
      let(:make_request) do
        get namespace_project_graph_path(namespace_id: project.namespace, project_id: project, id: 'master')
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

      it_behaves_like 'handles Gitaly errors for request specs'
    end
  end

  describe 'Projects::FindFileController' do
    describe '#show' do
      include_context 'when Gitlab::Git::Commit.find raises Gitaly error'

      let(:make_request) { get project_find_file_path(project, 'master') }

      it_behaves_like 'handles Gitaly errors for request specs'
    end

    describe '#list' do
      let(:make_request) { get project_files_path(project, 'master', format: :json) }

      let(:allow_gitaly_to_raise_error) do
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:ls_files)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      it_behaves_like 'handles Gitaly errors for json format'
    end
  end

  describe 'Projects::NetworkController' do
    include_context 'when Gitlab::Git::Commit.find raises Gitaly error'

    describe '#show' do
      let(:make_request) { get project_network_path(project, 'master') }

      it_behaves_like 'handles Gitaly errors for request specs'

      context 'with JSON format' do
        let(:make_request) { get project_network_path(project, 'master', format: :json) }

        it_behaves_like 'handles Gitaly errors for json format'
      end
    end
  end

  describe 'Projects::MergeRequests::DiffsController' do
    let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

    let(:allow_gitaly_to_raise_error) do
      allow_next_instance_of(Repository) do |repository|
        allow(repository).to receive(:diff_stats)
          .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
      end
    end

    describe '#show' do
      let(:make_request) { get diffs_project_merge_request_path(project, merge_request, format: :json) }

      it_behaves_like 'handles Gitaly errors for json format'
    end

    describe '#diffs_batch' do
      let(:make_request) do
        get diffs_batch_namespace_project_json_merge_request_path(
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: merge_request.iid,
          format: 'json'
        )
      end

      it_behaves_like 'handles Gitaly errors for json format'
    end

    describe '#diffs_metadata' do
      let(:make_request) do
        get diffs_metadata_namespace_project_json_merge_request_path(
          namespace_id: project.namespace.to_param,
          project_id: project,
          id: merge_request.iid,
          format: 'json'
        )
      end

      it_behaves_like 'handles Gitaly errors for json format'
    end

    describe '#diff_for_path' do
      let(:make_request) do
        get diff_for_path_project_merge_request_path(
          project,
          merge_request,
          old_path: 'README.md',
          new_path: 'README.md',
          format: :json
        )
      end

      it_behaves_like 'handles Gitaly errors for json format'
    end

    describe '#diff_by_file_hash' do
      let(:make_request) do
        get diff_by_file_hash_project_merge_request_path(
          project,
          merge_request,
          file_hash: 'abc123',
          format: :json
        )
      end

      it_behaves_like 'handles Gitaly errors for json format'
    end
  end

  describe 'Projects::RefsController' do
    include_context 'when Gitlab::Git::Commit.find raises Gitaly error'

    describe '#switch' do
      let(:make_request) do
        get switch_project_refs_path(project, id: 'master', destination: 'tree')
      end

      it_behaves_like 'handles Gitaly errors for request specs'
    end

    describe '#logs_tree' do
      let(:make_request) do
        get logs_tree_project_ref_path(project, id: 'master', format: :json)
      end

      it_behaves_like 'handles Gitaly errors for json format'
    end
  end

  describe 'Projects::RepositoriesController' do
    describe '#archive' do
      let(:allow_gitaly_to_raise_error) do
        allow_next_instance_of(Repository) do |repository|
          allow(repository).to receive(:archive_metadata)
            .and_raise(Gitlab::Git::CommandError, 'Gitaly unavailable')
        end
      end

      context 'with GET request' do
        let(:make_request) { get project_archive_path(project, id: 'master', format: :zip) }

        it_behaves_like 'handles Gitaly errors for request specs'
      end

      context 'with HEAD request' do
        let(:make_request) { head project_archive_path(project, id: 'master', format: :zip) }

        it_behaves_like 'handles Gitaly errors for request specs'
      end

      context 'when repository or ref is not found' do
        it 'returns 404 for ArchiveNotFoundError from Workhorse' do
          allow_next_instance_of(Projects::RepositoriesController) do |controller|
            allow(controller).to receive(:send_git_archive)
              .and_raise(Gitlab::Workhorse::ArchiveNotFoundError, 'Repository or ref not found')
          end

          get project_archive_path(project, id: 'master', format: :zip)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'Projects::ProtectedBranchesController' do
    include_context 'when RefsFinder#execute raises Gitaly error'

    let_it_be_with_reload(:protected_refs_project) { create(:project, :public, :repository) }
    let_it_be(:protected_branch) { create(:protected_branch, project: protected_refs_project) }

    before_all do
      protected_refs_project.add_maintainer(user)
    end

    describe '#show' do
      let(:make_request) { get project_protected_branch_path(protected_refs_project, protected_branch) }

      it_behaves_like 'handles Gitaly errors for request specs'
    end
  end

  describe 'Projects::ProtectedTagsController' do
    include_context 'when RefsFinder#execute raises Gitaly error'

    let_it_be_with_reload(:protected_refs_project) { create(:project, :public, :repository) }
    let_it_be(:protected_tag) { create(:protected_tag, project: protected_refs_project) }

    before_all do
      protected_refs_project.add_maintainer(user)
    end

    describe '#show' do
      let(:make_request) { get project_protected_tag_path(protected_refs_project, protected_tag) }

      it_behaves_like 'handles Gitaly errors for request specs'
    end
  end

  describe 'Projects::MergeRequests::ConflictsController' do
    include_context 'when Conflict::Resolver#conflicts raises Gitaly error'

    let_it_be(:merge_request) do
      create(:merge_request, source_branch: 'conflict-resolvable', target_branch: 'conflict-start',
        source_project: project, merge_status: :unchecked, &:mark_as_unmergeable)
    end

    describe '#show' do
      context 'with HTML format' do
        let(:make_request) { get conflicts_project_merge_request_path(project, merge_request) }

        it_behaves_like 'handles Gitaly errors for request specs'
      end

      context 'with JSON format' do
        let(:make_request) { get conflicts_project_merge_request_path(project, merge_request, format: :json) }

        it_behaves_like 'handles Gitaly errors for json format'
      end
    end

    describe '#conflict_for_path' do
      let(:make_request) do
        get conflict_for_path_project_merge_request_path(
          project,
          merge_request,
          old_path: 'files/ruby/popen.rb',
          new_path: 'files/ruby/popen.rb',
          format: :json
        )
      end

      it_behaves_like 'handles Gitaly errors for json format'
    end

    describe '#resolve_conflicts' do
      let(:make_request) do
        post resolve_conflicts_project_merge_request_path(
          project,
          merge_request,
          format: :json
        ), params: { files: [], commit_message: 'Resolve conflicts' }
      end

      it_behaves_like 'handles Gitaly errors for json format'
    end
  end
end
