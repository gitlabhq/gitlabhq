# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::ImportProtectedBranchWorker, feature_category: :importers do
  let(:worker) { described_class.new }

  let(:import_state) { build_stubbed(:import_state, :started) }
  let(:project) { instance_double('Project', full_path: 'foo/bar', id: 1, import_state: import_state) }
  let(:client) { instance_double('Gitlab::GithubImport::Client') }
  let(:importer) { instance_double('Gitlab::GithubImport::Importer::ProtectedBranchImporter') }

  describe '#import' do
    let(:json_hash) do
      {
        id: 'main',
        allow_force_pushes: true,
        allowed_to_push_users: []
      }
    end

    it 'imports protected branch rule' do
      allow(import_state).to receive(:in_progress?).and_return(true)

      expect(Gitlab::GithubImport::Importer::ProtectedBranchImporter)
        .to receive(:new)
        .with(
          an_instance_of(Gitlab::GithubImport::Representation::ProtectedBranch),
          project,
          client
        )
        .and_return(importer)

      expect(importer).to receive(:execute)

      expect(Gitlab::GithubImport::ObjectCounter)
        .to receive(:increment)
        .with(project, :protected_branch, :imported)

      worker.import(project, client, json_hash)
    end
  end
end
