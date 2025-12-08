# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Attachments::ImportNoteWorker, feature_category: :importers do
  subject(:worker) { described_class.new }

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

  describe '#import' do
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

  describe '#perform' do
    let_it_be(:project) { create(:project) }
    let_it_be(:import_state) { create(:import_state, :started, project: project) }

    context 'when rate limited' do
      before do
        allow(Gitlab::GithubImport).to receive(:new_client_for).and_return(client)
        allow(client).to receive(:rate_limit_resets_in).and_return(10)
        allow(Gitlab::GithubImport::Importer::NoteAttachmentsImporter).to receive(:new).and_return(importer)
      end

      it 'reschedules the job when RateLimitError is raised' do
        expect(importer).to receive(:execute).and_raise(Gitlab::GithubImport::RateLimitError, 'Rate limit exceeded')
        expect(described_class).to receive(:perform_in).with(a_kind_of(Numeric), project.id, note_hash, '')

        worker.perform(project.id, note_hash, nil)
      end
    end
  end
end
