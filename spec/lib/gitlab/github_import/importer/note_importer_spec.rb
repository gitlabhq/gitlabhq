# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::NoteImporter, feature_category: :importers do
  let(:client) { double(:client) }
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:created_at) { Time.new(2017, 1, 1, 12, 00) }
  let(:updated_at) { Time.new(2017, 1, 1, 12, 15) }
  let(:note_body) { 'This is my note' }

  let(:github_note) do
    Gitlab::GithubImport::Representation::Note.new(
      note_id: 100,
      noteable_id: 1,
      noteable_type: 'Issue',
      author: Gitlab::GithubImport::Representation::User.new(id: 4, login: 'alice'),
      note: note_body,
      created_at: created_at,
      updated_at: updated_at
    )
  end

  let(:importer) { described_class.new(github_note, project, client) }

  describe '#execute' do
    context 'when the noteable exists' do
      let!(:issue_row) { create(:issue, project: project, iid: 1) }

      before do
        allow(importer)
          .to receive(:find_noteable_id)
          .and_return(issue_row.id)
      end

      context 'when the author could be found' do
        it 'imports the note with the found author as the note author' do
          expect(importer.user_finder)
            .to receive(:author_id_for)
            .with(github_note)
            .and_return([user.id, true])

          expect(ApplicationRecord)
            .to receive(:legacy_bulk_insert)
            .with(
              Note.table_name,
              [
                {
                  noteable_type: 'Issue',
                  noteable_id: issue_row.id,
                  project_id: project.id,
                  namespace_id: project.project_namespace_id,
                  author_id: user.id,
                  note: 'This is my note',
                  discussion_id: match(/\A[0-9a-f]{40}\z/),
                  system: false,
                  created_at: created_at,
                  updated_at: updated_at
                }
              ]
            )
            .and_call_original

          importer.execute
        end
      end

      context 'when the note author could not be found' do
        it 'imports the note with the project creator as the note author' do
          expect(importer.user_finder)
            .to receive(:author_id_for)
            .with(github_note)
            .and_return([project.creator_id, false])

          expect(ApplicationRecord)
            .to receive(:legacy_bulk_insert)
            .with(
              Note.table_name,
              [
                {
                  noteable_type: 'Issue',
                  noteable_id: issue_row.id,
                  project_id: project.id,
                  namespace_id: project.project_namespace_id,
                  author_id: project.creator_id,
                  note: "*Created by: alice*\n\nThis is my note",
                  discussion_id: match(/\A[0-9a-f]{40}\z/),
                  system: false,
                  created_at: created_at,
                  updated_at: updated_at
                }
              ]
            )
            .and_call_original

          importer.execute
        end
      end

      context 'when the note have invalid chars' do
        let(:note_body) { %(There were an invalid char "\u0000" <= right here) }

        it 'removes invalid chars' do
          expect(importer.user_finder)
            .to receive(:author_id_for)
            .with(github_note)
            .and_return([user.id, true])

          expect { importer.execute }
            .to change(project.notes, :count)
            .by(1)

          expect(project.notes.last.note)
            .to eq('There were an invalid char "" <= right here')
        end
      end

      context 'when note is invalid' do
        it 'fails validation' do
          expect(importer.user_finder)
            .to receive(:author_id_for)
            .with(github_note)
            .and_return([user.id, true])

          expect(github_note).to receive(:discussion_id).and_return('invalid')

          expect { importer.execute }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      context 'when noteble_id can not be found' do
        before do
          allow(importer)
            .to receive(:find_noteable_id)
            .and_return(nil)
        end

        it 'raises NoteableNotFound' do
          expect { importer.execute }.to raise_error(
            ::Gitlab::GithubImport::Exceptions::NoteableNotFound,
            'Error to find noteable_id for note'
          )
        end
      end
    end

    it 'produces a valid Note' do
      issue_row = create(:issue, project: project, iid: 1)

      allow(importer)
        .to receive(:find_noteable_id)
        .and_return(issue_row.id)

      allow(importer.user_finder)
        .to receive(:author_id_for)
        .with(github_note)
        .and_return([user.id, true])

      importer.execute

      expect(project.notes.take).to be_valid
    end
  end

  describe '#find_noteable_id' do
    it 'returns the ID of the noteable' do
      expect_next_instance_of(Gitlab::GithubImport::IssuableFinder) do |instance|
        expect(instance).to receive(:database_id).and_return(10)
      end

      expect(importer.find_noteable_id).to eq(10)
    end
  end
end
