# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importers::PullRequestNotes::Inline, feature_category: :importers do
  include Import::UserMappingHelper

  let_it_be_with_reload(:project) do
    create(:project, :repository, :bitbucket_server_import, :import_user_mapping_enabled)
  end

  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:now) { Time.now.utc.change(usec: 0) }
  let_it_be(:reply) do
    {
      author_email: 'reply_author@example.org',
      author_username: 'reply_author',
      note: 'I agree',
      created_at: now,
      updated_at: now,
      parent_comment_note: nil
    }
  end

  let_it_be(:pr_inline_comment) do
    {
      id: 7,
      file_type: 'ADDED',
      from_sha: 'c5f4288162e2e6218180779c7f6ac1735bb56eab',
      to_sha: 'a4c2164330f2549f67c13f36a93884cf66e976be',
      file_path: '.gitmodules',
      old_pos: nil,
      new_pos: 4,
      note: 'Hello world',
      author_email: 'inline_note_author@example.org',
      author_username: 'inline_note_author',
      comments: [reply],
      created_at: now,
      updated_at: now,
      parent_comment_note: nil
    }
  end

  let_it_be(:reply_source_user) { generate_source_user(project, reply[:author_username]) }
  let_it_be(:note_source_user) { generate_source_user(project, pr_inline_comment[:author_username]) }

  let(:cached_references) { placeholder_user_references(::Import::SOURCE_BITBUCKET_SERVER, project.import_state.id) }

  def expect_log(stage:, message:, iid:, comment_id:)
    allow(Gitlab::BitbucketServerImport::Logger).to receive(:info).and_call_original
    expect(Gitlab::BitbucketServerImport::Logger)
      .to receive(:info).with(include(import_stage: stage, message: message, iid: iid, comment_id: comment_id))
  end

  subject(:importer) { described_class.new(project, merge_request) }

  describe '#execute', :clean_gitlab_redis_shared_state do
    it 'pushes placeholder references' do
      importer.execute(pr_inline_comment)

      expect(cached_references).to contain_exactly(
        ['DiffNote', instance_of(Integer), 'author_id', note_source_user.id],
        ['DiffNote', instance_of(Integer), 'author_id', reply_source_user.id]
      )
    end

    it 'imports the threaded discussion' do
      expect { importer.execute(pr_inline_comment) }.to change { Note.count }.by(2)

      expect(merge_request.discussions.count).to eq(1)

      notes = merge_request.notes.order(:id).to_a
      start_note = notes.first
      expect(start_note.type).to eq('DiffNote')
      expect(start_note.note).to end_with(pr_inline_comment[:note])
      expect(start_note.created_at).to eq(pr_inline_comment[:created_at])
      expect(start_note.updated_at).to eq(pr_inline_comment[:updated_at])
      expect(start_note.position.old_line).to be_nil
      expect(start_note.position.new_line).to eq(pr_inline_comment[:new_pos])
      expect(start_note.author_id).to eq(note_source_user.mapped_user_id)

      reply_note = notes.last
      expect(reply_note.note).to eq(reply[:note])
      expect(reply_note.author_id).to eq(reply_source_user.mapped_user_id)
      expect(reply_note.created_at).to eq(reply[:created_at])
      expect(reply_note.updated_at).to eq(reply[:created_at])
      expect(reply_note.position.old_line).to be_nil
      expect(reply_note.position.new_line).to eq(pr_inline_comment[:new_pos])
    end

    it 'logs its progress' do
      expect_log(stage: 'import_inline_comments', message: 'starting', iid: merge_request.iid, comment_id: 7)
      expect_log(stage: 'import_inline_comments', message: 'finished', iid: merge_request.iid, comment_id: 7)

      importer.execute(pr_inline_comment)
    end

    context 'when one of the comments has no associated author' do
      let(:pr_inline_comment) { super().merge(author_username: nil) }

      it 'creates the comment without an author' do
        expect { importer.execute(pr_inline_comment) }.to change { Note.count }.by(2)

        start_note, reply_note = merge_request.notes.order(:id).to_a

        expect(start_note.author_id).to eq(project.creator_id)
        expect(reply_note.author_id).to eq(reply_source_user.mapped_user_id)
      end

      it 'does not push placeholder references for that comment' do
        importer.execute(pr_inline_comment)

        expect(cached_references).to contain_exactly(
          ['DiffNote', instance_of(Integer), 'author_id', reply_source_user.id]
        )
      end
    end

    context 'when note has @ username mentions' do
      let(:original_text) { "Attention: @ali has worked on this. @fred's work from @.ali-ce/group#9?" }
      let(:expected_text) { "Attention: `@ali` has worked on this. `@fred`'s work from `@.ali-ce/group#9`?" }
      let(:mention_reply) do
        {
          author_email: 'reply_author@example.org',
          author_username: 'reply_author',
          note: original_text,
          created_at: now,
          updated_at: now,
          parent_comment_note: nil
        }
      end

      let(:mention_comment) do
        {
          id: 7,
          file_type: 'ADDED',
          from_sha: 'c5f4288162e2e6218180779c7f6ac1735bb56eab',
          to_sha: 'a4c2164330f2549f67c13f36a93884cf66e976be',
          file_path: '.gitmodules',
          old_pos: nil,
          new_pos: 4,
          note: original_text,
          author_email: 'inline_note_author@example.org',
          author_username: 'inline_note_author',
          comments: [mention_reply],
          created_at: now,
          updated_at: now,
          parent_comment_note: nil
        }
      end

      it 'inserts backticks around the mentions' do
        importer.execute(mention_comment)

        notes = merge_request.notes.order(:id).to_a
        start_note = notes.first
        expect(start_note.note).to end_with(expected_text)

        reply_note = notes.last
        expect(reply_note.note).to eq(expected_text)
      end
    end

    context 'when note is invalid' do
      let(:invalid_comment) do
        pr_inline_comment.merge(
          old_pos: 3,
          note: '',
          comments: []
        )
      end

      it 'fallback to basic note' do
        expect { importer.execute(invalid_comment) }.to change { Note.count }.by(1)

        expect(merge_request.discussions.count).to eq(1)

        notes = merge_request.notes.order(:id).to_a
        start_note = notes.first
        expect(start_note.note).to start_with("*Comment on .gitmodules:3 --> .gitmodules:4*")
        expect(start_note.created_at).to eq(invalid_comment[:created_at])
        expect(start_note.updated_at).to eq(invalid_comment[:updated_at])
      end

      it 'logs its fallback' do
        expect_log(
          stage: 'create_diff_note',
          message: 'creating standalone fallback for DiffNote',
          iid: merge_request.iid,
          comment_id: 7
        )

        importer.execute(invalid_comment)
      end
    end

    context 'when user contribution mapping is disabled' do
      let_it_be(:reply_author) { create(:user, username: 'reply_author', email: 'reply_author@example.org') }
      let_it_be(:inline_note_author) do
        create(:user, username: 'inline_note_author', email: 'inline_note_author@example.org')
      end

      before do
        project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false }).save!
      end

      it 'imports the threaded discussion' do
        expect { importer.execute(pr_inline_comment) }.to change { Note.count }.by(2)

        expect(merge_request.discussions.count).to eq(1)

        notes = merge_request.notes.order(:id).to_a
        start_note = notes.first
        expect(start_note.author_id).to eq(inline_note_author.id)

        reply_note = notes.last
        expect(reply_note.author_id).to eq(reply_author.id)
      end

      it 'does not push placeholder references' do
        importer.execute(pr_inline_comment)

        expect(cached_references).to be_empty
      end
    end
  end
end
