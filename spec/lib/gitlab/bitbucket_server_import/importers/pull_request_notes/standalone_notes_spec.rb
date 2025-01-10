# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importers::PullRequestNotes::StandaloneNotes, feature_category: :importers do
  include Import::UserMappingHelper

  let_it_be_with_reload(:project) do
    create(:project, :repository, :bitbucket_server_import, :import_user_mapping_enabled)
  end

  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:now) { Time.now.utc.change(usec: 0) }
  let_it_be(:author_details) do
    {
      author_name: 'John Notes',
      author_username: 'note_author',
      author_email: 'note_author@example.org'
    }
  end

  let_it_be(:pr_comment) do
    {
      id: 5,
      note: 'Hello world',
      comments: [],
      created_at: now,
      updated_at: now,
      parent_comment_note: nil
    }.merge(author_details)
  end

  let_it_be(:source_user) { generate_source_user(project, pr_comment[:author_username]) }

  let(:cached_references) { placeholder_user_references(::Import::SOURCE_BITBUCKET_SERVER, project.import_state.id) }

  def expect_log(stage:, message:, iid:, comment_id:)
    allow(Gitlab::BitbucketServerImport::Logger).to receive(:info).and_call_original
    expect(Gitlab::BitbucketServerImport::Logger)
      .to receive(:info).with(include(import_stage: stage, message: message, iid: iid, comment_id: comment_id))
  end

  subject(:importer) { described_class.new(project, merge_request) }

  describe '#execute', :clean_gitlab_redis_shared_state do
    it 'pushes placeholder reference' do
      importer.execute(pr_comment)

      expect(cached_references).to contain_exactly(
        ['Note', instance_of(Integer), 'author_id', source_user.id]
      )
    end

    it 'imports the stand alone comments' do
      expect { importer.execute(pr_comment) }.to change { Note.count }.by(1)

      expect(merge_request.notes.count).to eq(1)
      expect(merge_request.notes.first).to have_attributes(
        note: end_with(pr_comment[:note]),
        author_id: source_user.mapped_user_id,
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
          comments: [],
          created_at: now,
          updated_at: now,
          parent_comment_note: nil,
          imported_from: 'bitbucket_server'
        }.merge(author_details)
      end

      let(:pr_comment) do
        {
          id: 5,
          note: 'Hello world',
          comments: [pr_comment_extra],
          created_at: now,
          updated_at: now,
          parent_comment_note: nil,
          imported_from: 'bitbucket_server'
        }.merge(author_details)
      end

      it 'imports multiple comments' do
        expect { importer.execute(pr_comment) }.to change { Note.count }.by(2)

        expect(merge_request.notes.count).to eq(2)
        expect(merge_request.notes.first).to have_attributes(
          note: end_with(pr_comment[:note]),
          author_id: source_user.mapped_user_id,
          created_at: pr_comment[:created_at],
          updated_at: pr_comment[:created_at],
          imported_from: 'bitbucket_server'
        )
        expect(merge_request.notes.last).to have_attributes(
          note: end_with(pr_comment_extra[:note]),
          author_id: source_user.mapped_user_id,
          created_at: pr_comment_extra[:created_at],
          updated_at: pr_comment_extra[:created_at],
          imported_from: 'bitbucket_server'
        )
      end

      context 'when one of the comments has no associated author' do
        let(:pr_comment) { super().merge(author_username: nil) }

        it 'creates the comment without an author' do
          expect { importer.execute(pr_comment) }.to change { Note.count }.by(2)

          start_note, reply_note = merge_request.notes.order(:id).to_a

          expect(start_note.author_id).to eq(project.creator_id)
          expect(reply_note.author_id).to eq(source_user.mapped_user_id)
        end

        it 'does not push placeholder references for that comment' do
          importer.execute(pr_comment)

          expect(cached_references).to contain_exactly(
            ['Note', instance_of(Integer), 'author_id', source_user.id]
          )
        end
      end
    end

    context 'when note has @ username mentions' do
      let(:original_text) { "Attention: @ali has worked on this. @fred's work from @.ali-ce/group#9?" }
      let(:expected_text) { "Attention: `@ali` has worked on this. `@fred`'s work from `@.ali-ce/group#9`?" }
      let(:mention_extra_comment) do
        {
          id: 6,
          note: original_text,
          comments: [],
          created_at: now,
          updated_at: now,
          parent_comment_note: nil,
          imported_from: 'bitbucket_server'
        }.merge(author_details)
      end

      let(:mention_comment) do
        {
          id: 5,
          note: original_text,
          comments: [mention_extra_comment],
          created_at: now,
          updated_at: now,
          parent_comment_note: nil,
          imported_from: 'bitbucket_server'
        }.merge(author_details)
      end

      it 'inserts backticks around the mentions' do
        importer.execute(mention_comment)

        expect(merge_request.notes.first.note).to eq(expected_text)
        expect(merge_request.notes.last.note).to eq(expected_text)
      end
    end

    context 'when the note has a parent note' do
      let(:pr_comment) do
        {
          id: 5,
          note: 'Note',
          comments: [],
          created_at: now,
          updated_at: now,
          parent_comment_note: 'Parent note',
          imported_from: 'bitbucket_server'
        }.merge(author_details)
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
        expect(Gitlab::ErrorTracking).to receive(:log_exception)
          .with(StandardError, include(import_stage: 'import_standalone_notes_comments'))

        importer.execute(pr_comment)
      end
    end

    context 'when user contribution mapping is disabled' do
      let_it_be(:note_author) { create(:user, username: 'note_author', email: 'note_author@example.org') }

      before do
        project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false }).save!
      end

      it 'imports the merge event' do
        expect { importer.execute(pr_comment) }.to change { Note.count }.by(1)
        expect(merge_request.notes.first).to have_attributes(
          author_id: note_author.id
        )
      end

      it 'does not push placeholder references' do
        importer.execute(pr_comment)

        expect(cached_references).to be_empty
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
    end
  end
end
