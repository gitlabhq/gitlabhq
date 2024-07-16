# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::Importers::PullRequestNotesImporter, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let_it_be(:project) do
    create(:project, :repository, :import_started,
      import_data_attributes: {
        credentials: { 'base_uri' => 'http://bitbucket.org/', 'user' => 'bitbucket', 'password' => 'password' }
      }
    )
  end

  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:merge_request_diff) { create(:merge_request_diff, :external, merge_request: merge_request) }
  let_it_be(:bitbucket_user) { create(:user) }
  let_it_be(:identity) { create(:identity, user: bitbucket_user, extern_uid: '{123}', provider: :bitbucket) }
  let(:hash) { { iid: merge_request.iid } }
  let(:client) { Bitbucket::Client.new({}) }
  let(:ref_converter) { Gitlab::BitbucketImport::RefConverter.new(project) }
  let(:user_finder) { Gitlab::BitbucketImport::UserFinder.new(project) }
  let(:mentions_converter) { Gitlab::Import::MentionsConverter.new('bitbucket', project) }
  let(:note_body) { 'body' }
  let(:comments) { [Bitbucket::Representation::PullRequestComment.new(note_hash)] }
  let(:created_at) { Date.today - 2.days }
  let(:updated_at) { Date.today }
  let(:note_hash) do
    {
      'id' => 12,
      'user' => { 'nickname' => 'bitbucket_user', 'uuid' => '{123}' },
      'content' => { 'raw' => note_body },
      'created_on' => created_at,
      'updated_on' => updated_at
    }
  end

  subject(:importer) { described_class.new(project, hash) }

  before do
    allow(Bitbucket::Client).to receive(:new).and_return(client)
    allow(Gitlab::BitbucketImport::RefConverter).to receive(:new).and_return(ref_converter)
    allow(Gitlab::BitbucketImport::UserFinder).to receive(:new).and_return(user_finder)
    allow(Gitlab::Import::MentionsConverter).to receive(:new).and_return(mentions_converter)
    allow(client).to receive(:pull_request_comments).and_return(comments)
  end

  describe '#execute' do
    context 'for standalone pr comments' do
      it 'calls RefConverter' do
        expect(ref_converter).to receive(:convert_note).once.and_call_original

        importer.execute
      end

      it 'converts mentions in the comment' do
        expect(mentions_converter).to receive(:convert).once.and_call_original

        importer.execute
      end

      it 'creates a note with the correct attributes' do
        expect { importer.execute }.to change { merge_request.notes.count }.from(0).to(1)

        note = merge_request.notes.first

        expect(note.note).to eq(note_body)
        expect(note.author).to eq(bitbucket_user)
        expect(note.created_at).to eq(created_at)
        expect(note.updated_at).to eq(updated_at)
        expect(note.imported_from).to eq('bitbucket')
      end

      context 'when the author does not have a bitbucket identity' do
        before do
          identity.update!(provider: :github)
        end

        it 'sets the author to the project creator and adds the author to the note' do
          importer.execute

          note = merge_request.notes.first

          expect(note.author).to eq(project.creator)
          expect(note.note).to eq("*Created by: bitbucket_user*\n\nbody")
        end
      end

      context 'when the note is deleted' do
        let(:note_hash) do
          {
            'id' => 12,
            'user' => { 'nickname' => 'bitbucket_user', 'uuid' => '{123}' },
            'content' => { 'raw' => note_body },
            'deleted' => true,
            'created_on' => created_at,
            'updated_on' => updated_at
          }
        end

        it 'does not create a note' do
          expect { importer.execute }.not_to change { merge_request.notes.count }
        end
      end
    end

    context 'for threaded inline comments' do
      let(:path) { project.repository.commit.raw_diffs.first.new_path }
      let(:reply_body) { 'Some reply' }
      let(:comments) do
        [
          Bitbucket::Representation::PullRequestComment.new(pr_comment_1),
          Bitbucket::Representation::PullRequestComment.new(pr_comment_2)
        ]
      end

      let(:pr_comment_1) do
        {
          'id' => 14,
          'inline' => {
            'path' => path,
            'from' => nil,
            'to' => 1
          },
          'parent' => { 'id' => 13 },
          'user' => { 'nickname' => 'bitbucket_user', 'uuid' => '{123}' },
          'content' => { 'raw' => reply_body },
          'created_on' => created_at,
          'updated_on' => updated_at
        }
      end

      let(:pr_comment_2) do
        {
          'id' => 13,
          'inline' => {
            'path' => path,
            'from' => nil,
            'to' => 1
          },
          'user' => { 'nickname' => 'non_existent_user', 'uuid' => '{456}' },
          'content' => { 'raw' => note_body },
          'created_on' => created_at,
          'updated_on' => updated_at
        }
      end

      it 'creates notes in the correct position with the right attributes' do
        expect { importer.execute }.to change { merge_request.notes.count }.from(0).to(2)

        expect(merge_request.notes.map(&:discussion_id).uniq.count).to eq(1)

        notes = merge_request.notes.order(:id).to_a

        start_note = notes.first
        expect(start_note).to be_a(DiffNote)
        expect(start_note.note).to eq("*Created by: non_existent_user*\n\n#{note_body}")
        expect(start_note.author).to eq(project.creator)

        reply_note = notes.last
        expect(reply_note).to be_a(DiffNote)
        expect(reply_note.note).to eq(reply_body)
        expect(reply_note.author).to eq(bitbucket_user)
      end

      context 'when the comments are not part of the diff' do
        let(:pr_comment_1) do
          {
            'id' => 14,
            'inline' => {
              'path' => path,
              'from' => nil,
              'to' => nil
            },
            'parent' => { 'id' => 13 },
            'user' => { 'nickname' => 'bitbucket_user', 'uuid' => '{123}' },
            'content' => { 'raw' => reply_body },
            'created_on' => created_at,
            'updated_on' => updated_at
          }
        end

        let(:pr_comment_2) do
          {
            'id' => 13,
            'inline' => {
              'path' => path,
              'from' => nil,
              'to' => nil
            },
            'user' => { 'nickname' => 'bitbucket_user', 'uuid' => '{123}' },
            'content' => { 'raw' => note_body },
            'created_on' => created_at,
            'updated_on' => updated_at
          }
        end

        it 'creates them as normal notes' do
          expect { importer.execute }.to change { merge_request.notes.count }.from(0).to(2)

          notes = merge_request.notes.order(:id).to_a

          first_note = notes.first
          expect(first_note).not_to be_a(DiffNote)
          expect(first_note.note).to eq("*Comment on*\n\n#{note_body}")
          expect(first_note.author).to eq(bitbucket_user)

          second_note = notes.last
          expect(second_note).not_to be_a(DiffNote)
          expect(second_note.note).to eq("*Comment on*\n\n#{reply_body}")
          expect(second_note.author).to eq(bitbucket_user)
        end
      end

      context 'when an error is raised for one note' do
        before do
          allow(user_finder).to receive(:gitlab_user_id).and_call_original
          allow(user_finder).to receive(:gitlab_user_id).with(project, '{123}').and_raise(StandardError)
        end

        it 'tracks the error and continues to import other notes' do
          expect(Gitlab::ErrorTracking).to receive(:log_exception)
            .with(anything, hash_including(comment_id: 14)).and_call_original

          expect { importer.execute }.to change { merge_request.notes.count }.from(0).to(1)
        end
      end
    end

    context 'when the merge request does not exist' do
      let(:hash) { { iid: 'nonexistent' } }

      it 'does not call #import_pull_request_comments' do
        expect(importer).not_to receive(:import_pull_request_comments)

        importer.execute
      end
    end

    context 'when the merge request exists but not for this project' do
      let_it_be(:another_project) { create(:project) }

      before do
        merge_request.update!(source_project: another_project, target_project: another_project)
      end

      it 'does not call #import_pull_request_comments' do
        expect(importer).not_to receive(:import_pull_request_comments)

        importer.execute
      end
    end

    context 'when an error is raised' do
      before do
        allow(importer).to receive(:import_pull_request_comments).and_raise(StandardError)
      end

      it 'tracks the failure and does not fail' do
        expect(Gitlab::Import::ImportFailureService).to receive(:track).once

        importer.execute
      end
    end
  end
end
