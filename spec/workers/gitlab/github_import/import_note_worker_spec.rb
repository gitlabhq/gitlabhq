# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::ImportNoteWorker, feature_category: :importers do
  let(:worker) { described_class.new }

  describe '#import' do
    it 'imports a note' do
      import_state = create(:import_state, :started)
      project = double(:project, full_path: 'foo/bar', id: 1, import_state: import_state)
      client = double(:client)
      importer = double(:importer)
      hash = {
        'noteable_id' => 42,
        'github_id' => 42,
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

      expect(Gitlab::GithubImport::ObjectCounter)
        .to receive(:increment)
        .and_call_original

      worker.import(project, client, hash)
    end
  end
end
