# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GithubImport::Importer::DiffNoteImporter do
  let(:project) { create(:project) }
  let(:client) { double(:client) }
  let(:user) { create(:user) }
  let(:created_at) { Time.new(2017, 1, 1, 12, 00) }
  let(:updated_at) { Time.new(2017, 1, 1, 12, 15) }

  let(:hunk) do
    '@@ -1 +1 @@
    -Hello
    +Hello world'
  end

  let(:note) do
    Gitlab::GithubImport::Representation::DiffNote.new(
      noteable_type: 'MergeRequest',
      noteable_id: 1,
      commit_id: '123abc',
      file_path: 'README.md',
      diff_hunk: hunk,
      author: Gitlab::GithubImport::Representation::User
        .new(id: user.id, login: user.username),
      note: 'Hello',
      created_at: created_at,
      updated_at: updated_at,
      github_id: 1
    )
  end

  let(:importer) { described_class.new(note, project, client) }

  describe '#execute' do
    context 'when the merge request no longer exists' do
      it 'does not import anything' do
        expect(Gitlab::Database).not_to receive(:bulk_insert)

        importer.execute
      end
    end

    context 'when the merge request exists' do
      let!(:merge_request) do
        create(:merge_request, source_project: project, target_project: project)
      end

      before do
        allow(importer)
          .to receive(:find_merge_request_id)
          .and_return(merge_request.id)
      end

      it 'imports the note' do
        allow(importer.user_finder)
          .to receive(:author_id_for)
          .and_return([user.id, true])

        expect(Gitlab::Database)
          .to receive(:bulk_insert)
          .with(
            LegacyDiffNote.table_name,
            [
              {
                noteable_type: 'MergeRequest',
                noteable_id: merge_request.id,
                project_id: project.id,
                author_id: user.id,
                note: 'Hello',
                system: false,
                commit_id: '123abc',
                line_code: note.line_code,
                type: 'LegacyDiffNote',
                created_at: created_at,
                updated_at: updated_at,
                st_diff: note.diff_hash.to_yaml
              }
            ]
          )
          .and_call_original

        importer.execute
      end

      it 'imports the note when the author could not be found' do
        allow(importer.user_finder)
          .to receive(:author_id_for)
          .and_return([project.creator_id, false])

        expect(Gitlab::Database)
          .to receive(:bulk_insert)
          .with(
            LegacyDiffNote.table_name,
            [
              {
                noteable_type: 'MergeRequest',
                noteable_id: merge_request.id,
                project_id: project.id,
                author_id: project.creator_id,
                note: "*Created by: #{user.username}*\n\nHello",
                system: false,
                commit_id: '123abc',
                line_code: note.line_code,
                type: 'LegacyDiffNote',
                created_at: created_at,
                updated_at: updated_at,
                st_diff: note.diff_hash.to_yaml
              }
            ]
          )
          .and_call_original

        importer.execute
      end

      it 'produces a valid LegacyDiffNote' do
        allow(importer.user_finder)
          .to receive(:author_id_for)
          .and_return([user.id, true])

        importer.execute

        note = project.notes.diff_notes.take

        expect(note).to be_valid
        expect(note.diff).to be_an_instance_of(Gitlab::Git::Diff)
      end

      it 'does not import the note when a foreign key error is raised' do
        allow(importer.user_finder)
          .to receive(:author_id_for)
          .and_return([project.creator_id, false])

        expect(Gitlab::Database)
          .to receive(:bulk_insert)
          .and_raise(ActiveRecord::InvalidForeignKey, 'invalid foreign key')

        expect { importer.execute }.not_to raise_error
      end
    end
  end

  describe '#find_merge_request_id' do
    it 'returns a merge request ID' do
      expect_any_instance_of(Gitlab::GithubImport::IssuableFinder)
        .to receive(:database_id)
        .and_return(10)

      expect(importer.find_merge_request_id).to eq(10)
    end
  end
end
