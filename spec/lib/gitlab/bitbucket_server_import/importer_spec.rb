# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importer do
  include ImportSpecHelper

  let(:import_url) { 'http://my-bitbucket' }
  let(:bitbucket_user) { 'bitbucket' }
  let(:project_creator) { create(:user, username: 'project_creator', email: 'project_creator@example.org') }
  let(:password) { 'test' }
  let(:project) { create(:project, :repository, import_url: import_url, creator: project_creator) }
  let(:now) { Time.now.utc.change(usec: 0) }
  let(:project_key) { 'TEST' }
  let(:repo_slug) { 'rouge' }
  let(:sample) { RepoHelpers.sample_compare }

  subject { described_class.new(project, recover_missing_commits: true) }

  before do
    data = project.create_or_update_import_data(
      data: { project_key: project_key, repo_slug: repo_slug },
      credentials: { base_uri: import_url, user: bitbucket_user, password: password }
    )
    data.save
    project.save
  end

  describe '#import_repository' do
    it 'adds a remote' do
      expect(subject).to receive(:import_pull_requests)
      expect(subject).to receive(:delete_temp_branches)
      expect(project.repository).to receive(:fetch_as_mirror)
                                     .with('http://bitbucket:test@my-bitbucket',
                                           refmap: [:heads, :tags, '+refs/pull-requests/*/to:refs/merge-requests/*/head'],
                                           remote_name: 'bitbucket_server')

      subject.execute
    end

    it 'raises a Gitlab::Shell exception in the fetch' do
      expect(project.repository).to receive(:fetch_as_mirror).and_raise(Gitlab::Shell::Error)

      expect { subject.execute }.to raise_error(Gitlab::Shell::Error)
    end

    it 'raises an unhandled exception in the fetch' do
      expect(project.repository).to receive(:fetch_as_mirror).and_raise(RuntimeError)

      expect { subject.execute }.to raise_error(RuntimeError)
    end
  end

  describe '#import_pull_requests' do
    let(:pull_request_author) { create(:user, username: 'pull_request_author', email: 'pull_request_author@example.org') }
    let(:note_author) { create(:user, username: 'note_author', email: 'note_author@example.org') }

    let(:pull_request) do
      instance_double(
        BitbucketServer::Representation::PullRequest,
        iid: 10,
        source_branch_sha: sample.commits.last,
        source_branch_name: Gitlab::Git::BRANCH_REF_PREFIX + sample.source_branch,
        target_branch_sha: sample.commits.first,
        target_branch_name: Gitlab::Git::BRANCH_REF_PREFIX + sample.target_branch,
        title: 'This is a title',
        description: 'This is a test pull request',
        state: 'merged',
        author: 'Test Author',
        author_email: pull_request_author.email,
        author_username: pull_request_author.username,
        created_at: Time.now,
        updated_at: Time.now,
        raw: {},
        merged?: true)
    end

    let(:merge_event) do
      instance_double(
        BitbucketServer::Representation::Activity,
        comment?: false,
        merge_event?: true,
        committer_email: pull_request_author.email,
        merge_timestamp: now,
        merge_commit: '12345678'
      )
    end

    let(:pr_note) do
      instance_double(
        BitbucketServer::Representation::Comment,
        note: 'Hello world',
        author_email: note_author.email,
        author_username: note_author.username,
        comments: [],
        created_at: now,
        updated_at: now,
        parent_comment: nil)
    end

    let(:pr_comment) do
      instance_double(
        BitbucketServer::Representation::Activity,
        comment?: true,
        inline_comment?: false,
        merge_event?: false,
        comment: pr_note)
    end

    before do
      allow(subject).to receive(:import_repository)
      allow(subject).to receive(:delete_temp_branches)
      allow(subject).to receive(:restore_branches)

      allow(subject.client).to receive(:pull_requests).and_return([pull_request], [])
    end

    # As we are using Caching with redis, it is best to clean the cache after each test run, else we need to wait for
    # the expiration by the importer
    after do
      Gitlab::Cache::Import::Caching.expire(subject.already_imported_cache_key, 0)
    end

    it 'imports merge event' do
      expect(subject.client).to receive(:activities).and_return([merge_event])

      expect { subject.execute }.to change { MergeRequest.count }.by(1)

      merge_request = MergeRequest.first
      expect(merge_request.metrics.merged_by).to eq(pull_request_author)
      expect(merge_request.metrics.merged_at).to eq(merge_event.merge_timestamp)
      expect(merge_request.merge_commit_sha).to eq('12345678')
      expect(merge_request.state_id).to eq(3)
    end

    describe 'pull request author user mapping' do
      before do
        allow(subject.client).to receive(:activities).and_return([merge_event])
      end

      shared_examples 'imports pull requests' do
        it 'maps user' do
          expect { subject.execute }.to change { MergeRequest.count }.by(1)

          merge_request = MergeRequest.first
          expect(merge_request.author).to eq(pull_request_author)
        end
      end

      context 'when bitbucket_server_user_mapping_by_username feature flag is disabled' do
        before do
          stub_feature_flags(bitbucket_server_user_mapping_by_username: false)
        end

        include_examples 'imports pull requests'
      end

      context 'when bitbucket_server_user_mapping_by_username feature flag is enabled' do
        before do
          stub_feature_flags(bitbucket_server_user_mapping_by_username: true)
        end

        include_examples 'imports pull requests' do
          context 'when username is not present' do
            before do
              allow(pull_request).to receive(:author_username).and_return(nil)
            end

            it 'maps by email' do
              expect { subject.execute }.to change { MergeRequest.count }.by(1)

              merge_request = MergeRequest.first
              expect(merge_request.author).to eq(pull_request_author)
            end
          end
        end
      end

      context 'when user is not found' do
        before do
          allow(pull_request).to receive(:author_username).and_return(nil)
          allow(pull_request).to receive(:author_email).and_return(nil)
        end

        it 'maps importer user' do
          expect { subject.execute }.to change { MergeRequest.count }.by(1)

          merge_request = MergeRequest.first
          expect(merge_request.author).to eq(project_creator)
        end
      end
    end

    describe 'comments' do
      shared_examples 'imports comments' do
        it 'imports comments' do
          expect(subject.client).to receive(:activities).and_return([pr_comment])

          expect { subject.execute }.to change { MergeRequest.count }.by(1)

          merge_request = MergeRequest.first
          expect(merge_request.notes.count).to eq(1)
          note = merge_request.notes.first
          expect(note.note).to end_with(pr_note.note)
          expect(note.author).to eq(note_author)
          expect(note.created_at).to eq(pr_note.created_at)
          expect(note.updated_at).to eq(pr_note.created_at)
        end
      end

      context 'when bitbucket_server_user_mapping_by_username feature flag is disabled' do
        before do
          stub_feature_flags(bitbucket_server_user_mapping_by_username: false)
        end

        include_examples 'imports comments'
      end

      context 'when bitbucket_server_user_mapping_by_username feature flag is enabled' do
        before do
          stub_feature_flags(bitbucket_server_user_mapping_by_username: true)
        end

        include_examples 'imports comments'

        context 'when username is not present' do
          before do
            allow(pr_note).to receive(:author_username).and_return(nil)
            allow(subject.client).to receive(:activities).and_return([pr_comment])
          end

          it 'maps by email' do
            expect { subject.execute }.to change { MergeRequest.count }.by(1)

            merge_request = MergeRequest.first
            expect(merge_request.notes.count).to eq(1)
            note = merge_request.notes.first
            expect(note.author).to eq(note_author)
          end
        end
      end
    end

    context 'metrics' do
      let(:histogram) { double(:histogram) }
      let(:counter) { double('counter', increment: true) }

      before do
        allow(Gitlab::Metrics).to receive(:counter) { counter }
        allow(Gitlab::Metrics).to receive(:histogram) { histogram }
        allow(subject.client).to receive(:activities).and_return([merge_event])
      end

      it 'counts and measures duration of imported projects' do
        expect(Gitlab::Metrics).to receive(:counter).with(
          :bitbucket_server_importer_imported_projects_total,
          'The number of imported projects'
        )

        expect(Gitlab::Metrics).to receive(:histogram).with(
          :bitbucket_server_importer_total_duration_seconds,
          'Total time spent importing projects, in seconds',
          {},
          Gitlab::Import::Metrics::IMPORT_DURATION_BUCKETS
        )

        expect(counter).to receive(:increment)
        expect(histogram).to receive(:observe).with({ importer: :bitbucket_server_importer }, anything)

        subject.execute
      end

      it 'counts imported pull requests' do
        expect(Gitlab::Metrics).to receive(:counter).with(
          :bitbucket_server_importer_imported_merge_requests_total,
          'The number of imported merge (pull) requests'
        )

        expect(counter).to receive(:increment)
        allow(histogram).to receive(:observe).with({ importer: :bitbucket_server_importer }, anything)

        subject.execute
      end
    end

    describe 'threaded discussions' do
      let(:reply_author) { create(:user, username: 'reply_author', email: 'reply_author@example.org') }
      let(:inline_note_author) { create(:user, username: 'inline_note_author', email: 'inline_note_author@example.org') }

      let(:reply) do
        instance_double(
          BitbucketServer::Representation::PullRequestComment,
          author_email: reply_author.email,
          author_username: reply_author.username,
          note: 'I agree',
          created_at: now,
          updated_at: now)
      end

      # https://gitlab.com/gitlab-org/gitlab-test/compare/c1acaa58bbcbc3eafe538cb8274ba387047b69f8...5937ac0a7beb003549fc5fd26fc247ad
      let(:inline_note) do
        instance_double(
          BitbucketServer::Representation::PullRequestComment,
          file_type: 'ADDED',
          from_sha: sample.commits.first,
          to_sha: sample.commits.last,
          file_path: '.gitmodules',
          old_pos: nil,
          new_pos: 4,
          note: 'Hello world',
          author_email: inline_note_author.email,
          author_username: inline_note_author.username,
          comments: [reply],
          created_at: now,
          updated_at: now,
          parent_comment: nil)
      end

      let(:inline_comment) do
        instance_double(
          BitbucketServer::Representation::Activity,
          comment?: true,
          inline_comment?: true,
          merge_event?: false,
          comment: inline_note)
      end

      before do
        allow(reply).to receive(:parent_comment).and_return(inline_note)
        allow(subject.client).to receive(:activities).and_return([inline_comment])
      end

      shared_examples 'imports threaded discussions' do
        it 'imports threaded discussions' do
          expect { subject.execute }.to change { MergeRequest.count }.by(1)

          merge_request = MergeRequest.first
          expect(merge_request.notes.count).to eq(2)
          expect(merge_request.notes.map(&:discussion_id).uniq.count).to eq(1)

          notes = merge_request.notes.order(:id).to_a
          start_note = notes.first
          expect(start_note.type).to eq('DiffNote')
          expect(start_note.note).to end_with(inline_note.note)
          expect(start_note.created_at).to eq(inline_note.created_at)
          expect(start_note.updated_at).to eq(inline_note.updated_at)
          expect(start_note.position.base_sha).to eq(inline_note.from_sha)
          expect(start_note.position.start_sha).to eq(inline_note.from_sha)
          expect(start_note.position.head_sha).to eq(inline_note.to_sha)
          expect(start_note.position.old_line).to be_nil
          expect(start_note.position.new_line).to eq(inline_note.new_pos)
          expect(start_note.author).to eq(inline_note_author)

          reply_note = notes.last
          # Make sure author and reply context is included
          expect(reply_note.note).to start_with("> #{inline_note.note}\n\n#{reply.note}")
          expect(reply_note.author).to eq(reply_author)
          expect(reply_note.created_at).to eq(reply.created_at)
          expect(reply_note.updated_at).to eq(reply.created_at)
          expect(reply_note.position.base_sha).to eq(inline_note.from_sha)
          expect(reply_note.position.start_sha).to eq(inline_note.from_sha)
          expect(reply_note.position.head_sha).to eq(inline_note.to_sha)
          expect(reply_note.position.old_line).to be_nil
          expect(reply_note.position.new_line).to eq(inline_note.new_pos)
        end
      end

      context 'when bitbucket_server_user_mapping_by_username feature flag is disabled' do
        before do
          stub_feature_flags(bitbucket_server_user_mapping_by_username: false)
        end

        include_examples 'imports threaded discussions'
      end

      context 'when bitbucket_server_user_mapping_by_username feature flag is enabled' do
        before do
          stub_feature_flags(bitbucket_server_user_mapping_by_username: true)
        end

        include_examples 'imports threaded discussions' do
          context 'when username is not present' do
            before do
              allow(reply).to receive(:author_username).and_return(nil)
              allow(inline_note).to receive(:author_username).and_return(nil)
            end

            it 'maps by email' do
              expect { subject.execute }.to change { MergeRequest.count }.by(1)

              notes = MergeRequest.first.notes.order(:id).to_a

              expect(notes.first.author).to eq(inline_note_author)
              expect(notes.last.author).to eq(reply_author)
            end
          end
        end
      end

      context 'when user is not found' do
        before do
          allow(reply).to receive(:author_username).and_return(nil)
          allow(reply).to receive(:author_email).and_return(nil)
          allow(inline_note).to receive(:author_username).and_return(nil)
          allow(inline_note).to receive(:author_email).and_return(nil)
        end

        it 'maps importer user' do
          expect { subject.execute }.to change { MergeRequest.count }.by(1)

          notes = MergeRequest.first.notes.order(:id).to_a

          expect(notes.first.author).to eq(project_creator)
          expect(notes.last.author).to eq(project_creator)
        end
      end
    end

    it 'falls back to comments if diff comments fail to validate' do
      reply = instance_double(
        BitbucketServer::Representation::Comment,
        author_email: 'someuser@gitlab.com',
        author_username: 'Aquaman',
        note: 'I agree',
        created_at: now,
        updated_at: now)

      # https://gitlab.com/gitlab-org/gitlab-test/compare/c1acaa58bbcbc3eafe538cb8274ba387047b69f8...5937ac0a7beb003549fc5fd26fc247ad
      inline_note = instance_double(
        BitbucketServer::Representation::PullRequestComment,
        file_type: 'REMOVED',
        from_sha: sample.commits.first,
        to_sha: sample.commits.last,
        file_path: '.gitmodules',
        old_pos: 8,
        new_pos: 9,
        note: 'This is a note with an invalid line position.',
        author_email: project.owner.email,
        author_username: 'Owner',
        comments: [reply],
        created_at: now,
        updated_at: now,
        parent_comment: nil)

      inline_comment = instance_double(
        BitbucketServer::Representation::Activity,
        comment?: true,
        inline_comment?: true,
        merge_event?: false,
        comment: inline_note)

      allow(reply).to receive(:parent_comment).and_return(inline_note)

      expect(subject.client).to receive(:activities).and_return([inline_comment])

      expect { subject.execute }.to change { MergeRequest.count }.by(1)

      merge_request = MergeRequest.first
      expect(merge_request.notes.count).to eq(2)
      notes = merge_request.notes

      expect(notes.first.note).to start_with('*Comment on .gitmodules')
      expect(notes.second.note).to start_with('*Comment on .gitmodules')
    end

    it 'reports an error if an exception is raised' do
      allow(subject).to receive(:import_bitbucket_pull_request).and_raise(RuntimeError)
      expect(Gitlab::ErrorTracking).to receive(:log_exception)

      subject.execute
    end

    describe 'import pull requests with caching' do
      let(:pull_request_already_imported) do
        instance_double(
          BitbucketServer::Representation::PullRequest,
          iid: 11)
      end

      let(:pull_request_to_be_imported) do
        instance_double(
          BitbucketServer::Representation::PullRequest,
          iid: 12,
          source_branch_sha: sample.commits.last,
          source_branch_name: Gitlab::Git::BRANCH_REF_PREFIX + sample.source_branch,
          target_branch_sha: sample.commits.first,
          target_branch_name: Gitlab::Git::BRANCH_REF_PREFIX + sample.target_branch,
          title: 'This is a title',
          description: 'This is a test pull request',
          state: 'merged',
          author: 'Test Author',
          author_email: pull_request_author.email,
          author_username: pull_request_author.username,
          created_at: Time.now,
          updated_at: Time.now,
          raw: {},
          merged?: true)
      end

      before do
        Gitlab::Cache::Import::Caching.set_add(subject.already_imported_cache_key, pull_request_already_imported.iid)
        allow(subject.client).to receive(:pull_requests).and_return([pull_request_to_be_imported, pull_request_already_imported], [])
      end

      it 'only imports one Merge Request, as the other on is in the cache' do
        expect(subject.client).to receive(:activities).and_return([merge_event])
        expect { subject.execute }.to change { MergeRequest.count }.by(1)

        expect(Gitlab::Cache::Import::Caching.set_includes?(subject.already_imported_cache_key, pull_request_already_imported.iid)).to eq(true)
        expect(Gitlab::Cache::Import::Caching.set_includes?(subject.already_imported_cache_key, pull_request_to_be_imported.iid)).to eq(true)
      end
    end
  end

  describe 'inaccessible branches' do
    let(:id) { 10 }
    let(:temp_branch_from) { "gitlab/import/pull-request/#{id}/from" }
    let(:temp_branch_to) { "gitlab/import/pull-request/#{id}/to" }

    before do
      pull_request = instance_double(
        BitbucketServer::Representation::PullRequest,
        iid: id,
        source_branch_sha: '12345678',
        source_branch_name: Gitlab::Git::BRANCH_REF_PREFIX + sample.source_branch,
        target_branch_sha: '98765432',
        target_branch_name: Gitlab::Git::BRANCH_REF_PREFIX + sample.target_branch,
        title: 'This is a title',
        description: 'This is a test pull request',
        state: 'merged',
        author: 'Test Author',
        author_email: project.owner.email,
        author_username: 'author',
        created_at: Time.now,
        updated_at: Time.now,
        merged?: true)

      expect(subject.client).to receive(:pull_requests).and_return([pull_request], [])
      expect(subject.client).to receive(:activities).and_return([])
      expect(subject).to receive(:import_repository).twice
    end

    it '#restore_branches' do
      expect(subject).to receive(:restore_branches).and_call_original
      expect(subject).to receive(:delete_temp_branches)
      expect(subject.client).to receive(:create_branch)
                                 .with(project_key, repo_slug,
                                       temp_branch_from,
                                       '12345678')
      expect(subject.client).to receive(:create_branch)
                                 .with(project_key, repo_slug,
                                       temp_branch_to,
                                       '98765432')

      expect { subject.execute }.to change { MergeRequest.count }.by(1)
    end

    it '#delete_temp_branches' do
      expect(subject.client).to receive(:create_branch).twice
      expect(subject).to receive(:delete_temp_branches).and_call_original
      expect(subject.client).to receive(:delete_branch)
                                 .with(project_key, repo_slug,
                                       temp_branch_from,
                                       '12345678')
      expect(subject.client).to receive(:delete_branch)
                                 .with(project_key, repo_slug,
                                       temp_branch_to,
                                       '98765432')
      expect(project.repository).to receive(:delete_branch).with(temp_branch_from)
      expect(project.repository).to receive(:delete_branch).with(temp_branch_to)

      expect { subject.execute }.to change { MergeRequest.count }.by(1)
    end
  end

  context "lfs files" do
    before do
      allow(project).to receive(:lfs_enabled?).and_return(true)
      allow(subject).to receive(:import_repository)
      allow(subject).to receive(:import_pull_requests)
    end

    it "downloads lfs objects if lfs_enabled is enabled for project" do
      expect_next_instance_of(Projects::LfsPointers::LfsImportService) do |lfs_import_service|
        expect(lfs_import_service).to receive(:execute).and_return(status: :success)
      end

      subject.execute
    end

    it "adds the error message when the lfs download fails" do
      allow_next_instance_of(Projects::LfsPointers::LfsImportService) do |lfs_import_service|
        expect(lfs_import_service).to receive(:execute).and_return(status: :error, message: "LFS server not reachable")
      end

      subject.execute

      expect(project.import_state.reload.last_error).to eq(Gitlab::Json.dump({
        message: "The remote data could not be fully imported.",
        errors: [{
          type: "lfs_objects",
          errors: "The Lfs import process failed. LFS server not reachable"
        }]
      }))
    end
  end
end
