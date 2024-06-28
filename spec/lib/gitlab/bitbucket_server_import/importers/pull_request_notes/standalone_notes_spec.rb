# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importers::PullRequestNotes::StandaloneNotes, feature_category: :importers do
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
  let_it_be(:note_author) { create(:user, username: 'note_author', email: 'note_author@example.org') }
  let_it_be(:mentions_converter) { Gitlab::Import::MentionsConverter.new('bitbucket_server', project) }

  let(:pr_comment) do
    {
      id: 5,
      note: 'Hello world',
      author_email: note_author.email,
      author_username: note_author.username,
      comments: [],
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
    it 'imports the stand alone comments' do
      expect(mentions_converter).to receive(:convert).and_call_original

      expect { importer.execute(pr_comment) }.to change { Note.count }.by(1)

      expect(merge_request.notes.count).to eq(1)
      expect(merge_request.notes.first).to have_attributes(
        note: end_with(pr_comment[:note]),
        author: note_author,
        created_at: pr_comment[:created_at],
        updated_at: pr_comment[:created_at],
        imported_from: 'bitbucket_server'
      )
    end

    context 'when the note has multiple comments' do
      let(:pr_comment_extra) do
        {
          id: 6,
          note: 'Foo bar',
          author_email: note_author.email,
          author_username: note_author.username,
          comments: [],
          created_at: now,
          updated_at: now,
          parent_comment_note: nil,
          imported_from: 'bitbucket_server'
        }
      end

      let(:pr_comment) do
        {
          id: 5,
          note: 'Hello world',
          author_email: note_author.email,
          author_username: note_author.username,
          comments: [pr_comment_extra],
          created_at: now,
          updated_at: now,
          parent_comment_note: nil,
          imported_from: 'bitbucket_server'
        }
      end

      it 'imports multiple comments' do
        expect(mentions_converter).to receive(:convert).and_call_original.twice

        expect { importer.execute(pr_comment) }.to change { Note.count }.by(2)

        expect(merge_request.notes.count).to eq(2)
        expect(merge_request.notes.first).to have_attributes(
          note: end_with(pr_comment[:note]),
          author: note_author,
          created_at: pr_comment[:created_at],
          updated_at: pr_comment[:created_at],
          imported_from: 'bitbucket_server'
        )
        expect(merge_request.notes.last).to have_attributes(
          note: end_with(pr_comment_extra[:note]),
          author: note_author,
          created_at: pr_comment_extra[:created_at],
          updated_at: pr_comment_extra[:created_at],
          imported_from: 'bitbucket_server'
        )
      end
    end

    context 'when the author is not found' do
      before do
        allow_next_instance_of(Gitlab::BitbucketServerImport::UserFinder) do |user_finder|
          allow(user_finder).to receive(:uid).and_return(nil)
        end
      end

      it 'adds a note with the author username and email' do
        importer.execute(pr_comment)

        expect(Note.first.note).to include("*By #{note_author.username} (#{note_author.email})")
      end
    end

    context 'when the note has a parent note' do
      let(:pr_comment) do
        {
          id: 5,
          note: 'Note',
          author_email: note_author.email,
          author_username: note_author.username,
          comments: [],
          created_at: now,
          updated_at: now,
          parent_comment_note: 'Parent note',
          imported_from: 'bitbucket_server'
        }
      end

      it 'adds the parent note before the actual note' do
        importer.execute(pr_comment)

        expect(Note.first.note).to include("> #{pr_comment[:parent_comment_note]}\n\n")
      end

      it 'logs its progress' do
        expect_log(
          stage: 'import_standalone_notes_comments',
          message: 'starting',
          iid: merge_request.iid,
          comment_id: 5
        )
        expect_log(
          stage: 'import_standalone_notes_comments',
          message: 'finished',
          iid: merge_request.iid,
          comment_id: 5
        )

        importer.execute(pr_comment)
      end
    end

    context 'when saving notes is failed' do
      before do
        allow(merge_request.notes).to receive(:create!).and_raise(StandardError)
      end

      it 'logs its exception' do
        expect(mentions_converter).to receive(:convert).and_call_original
        expect(Gitlab::ErrorTracking).to receive(:log_exception)
          .with(StandardError, include(import_stage: 'import_standalone_notes_comments'))

        importer.execute(pr_comment)
      end
    end
  end
end
