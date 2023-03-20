# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::ImportIssueEventWorker, feature_category: :importers do
  subject(:worker) { described_class.new }

  describe '#import' do
    let(:import_state) { create(:import_state, :started) }

    let(:project) do
      instance_double('Project', full_path: 'foo/bar', id: 1, import_state: import_state)
    end

    let(:client) { instance_double('Gitlab::GithubImport::Client') }
    let(:importer) { instance_double('Gitlab::GithubImport::Importer::IssueEventImporter') }

    let(:event_hash) do
      {
        'id' => 6501124486,
        'node_id' => 'CE_lADOHK9fA85If7x0zwAAAAGDf0mG',
        'url' => 'https://api.github.com/repos/elhowm/test-import/issues/events/6501124486',
        'actor' => { 'id' => 4, 'login' => 'alice' },
        'event' => 'closed',
        'commit_id' => nil,
        'commit_url' => nil,
        'created_at' => '2022-04-26 18:30:53 UTC',
        'performed_via_github_app' => nil
      }
    end

    it 'imports an issue event' do
      expect(Gitlab::GithubImport::Importer::IssueEventImporter)
        .to receive(:new)
        .with(
          an_instance_of(Gitlab::GithubImport::Representation::IssueEvent),
          project,
          client
        )
        .and_return(importer)

      expect(importer).to receive(:execute)

      expect(Gitlab::GithubImport::ObjectCounter)
        .to receive(:increment)
        .and_call_original

      worker.import(project, client, event_hash)
    end
  end
end
