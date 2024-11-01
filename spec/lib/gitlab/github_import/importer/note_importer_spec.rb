# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::NoteImporter, feature_category: :importers do
  let_it_be(:imported_from) { ::Import::HasImportSource::IMPORT_SOURCES[:github] }
  let_it_be(:project) { create(:project, :with_import_url) }
  let_it_be(:user) { create(:user) }

  let_it_be(:source_user) do
    create(:import_source_user,
      placeholder_user_id: user.id,
      namespace_id: project.root_ancestor.id,
      source_user_identifier: '4',
      source_hostname: project.import_url
    )
  end

  let(:client) { double(:client) }
  let(:created_at) { Time.new(2017, 1, 1, 12, 00) }
  let(:updated_at) { Time.new(2017, 1, 1, 12, 15) }
  let(:note_body) { 'This is my note' }
  let(:import_state) { create(:import_state, :started, project: project) }

  let(:github_note) do
    Gitlab::GithubImport::Representation::Note.new(
      note_id: 100,
      noteable_id: 1,
      noteable_type: 'Issue',
      author: Gitlab::GithubImport::Representation::User.new(id: 4, login: 'alice', email: 'alice@alice.com'),
      note: note_body,
      created_at: created_at,
      updated_at: updated_at
    )
  end

  let(:importer) { described_class.new(github_note, project, client) }
  let(:user_mapping_enabled) { true }

  before do
    project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: user_mapping_enabled })
  end

  describe '#execute' do
    context 'when the noteable exists' do
      let!(:issue_row) { create(:issue, project: project, iid: 1) }

      before do
        allow(importer)
          .to receive(:find_noteable_id)
          .and_return(issue_row.id)
      end

      context 'when user_mapping_enabled is true' do
        it 'maps the correct user and pushes a reference' do
          expect(importer.user_finder).to receive(:author_id_for).with(github_note).and_call_original

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
                  author_id: source_user.mapped_user_id,
                  note: 'This is my note',
                  discussion_id: match(/\A[0-9a-f]{40}\z/),
                  system: false,
                  created_at: created_at,
                  updated_at: updated_at,
                  imported_from: imported_from
                }
              ],
              { return_ids: true }
            )
            .and_call_original

          expect_next_instance_of(::Import::PlaceholderReferences::PushService,
            import_source: ::Import::SOURCE_GITHUB,
            import_uid: project.import_state.id,
            source_user_id: source_user.id,
            source_user_namespace_id: project.root_ancestor.id,
            model: Note,
            user_reference_column: :author_id,
            numeric_key: an_instance_of(Integer)) do |push_service|
              expect(push_service).to receive(:execute).and_call_original
            end

          importer.execute
        end
      end

      context 'when user_mapping_enabled is false' do
        let(:user_mapping_enabled) { false }

        before do
          allow(importer.user_finder)
            .to receive(:email_for_github_username)
            .and_return('alice@alice.com')
        end

        context 'when the author could be found' do
          it 'imports the note with the found author as the note author and does not push a placeholder reference' do
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
                    updated_at: updated_at,
                    imported_from: imported_from
                  }
                ],
                { return_ids: true }
              )
              .and_call_original

            expect(::Import::PlaceholderReferences::PushService)
              .not_to receive(:new)

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
                    updated_at: updated_at,
                    imported_from: imported_from
                  }
                ],
                {
                  return_ids: true
                }
              )
              .and_call_original

            importer.execute
          end
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

    context 'when the description has user mentions' do
      let(:note_body) { 'You can ask @knejad by emailing xyz@gitlab.com' }

      it 'adds backticks to the username' do
        issue_row = create(:issue, project: project, iid: 1)

        allow(importer)
          .to receive(:find_noteable_id)
          .and_return(issue_row.id)

        allow(importer.user_finder)
          .to receive(:author_id_for)
          .with(github_note)
          .and_return([user.id, true])

        importer.execute

        expect(project.notes.last.note).to eq("You can ask `@knejad` by emailing xyz@gitlab.com")
      end
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
