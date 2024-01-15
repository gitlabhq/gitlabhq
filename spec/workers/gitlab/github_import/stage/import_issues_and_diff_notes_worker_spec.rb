# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportIssuesAndDiffNotesWorker, feature_category: :importers do
  let_it_be(:project) { create(:project) }

  let(:settings) { ::Gitlab::GithubImport::Settings.new(project.reload) }
  let(:single_endpoint_optional_stage) { true }

  subject(:worker) { described_class.new }

  before do
    settings.write({ optional_stages: { single_endpoint_notes_import: single_endpoint_optional_stage } })
  end

  it_behaves_like Gitlab::GithubImport::StageMethods

  describe '#import' do
    it 'imports the issues and diff notes' do
      client = double(:client)

      worker.importers(project).each do |klass|
        importer = double(:importer)
        waiter = Gitlab::JobWaiter.new(2, '123')

        expect(klass)
          .to receive(:new)
          .with(project, client)
          .and_return(importer)

        expect(importer)
          .to receive(:execute)
          .and_return(waiter)
      end

      expect(Gitlab::GithubImport::AdvanceStageWorker)
        .to receive(:perform_async)
        .with(project.id, { '123' => 2 }, 'issue_events')

      worker.import(client, project)
    end
  end

  describe '#importers' do
    context 'when optional stage single_endpoint_notes_import is enabled' do
      it 'includes single endpoint diff notes importer' do
        expect(worker.importers(project)).to contain_exactly(
          Gitlab::GithubImport::Importer::IssuesImporter,
          Gitlab::GithubImport::Importer::SingleEndpointDiffNotesImporter
        )
      end
    end

    context 'when optional stage single_endpoint_notes_import is disabled' do
      let(:single_endpoint_optional_stage) { false }

      it 'includes default diff notes importer' do
        expect(worker.importers(project)).to contain_exactly(
          Gitlab::GithubImport::Importer::IssuesImporter,
          Gitlab::GithubImport::Importer::DiffNotesImporter
        )
      end
    end
  end
end
