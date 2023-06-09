# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::ImportCollaboratorWorker, feature_category: :importers do
  let(:worker) { described_class.new }

  describe '#import' do
    let(:project) do
      instance_double('Project', full_path: 'foo/bar', id: 1, import_state: import_state)
    end

    let(:import_state) { build_stubbed(:import_state, :started) }
    let(:client) { instance_double('Gitlab::GithubImport::Client') }
    let(:importer) { instance_double('Gitlab::GithubImport::Importer::NoteAttachmentsImporter') }

    it 'imports a collaborator' do
      allow(import_state).to receive(:in_progress?).and_return(true)

      expect(Gitlab::GithubImport::Importer::CollaboratorImporter)
        .to receive(:new)
        .with(
          an_instance_of(Gitlab::GithubImport::Representation::Collaborator),
          project,
          client
        )
        .and_return(importer)

      expect(importer).to receive(:execute)

      expect(Gitlab::GithubImport::ObjectCounter)
        .to receive(:increment)
        .and_call_original

      worker.import(
        project, client, { 'id' => 100500, 'login' => 'alice', 'role_name' => 'maintainer' }
      )
    end
  end
end
