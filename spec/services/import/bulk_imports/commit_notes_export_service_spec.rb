# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BulkImports::CommitNotesExportService, feature_category: :importers do
  let_it_be(:project) { create(:project, :small_repo) }
  let_it_be(:commit_sha) { project.repository.commit.id }
  let_it_be(:commit_note) { create(:note_on_commit, project: project, commit_id: commit_sha, note: 'review feedback') }
  let_it_be(:export) { create(:bulk_import_export, project: project, relation: 'commit_notes') }

  let(:export_path) { Dir.mktmpdir('commit_notes_export_service_spec') }

  subject(:service) { described_class.new(export, export_path, project.owner) }

  after do
    FileUtils.rm_rf(export_path)
  end

  it 'inherits from TreeExportService' do
    expect(described_class.superclass).to eq(BulkImports::TreeExportService)
  end

  describe '#exported_filename' do
    it 'returns commit_notes.ndjson' do
      expect(service.exported_filename).to eq('commit_notes.ndjson')
    end
  end

  describe '#execute' do
    it 'writes commit_notes serialized as ndjson', :aggregate_failures do
      service.execute

      records = ndjson_records
      expect(records.size).to eq(1)
      expect(records.first).to include('note' => 'review feedback', 'commit_id' => commit_sha)
    end

    it 'increments exported_objects_count' do
      expect { service.execute }.to change { service.exported_objects_count }.from(0).to(1)
    end

    it 'does not export or count a note on the same commit_id that belongs to another project' do
      other_project = create(:project)
      create(:note_on_commit, project: other_project, commit_id: commit_sha, note: 'from another project')

      expect { service.execute }.to change { service.exported_objects_count }.from(0).to(1)

      records = ndjson_records
      expect(records.map { |record| record['note'] }).to contain_exactly('review feedback')
    end

    context 'when there are no commit notes' do
      let_it_be(:project) { create(:project, :small_repo) }
      let_it_be(:commit_note) { nil }
      let_it_be(:export) { create(:bulk_import_export, project: project, relation: 'commit_notes') }

      it 'does not walk the repository' do
        expect(Import::Export::Project::CommitNotesBatcher).not_to receive(:new)

        service.execute
      end

      it 'does not write the output file' do
        service.execute

        expect(File.exist?(File.join(export_path, 'commit_notes.ndjson'))).to be(false)
      end
    end
  end

  describe '#export_batch' do
    it 'serializes the given commit-note IDs' do
      service.export_batch([commit_note.id])

      records = ndjson_records
      expect(records.size).to eq(1)
      expect(records.first).to include('commit_id' => commit_sha)
    end

    it 'serializes nothing for IDs that are not this project\'s commit notes' do
      issue = create(:issue, project: project)
      issue_note = create(:note, project: project, noteable: issue)

      service.export_batch([issue_note.id])

      expect(service.exported_objects_count).to eq(0)
      # Pipeline gzips exported_filename after this, so an empty file must exist.
      file = File.join(export_path, 'commit_notes.ndjson')
      expect(File.exist?(file)).to be(true)
      expect(File.size(file)).to eq(0)
    end

    it 'creates an empty export file when given an empty array' do
      service.export_batch([])

      expect(service.exported_objects_count).to eq(0)
      expect(File.exist?(File.join(export_path, 'commit_notes.ndjson'))).to be(true)
    end
  end

  def ndjson_records
    file = File.join(export_path, 'commit_notes.ndjson')
    return [] unless File.exist?(file)

    File.foreach(file).map { |line| Gitlab::Json.safe_parse(line) }
  end
end
