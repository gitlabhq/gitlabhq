# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importers::PullRequestNotes::Inline, feature_category: :importers do
  let_it_be(:project) do
    create(:project, :repository, :import_started,
      import_data_attributes: {
        data: { 'project_key' => 'key', 'repo_slug' => 'slug' },
        credentials: { 'token' => 'token' }
      }
    )
  end

  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:now) { Time.now.utc.change(usec: 0) }
  let_it_be(:mentions_converter) { Gitlab::Import::MentionsConverter.new('bitbucket_server', project) }
  let_it_be(:reply_author) { create(:user, username: 'reply_author', email: 'reply_author@example.org') }
  let_it_be(:inline_note_author) do
    create(:user, username: 'inline_note_author', email: 'inline_note_author@example.org')
  end

  let(:reply) do
    {
      author_email: reply_author.email,
      author_username: reply_author.username,
      note: 'I agree',
      created_at: now,
      updated_at: now,
      parent_comment_note: nil
    }
  end

  let(:pr_inline_comment) do
    {
      id: 7,
      file_type: 'ADDED',
      from_sha: 'c5f4288162e2e6218180779c7f6ac1735bb56eab',
      to_sha: 'a4c2164330f2549f67c13f36a93884cf66e976be',
      file_path: '.gitmodules',
      old_pos: nil,
      new_pos: 4,
      note: 'Hello world',
      author_email: inline_note_author.email,
      author_username: inline_note_author.username,
      comments: [reply],
      created_at: now,
      updated_at: now,
      parent_comment_note: nil
    }
  end

  before do
    allow(Gitlab::Import::MentionsConverter).to receive(:new).and_return(mentions_converter)
  end

  def expect_log(stage:, message:, iid:, comment_id:)
    allow(Gitlab::BitbucketServerImport::Logger).to receive(:info).and_call_original
    expect(Gitlab::BitbucketServerImport::Logger)
      .to receive(:info).with(include(import_stage: stage, message: message, iid: iid, comment_id: comment_id))
  end

  subject(:importer) { described_class.new(project, merge_request) }

  describe '#execute' do
    it 'imports the threaded discussion' do
      expect(mentions_converter).to receive(:convert).and_call_original.twice

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
      expect(start_note.author).to eq(inline_note_author)

      reply_note = notes.last
      expect(reply_note.note).to eq(reply[:note])
      expect(reply_note.author).to eq(reply_author)
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

    context 'when note is invalid' do
      let(:invalid_comment) do
        {
          id: 7,
          file_type: 'ADDED',
          from_sha: 'c5f4288162e2e6218180779c7f6ac1735bb56eab',
          to_sha: 'a4c2164330f2549f67c13f36a93884cf66e976be',
          file_path: '.gitmodules',
          old_pos: 3,
          new_pos: 4,
          note: '',
          author_email: inline_note_author.email,
          author_username: inline_note_author.username,
          comments: [],
          created_at: now,
          updated_at: now,
          parent_comment_note: nil
        }
      end

      it 'fallback to basic note' do
        expect(mentions_converter).to receive(:convert).and_call_original.twice

        expect { importer.execute(invalid_comment) }.to change { Note.count }.by(1)

        expect(merge_request.discussions.count).to eq(1)

        notes = merge_request.notes.order(:id).to_a
        start_note = notes.first
        expect(start_note.note).to start_with("*Comment on .gitmodules:3 --> .gitmodules:4*")
        expect(start_note.created_at).to eq(invalid_comment[:created_at])
        expect(start_note.updated_at).to eq(invalid_comment[:updated_at])
      end

      it 'logs its fallback' do
        expect(mentions_converter).to receive(:convert).and_call_original.twice
        expect_log(
          stage: 'create_diff_note',
          message: 'creating standalone fallback for DiffNote',
          iid: merge_request.iid,
          comment_id: 7
        )

        importer.execute(invalid_comment)
      end
    end

    context 'when converting mention is failed' do
      it 'logs its exception' do
        expect(mentions_converter).to receive(:convert).and_raise(StandardError)
        expect(Gitlab::ErrorTracking).to receive(:log_exception)
          .with(StandardError, include(import_stage: 'create_diff_note'))

        importer.execute(pr_inline_comment)
      end
    end
  end
end
