# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importers::PullRequestNotesImporter, feature_category: :importers do
  include AfterNextHelpers
  include Import::UserMappingHelper

  let_it_be_with_reload(:project) do
    create(:project, :repository, :bitbucket_server_import, :import_user_mapping_enabled)
  end

  let_it_be(:pull_request_data) { Gitlab::Json.parse(fixture_file('importers/bitbucket_server/pull_request.json')) }
  let_it_be(:pull_request) { BitbucketServer::Representation::PullRequest.new(pull_request_data) }
  let_it_be_with_reload(:merge_request) { create(:merge_request, iid: pull_request.iid, source_project: project) }

  let(:merge_event) do
    instance_double(
      BitbucketServer::Representation::Activity,
      id: 3,
      comment?: false,
      merge_event?: true,
      approved_event?: false,
      committer_name: 'Pull Request Author',
      committer_username: 'pull_request_author',
      committer_email: 'pull_request_author@example.com',
      merge_timestamp: now,
      merge_commit: '12345678'
    )
  end

  let(:approved_event) do
    instance_double(
      BitbucketServer::Representation::Activity,
      id: 4,
      comment?: false,
      merge_event?: false,
      approved_event?: true,
      approver_name: 'Pull Request Author',
      approver_username: 'pull_request_author',
      approver_email: 'pull_request_author@example.org',
      created_at: now
    )
  end

  let(:pr_note) do
    instance_double(
      BitbucketServer::Representation::Comment,
      id: 456,
      note: 'Hello world',
      author_name: 'Note Author',
      author_email: 'note_author@example.org',
      author_username: 'note_author',
      comments: [pr_note_reply],
      created_at: now,
      updated_at: now,
      parent_comment: nil)
  end

  let(:pr_note_reply) do
    instance_double(
      BitbucketServer::Representation::Comment,
      note: 'Yes, absolutely.',
      author_name: 'Note Author',
      author_email: 'note_author@example.org',
      author_username: 'note_author',
      comments: [],
      created_at: now,
      updated_at: now,
      parent_comment: nil)
  end

  let(:pr_comment) do
    instance_double(
      BitbucketServer::Representation::Activity,
      id: 5,
      comment?: true,
      inline_comment?: false,
      merge_event?: false,
      comment: pr_note)
  end

  let!(:author_source_user) { generate_source_user(project, merge_event.committer_username) }
  let!(:note_source_user) { generate_source_user(project, pr_note.author_username) }

  let_it_be(:sample) { RepoHelpers.sample_compare }
  let_it_be(:now) { Time.now.utc.change(usec: 0) }

  let(:cached_references) do
    placeholder_user_references(::Import::SOURCE_BITBUCKET_SERVER, project.import_state.id)
  end

  def expect_log(stage:, message:)
    allow(Gitlab::BitbucketServerImport::Logger).to receive(:info).and_call_original
    expect(Gitlab::BitbucketServerImport::Logger)
      .to receive(:info).with(include(import_stage: stage, message: message))
  end

  subject(:importer) { described_class.new(project.reload, pull_request.to_hash) }

  describe '#execute', :clean_gitlab_redis_shared_state do
    context 'when a matching merge request is not found' do
      before do
        merge_request.update!(iid: merge_request.iid + 1)
      end

      it 'does nothing' do
        expect { importer.execute }.not_to change { Note.count }
      end

      it 'logs its progress' do
        expect_log(stage: 'import_pull_request_notes', message: 'starting')
        expect_log(stage: 'import_pull_request_notes', message: 'finished')

        importer.execute
      end
    end

    context 'when a matching merge request is found' do
      it 'logs its progress' do
        allow_next(BitbucketServer::Client).to receive(:activities).and_return([])

        expect_log(stage: 'import_pull_request_notes', message: 'starting')
        expect_log(stage: 'import_pull_request_notes', message: 'finished')

        importer.execute
      end

      context 'when PR has comments' do
        before do
          allow_next(BitbucketServer::Client).to receive(:activities).and_return([pr_comment])
        end

        it 'pushes placeholder references' do
          importer.execute

          expect(cached_references).to contain_exactly(
            ['Note', instance_of(Integer), 'author_id', note_source_user.id],
            ["Note", instance_of(Integer), "author_id", note_source_user.id]
          )
        end

        it 'imports the stand alone comments' do
          expect { importer.execute }.to change { Note.count }.by(2)

          notes = merge_request.notes.order(:id)

          expect(notes.first).to have_attributes(
            note: end_with(pr_note.note),
            author_id: note_source_user.mapped_user_id,
            created_at: pr_note.created_at,
            updated_at: pr_note.created_at,
            imported_from: 'bitbucket_server'
          )

          expect(notes.last).to have_attributes(
            note: end_with(pr_note_reply.note),
            author_id: note_source_user.mapped_user_id,
            created_at: pr_note_reply.created_at,
            updated_at: pr_note_reply.created_at,
            imported_from: 'bitbucket_server'
          )
        end

        context 'when the note has @ mentions' do
          let(:original_note_text) { "I said to @sam_allen.greg follow @bob's advice. @.ali-ce/group#9?" }
          let(:expected_note_text) { "I said to `@sam_allen.greg` follow `@bob`'s advice. `@.ali-ce/group#9`?" }
          let(:original_reply_text) { "@bachhus I don't agree. See @ali's evidence cc @.ali-ce/group#9?" }
          let(:expected_reply_text) { "`@bachhus` I don't agree. See `@ali`'s evidence cc `@.ali-ce/group#9`?" }

          let(:pr_note) do
            instance_double(
              BitbucketServer::Representation::Comment,
              id: 456,
              note: original_note_text,
              author_name: 'Note Author',
              author_email: 'note_author@example.org',
              author_username: 'note_author',
              comments: [pr_note_reply],
              created_at: now,
              updated_at: now,
              parent_comment: nil)
          end

          let(:pr_note_reply) do
            instance_double(
              BitbucketServer::Representation::Comment,
              note: original_reply_text,
              author_name: 'Note Author',
              author_email: 'note_author@example.org',
              author_username: 'note_author',
              comments: [],
              created_at: now,
              updated_at: now,
              parent_comment: nil)
          end

          it 'inserts backticks around the mentions' do
            importer.execute

            expect(Note.first.note).to eq(expected_note_text)
            expect(Note.last.note).to eq(expected_reply_text)
          end
        end

        context 'when the note has a parent note with @ mentions' do
          let(:original_parent_text) do
            "Attention: To inform @ali has worked on this. @fred's work from @.ali-ce/group#9?"
          end

          let(:expected_parent_text) do
            "Attention: To inform `@ali` has worked on this. `@fred`'s work from `@.ali-ce/gro` ..."
          end

          let(:pr_note) do
            instance_double(
              BitbucketServer::Representation::Comment,
              note: 'Note',
              author_name: 'Note Author',
              author_email: 'note_author@example.org',
              author_username: 'note_author',
              comments: [],
              created_at: now,
              updated_at: now,
              parent_comment: pr_parent_note
            )
          end

          let(:pr_parent_note) do
            instance_double(
              BitbucketServer::Representation::Comment,
              note: original_parent_text,
              author_name: 'Note Author',
              author_email: 'note_author@example.org',
              author_username: 'note_author',
              comments: [],
              created_at: now,
              updated_at: now,
              parent_comment: nil
            )
          end

          it 'adds the parent note before the actual note with backticks inserted' do
            importer.execute

            expect(Note.first.note).to include("> #{expected_parent_text}")
          end
        end

        context 'when an exception is raised during comment creation' do
          before do
            allow(importer).to receive(:pull_request_comment_attributes).and_raise(exception)
          end

          let(:exception) { StandardError.new('something went wrong') }

          it 'logs the error' do
            expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
              exception,
              import_stage: 'import_standalone_pr_comments',
              comment_id: pr_note.id,
              error: exception.message,
              merge_request_id: merge_request.id
            )

            importer.execute
          end
        end

        it 'logs its progress' do
          expect_log(stage: 'import_standalone_pr_comments', message: 'starting')
          expect_log(stage: 'import_standalone_pr_comments', message: 'finished')

          importer.execute
        end
      end

      context 'when PR has threaded inline discussion' do
        let(:reply) do
          instance_double(
            BitbucketServer::Representation::PullRequestComment,
            author_name: 'Reply Author',
            author_email: 'reply_author@example.org',
            author_username: 'reply_author',
            note: 'I agree',
            created_at: now,
            updated_at: now,
            parent_comment: nil)
        end

        let(:pr_inline_note) do
          instance_double(
            BitbucketServer::Representation::PullRequestComment,
            id: 123,
            file_type: 'ADDED',
            from_sha: pull_request.target_branch_sha,
            to_sha: pull_request.source_branch_sha,
            file_path: '.gitmodules',
            old_pos: nil,
            new_pos: 4,
            note: 'Hello world',
            author_name: 'Inline Note Author',
            author_email: 'inline_note_author@example.org',
            author_username: 'inline_note_author',
            comments: [reply],
            created_at: now,
            updated_at: now,
            parent_comment: nil)
        end

        let(:pr_inline_comment) do
          instance_double(
            BitbucketServer::Representation::Activity,
            comment?: true,
            inline_comment?: true,
            merge_event?: false,
            comment: pr_inline_note)
        end

        let_it_be(:reply_source_user) { generate_source_user(project, 'reply_author') }
        let_it_be(:note_source_user) { generate_source_user(project, 'inline_note_author') }

        before do
          allow_next(BitbucketServer::Client).to receive(:activities).and_return([pr_inline_comment])
        end

        it 'imports the threaded discussion' do
          expect { importer.execute }.to change { Note.count }.by(2)

          expect(merge_request.discussions.count).to eq(1)

          notes = merge_request.notes.order(:id).to_a
          start_note = notes.first
          expect(start_note.type).to eq('DiffNote')
          expect(start_note.note).to end_with(pr_inline_note.note)
          expect(start_note.created_at).to eq(pr_inline_note.created_at)
          expect(start_note.updated_at).to eq(pr_inline_note.updated_at)
          expect(start_note.position.old_line).to be_nil
          expect(start_note.position.new_line).to eq(pr_inline_note.new_pos)
          expect(start_note.author_id).to eq(note_source_user.mapped_user_id)
          expect(start_note.imported_from).to eq('bitbucket_server')

          reply_note = notes.last
          expect(reply_note.note).to eq(reply.note)
          expect(reply_note.author_id).to eq(reply_source_user.mapped_user_id)
          expect(reply_note.created_at).to eq(reply.created_at)
          expect(reply_note.updated_at).to eq(reply.created_at)
          expect(reply_note.position.old_line).to be_nil
          expect(reply_note.position.new_line).to eq(pr_inline_note.new_pos)
          expect(reply_note.imported_from).to eq('bitbucket_server')
        end

        it 'pushes placeholder references' do
          importer.execute

          expect(cached_references).to contain_exactly(
            ['DiffNote', instance_of(Integer), 'author_id', reply_source_user.id],
            ['DiffNote', instance_of(Integer), 'author_id', note_source_user.id]
          )
        end

        context 'when comment has no associated author' do
          before do
            allow(pr_inline_note).to receive(:author_username).and_return(nil)
            allow(reply).to receive(:author_username).and_return(nil)
          end

          it 'attributes the comments to the project creator' do
            importer.execute

            expect(merge_request.notes.collect(&:author_id)).to match_array([project.creator_id, project.creator_id])
          end

          it 'does not push placeholder references' do
            importer.execute

            expect(cached_references).to be_empty
          end
        end

        context 'when a diff note is invalid' do
          let(:pr_inline_note) do
            instance_double(
              BitbucketServer::Representation::PullRequestComment,
              file_type: 'ADDED',
              from_sha: pull_request.target_branch_sha,
              to_sha: pull_request.source_branch_sha,
              file_path: '.gitmodules',
              old_pos: 3,
              new_pos: nil,
              note: 'Hello world',
              author_name: 'Inline Note Author',
              author_email: 'inline_note_author@example.org',
              author_username: 'inline_note_author',
              comments: [],
              created_at: now,
              updated_at: now,
              parent_comment: nil)
          end

          it 'creates a fallback diff note' do
            importer.execute

            notes = merge_request.notes.order(:id).to_a
            note = notes.first

            expect(note.note).to eq("*Comment on .gitmodules:3 -->*\n\nHello world")
          end
        end

        context 'when an exception is raised during DiffNote creation' do
          before do
            allow(importer).to receive(:pull_request_comment_attributes).and_raise(exception)
          end

          let(:exception) { StandardError.new('something went wrong') }

          it 'logs the error' do
            expect(Gitlab::ErrorTracking).to receive(:log_exception).with(
              exception,
              import_stage: 'create_diff_note',
              comment_id: 123,
              error: exception.message
            )

            importer.execute
          end
        end

        it 'logs its progress' do
          expect_log(stage: 'import_inline_comments', message: 'starting')
          expect_log(stage: 'import_inline_comments', message: 'finished')

          importer.execute
        end
      end

      context 'when PR has a merge event' do
        before do
          allow_next(BitbucketServer::Client).to receive(:activities).and_return([merge_event])
        end

        it 'imports the merge event' do
          importer.execute

          merge_request.reload

          expect(merge_request.metrics.merged_by_id).to eq(author_source_user.mapped_user_id)
          expect(merge_request.metrics.merged_at).to eq(merge_event.merge_timestamp)
          expect(merge_request.merge_commit_sha).to eq(merge_event.merge_commit)
        end

        it 'pushes placeholder references' do
          importer.execute

          expect(cached_references).to contain_exactly(
            ["MergeRequest::Metrics", instance_of(Integer), "merged_by_id", author_source_user.id]
          )
        end

        context 'when merge event has no associated user' do
          before do
            allow(merge_event).to receive(:committer_username).and_return(nil)
          end

          it 'associates the merge event with project creator' do
            importer.execute

            merge_request.reload

            expect(merge_request.metrics.merged_by_id).to eq(project.creator_id)
          end

          it 'does not push placeholder references' do
            importer.execute

            expect(cached_references).to be_empty
          end
        end
      end

      context 'when PR has an approved event' do
        before do
          allow_next(BitbucketServer::Client).to receive(:activities).and_return([approved_event])
        end

        it 'creates the approval, reviewer and approval note' do
          expect { importer.execute }
            .to change { merge_request.approvals.count }.from(0).to(1)
            .and change { merge_request.notes.count }.from(0).to(1)
            .and change { merge_request.reviewers.count }.from(0).to(1)

          approval = merge_request.approvals.first

          expect(approval.user_id).to eq(author_source_user.mapped_user_id)
          expect(approval.created_at).to eq(now)

          note = merge_request.notes.first

          expect(note.note).to eq('approved this merge request')
          expect(note.author_id).to eq(author_source_user.mapped_user_id)
          expect(note.system).to be_truthy
          expect(note.created_at).to eq(now)

          reviewer = merge_request.reviewers.first

          expect(reviewer.id).to eq(author_source_user.mapped_user_id)
        end

        it 'pushes placeholder references' do
          importer.execute

          expect(cached_references).to contain_exactly(
            ['Approval', instance_of(Integer), 'user_id', author_source_user.id],
            ['MergeRequestReviewer', instance_of(Integer), 'user_id', author_source_user.id],
            ['Note', instance_of(Integer), 'author_id', author_source_user.id]
          )
        end

        context 'if the reviewer is already assigned to the MR' do
          before do
            merge_request.reviewers = [author_source_user.mapped_user]
            merge_request.save!
          end

          it 'does not create the reviewer record' do
            expect { importer.execute }.not_to change { merge_request.reviewers.count }
          end
        end

        context 'when approved event has no associated approver' do
          before do
            allow(approved_event).to receive(:approver_username).and_return(nil)
          end

          it 'does not set an approver' do
            expect { importer.execute }
              .to not_change { merge_request.approvals.count }
              .and not_change { merge_request.notes.count }
              .and not_change { merge_request.reviewers.count }

            expect(merge_request.approvals).to be_empty
          end
        end
      end
    end

    shared_examples 'import is skipped' do
      it 'does not log and does not import notes' do
        expect(Gitlab::BitbucketServerImport::Logger)
          .not_to receive(:info).with(include(import_stage: 'import_pull_request_notes', message: 'starting'))

        expect { importer.execute }.not_to change { Note.count }
      end
    end

    context 'when the project has been marked as failed' do
      before do
        project.import_state.mark_as_failed('error')
      end

      include_examples 'import is skipped'
    end

    context 'when the import data does not have credentials' do
      let_it_be(:project) do
        create(:project, :repository, :bitbucket_server_import,
          import_data_attributes: {
            data: { 'project_key' => 'key', 'repo_slug' => 'slug' },
            credentials: nil
          }
        )
      end

      include_examples 'import is skipped'
    end

    context 'when the import data does not have data' do
      let_it_be(:project) do
        create(:project, :repository, :bitbucket_server_import,
          import_data_attributes: {
            data: nil,
            credentials: { 'token' => 'token' }
          }
        )
      end

      include_examples 'import is skipped'
    end

    context 'when user contribution mapping is disabled' do
      let!(:note_author) { create(:user, username: 'note_author', email: 'note_author@example.org') }
      let!(:pull_request_author) do
        create(:user, username: 'pull_request_author', email: 'pull_request_author@example.org')
      end

      before do
        project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false }).save!
        allow_next(BitbucketServer::Client).to receive(:activities).and_return([approved_event])
      end

      it 'assigns the approval to the PR author based on email' do
        importer.execute

        approval = merge_request.approvals.first

        expect(approval.user).to eq(pull_request_author)
      end

      context 'when no users match email' do
        before do
          pull_request_author.destroy!
        end

        it 'does not set an approver' do
          expect { importer.execute }
            .to not_change { merge_request.approvals.count }
            .and not_change { merge_request.notes.count }
            .and not_change { merge_request.reviewers.count }

          expect(merge_request.approvals).to be_empty
        end

        context 'when importing merge events' do
          before do
            allow_next(BitbucketServer::Client).to receive(:activities).and_return([merge_event])
          end

          it 'attributes the merge event to the project creator' do
            importer.execute

            expect(merge_request.metrics.merged_by_id).to eq(project.creator_id)
          end
        end

        context 'when PR has threaded discussion' do
          let(:reply) do
            instance_double(
              BitbucketServer::Representation::PullRequestComment,
              author_name: 'Reply Author',
              author_email: 'reply_author@example.org',
              author_username: 'reply_author',
              note: 'I agree',
              created_at: now,
              updated_at: now,
              parent_comment: nil)
          end

          let(:pr_inline_note) do
            instance_double(
              BitbucketServer::Representation::PullRequestComment,
              file_type: 'ADDED',
              from_sha: pull_request.target_branch_sha,
              to_sha: pull_request.source_branch_sha,
              file_path: '.gitmodules',
              old_pos: nil,
              new_pos: 4,
              note: 'Hello world',
              author_name: 'Inline Note Author',
              author_email: 'inline_note_author@example.org',
              author_username: 'inline_note_author',
              comments: [reply],
              created_at: now,
              updated_at: now,
              parent_comment: nil)
          end

          let(:pr_inline_comment) do
            instance_double(
              BitbucketServer::Representation::Activity,
              comment?: true,
              inline_comment?: true,
              merge_event?: false,
              comment: pr_inline_note)
          end

          before do
            allow_next(BitbucketServer::Client).to receive(:activities).and_return([pr_inline_comment])
          end

          it 'attributes the comments to the project creator' do
            importer.execute

            expect(merge_request.notes.collect(&:author_id)).to match_array([project.creator_id, project.creator_id])
          end
        end
      end

      it 'does not push placeholder references' do
        importer.execute

        cached_references = placeholder_user_references(::Import::SOURCE_BITBUCKET_SERVER, project.import_state.id)
        expect(cached_references).to be_empty
      end

      context 'when the author is not found' do
        before do
          allow_next(BitbucketServer::Client).to receive(:activities).and_return([pr_comment])

          allow_next_instance_of(Gitlab::BitbucketServerImport::UserFinder) do |user_finder|
            allow(user_finder).to receive(:uid).and_return(nil)
          end
        end

        it 'adds a note with the author username and email' do
          importer.execute

          expect(Note.first.note).to include("*By #{note_author.username} (#{note_author.email})")
        end
      end
    end
  end
end
