require 'spec_helper'

describe Gitlab::GithubImport::ImportNoteWorker do
  let(:worker) { described_class.new }

  describe '#import' do
    it 'imports a note' do
      project = double(:project, full_path: 'foo/bar')
      client = double(:client)
      importer = double(:importer)
      hash = {
        'noteable_id' => 42,
        'noteable_type' => 'issues',
        'user' => { 'id' => 4, 'login' => 'alice' },
        'note' => 'Hello world',
        'created_at' => Time.zone.now.to_s,
        'updated_at' => Time.zone.now.to_s
      }

      expect(Gitlab::GithubImport::Importer::NoteImporter)
        .to receive(:new)
        .with(
          an_instance_of(Gitlab::GithubImport::Representation::Note),
          project,
          client
        )
        .and_return(importer)

      expect(importer)
        .to receive(:execute)

      expect(worker.counter)
        .to receive(:increment)
        .with(project: 'foo/bar')
        .and_call_original

      worker.import(project, client, hash)
    end
  end
end
