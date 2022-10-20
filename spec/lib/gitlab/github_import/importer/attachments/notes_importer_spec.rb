# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Attachments::NotesImporter do
  subject(:importer) { described_class.new(project, client) }

  let_it_be(:project) { create(:project) }

  let(:client) { instance_double(Gitlab::GithubImport::Client) }

  describe '#sequential_import', :clean_gitlab_redis_cache do
    let_it_be(:note_1) { create(:note, project: project) }
    let_it_be(:note_2) { create(:note, project: project) }
    let_it_be(:system_note) { create(:note, :system, project: project) }

    let(:importer_stub) { instance_double('Gitlab::GithubImport::Importer::NoteAttachmentsImporter') }
    let(:importer_attrs) { [instance_of(Gitlab::GithubImport::Representation::NoteText), project, client] }

    it 'imports each project user note' do
      expect(Gitlab::GithubImport::Importer::NoteAttachmentsImporter).to receive(:new)
        .with(*importer_attrs).twice.and_return(importer_stub)
      expect(importer_stub).to receive(:execute).twice

      importer.sequential_import
    end

    context 'when note is already processed' do
      it "doesn't import this note" do
        importer.mark_as_imported(note_1)

        expect(Gitlab::GithubImport::Importer::NoteAttachmentsImporter).to receive(:new)
          .with(*importer_attrs).once.and_return(importer_stub)
        expect(importer_stub).to receive(:execute).once

        importer.sequential_import
      end
    end
  end

  describe '#sidekiq_worker_class' do
    it { expect(importer.sidekiq_worker_class).to eq(Gitlab::GithubImport::Attachments::ImportNoteWorker) }
  end

  describe '#collection_method' do
    it { expect(importer.collection_method).to eq(:note_attachments) }
  end

  describe '#object_type' do
    it { expect(importer.object_type).to eq(:note_attachment) }
  end

  describe '#id_for_already_imported_cache' do
    let(:note) { build_stubbed(:note) }

    it { expect(importer.id_for_already_imported_cache(note)).to eq(note.id) }
  end
end
