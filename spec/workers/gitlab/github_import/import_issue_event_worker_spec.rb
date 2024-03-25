# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::ImportIssueEventWorker, feature_category: :importers do
  subject(:worker) { described_class.new }

  describe '#execute' do
    let_it_be(:project) do
      create(:project, import_url: 'https://github.com/foo/bar.git', import_state: create(:import_state, :started))
    end

    let(:client) { instance_double(Gitlab::GithubImport::Client) }
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

    it 'imports an issue event and increase importer counter' do
      expect_next_instance_of(Gitlab::GithubImport::Importer::IssueEventImporter,
        an_instance_of(Gitlab::GithubImport::Representation::IssueEvent),
        project,
        client
      ) do |importer|
        expect(importer).to receive(:execute)
      end

      expect(Gitlab::GithubImport::ObjectCounter)
        .to receive(:increment)
        .with(project, :issue_event, :imported)
        .and_call_original

      worker.import(project, client, event_hash)
    end

    context 'when event should increment a mapped importer counter' do
      before do
        stub_const('Gitlab::GithubImport::Importer::IssueEventImporter::EVENT_COUNTER_MAP', {
          'closed' => 'custom_type'
        })

        allow_next_instance_of(Gitlab::GithubImport::Importer::IssueEventImporter) do |importer|
          allow(importer).to receive(:execute)
        end
      end

      it 'increments the mapped importer counter' do
        expect(Gitlab::GithubImport::ObjectCounter).to receive(:increment).with(project, 'custom_type', :imported)

        worker.import(project, client, event_hash)
      end
    end
  end
end
