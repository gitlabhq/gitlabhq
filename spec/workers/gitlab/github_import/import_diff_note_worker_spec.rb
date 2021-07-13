# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::ImportDiffNoteWorker do
  let(:worker) { described_class.new }

  describe '#import' do
    it 'imports a diff note' do
      project = double(:project, full_path: 'foo/bar', id: 1)
      client = double(:client)
      importer = double(:importer)
      hash = {
        'noteable_id' => 42,
        'github_id' => 42,
        'path' => 'README.md',
        'commit_id' => '123abc',
        'diff_hunk' => "@@ -1 +1 @@\n-Hello\n+Hello world",
        'user' => { 'id' => 4, 'login' => 'alice' },
        'note' => 'Hello world',
        'created_at' => Time.zone.now.to_s,
        'updated_at' => Time.zone.now.to_s
      }

      expect(Gitlab::GithubImport::Importer::DiffNoteImporter)
        .to receive(:new)
        .with(
          an_instance_of(Gitlab::GithubImport::Representation::DiffNote),
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
