# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Attachments::ImportNoteWorker, feature_category: :importers do
  subject(:worker) { described_class.new }

  describe '#import' do
    let(:import_state) { create(:import_state, :started) }

    let(:project) do
      instance_double('Project', full_path: 'foo/bar', id: 1, import_state: import_state)
    end

    let(:client) { instance_double('Gitlab::GithubImport::Client') }
    let(:importer) { instance_double('Gitlab::GithubImport::Importer::NoteAttachmentsImporter') }

    let(:note_hash) do
      {
        'record_db_id' => rand(100),
        'record_type' => 'Note',
        'noteable_type' => 'Issue',
        'text' => <<-TEXT
          Some text...

          ![special-image](https://user-images.githubusercontent.com...)
        TEXT
      }
    end

    it 'imports an release attachments' do
      expect(Gitlab::GithubImport::Importer::NoteAttachmentsImporter)
        .to receive(:new)
        .with(
          an_instance_of(Gitlab::GithubImport::Representation::NoteText),
          project,
          client
        )
        .and_return(importer)

      expect(importer).to receive(:execute)

      expect(Gitlab::GithubImport::ObjectCounter)
        .to receive(:increment)
        .and_call_original

      worker.import(project, client, note_hash)
    end
  end
end
