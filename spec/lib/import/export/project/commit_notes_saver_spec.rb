# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Export::Project::CommitNotesSaver, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:commit_sha) { project.repository.commit.id }
  let_it_be(:commit_note) { create(:note_on_commit, project: project, commit_id: commit_sha, note: 'Looks good!') }

  let(:export_path) { Dir.mktmpdir('commit_notes_saver_spec') }
  let(:shared) { project.import_export_shared.tap { |s| allow(s).to receive(:export_path).and_return(export_path) } }

  subject(:saver) { described_class.new(project: project, shared: shared, user: user) }

  after do
    FileUtils.rm_rf(export_path)
  end

  describe '#save' do
    it 'returns true and writes commit_notes.ndjson with the note serialized' do
      result = saver.save

      expect(result).to be(true)
      expect(shared.errors).to be_empty

      file = File.join(export_path, 'tree', 'project', 'commit_notes.ndjson')
      expect(File.exist?(file)).to be(true)

      records = File.foreach(file).map { |line| Gitlab::Json.safe_parse(line) }
      expect(records.first).to include('note' => 'Looks good!', 'commit_id' => commit_sha)
    end

    it 'does not export a note on the same commit_id that belongs to another project' do
      other_project = create(:project)
      create(:note_on_commit, project: other_project, commit_id: commit_sha, note: 'From another project')

      expect(saver.save).to be(true)

      file = File.join(export_path, 'tree', 'project', 'commit_notes.ndjson')
      records = File.foreach(file).map { |line| Gitlab::Json.safe_parse(line) }
      notes = records.map { |record| record['note'] }
      expect(notes).to contain_exactly('Looks good!')
    end

    it 'logs a summary with the exported count' do
      allow(Gitlab::Export::Logger).to receive(:info)
      expect(Gitlab::Export::Logger).to receive(:info).with(
        hash_including(
          message: 'commit_notes exported via git repository',
          project_id: project.id,
          exported_count: 1,
          relation: Projects::ImportExport::RelationExport::COMMIT_NOTES_RELATION
        )
      )

      saver.save # rubocop:disable Rails/SaveBang -- Call CommitNotesSaver's #save, not ActiveRecord
    end

    context 'when the project has no commit notes' do
      let_it_be(:project) { create(:project, :repository) }
      let_it_be(:commit_note) { nil }

      it 'returns true without walking the repository' do
        expect(Import::Export::Project::CommitNotesBatcher).not_to receive(:new)

        expect(saver.save).to be(true)
      end
    end

    context 'when a SHA batch resolves to no notes' do
      it 'skips serialization for that batch' do
        unrelated_sha = 'a' * 40
        allow_next_instance_of(Import::Export::Project::CommitNotesBatcher) do |batcher|
          allow(batcher).to receive(:each_batch).and_yield([unrelated_sha]).and_yield([commit_sha])
        end

        expect(saver.save).to be(true)

        file = File.join(export_path, 'tree', 'project', 'commit_notes.ndjson')
        records = File.foreach(file).map { |line| Gitlab::Json.safe_parse(line) }
        expect(records.size).to eq(1)
      end
    end

    context 'when serialization raises' do
      it 'returns false and registers the error on shared' do
        allow_next_instance_of(Gitlab::ImportExport::Json::StreamingSerializer) do |serializer|
          allow(serializer).to receive(:serialize_relation).and_raise('boom')
        end

        result = saver.save

        expect(result).to be(false)
        expect(shared.errors).to include('boom')
      end
    end
  end

  it 'inherits from RelationSaver' do
    expect(described_class.superclass).to eq(Gitlab::ImportExport::Project::RelationSaver)
  end
end
