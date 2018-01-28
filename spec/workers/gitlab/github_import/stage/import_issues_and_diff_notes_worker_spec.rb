require 'spec_helper'

describe Gitlab::GithubImport::Stage::ImportIssuesAndDiffNotesWorker do
  let(:project) { create(:project) }
  let(:worker) { described_class.new }

  describe '#import' do
    it 'imports the issues and diff notes' do
      client = double(:client)

      described_class::IMPORTERS.each do |klass|
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
        .with(project.id, { '123' => 2 }, :notes)

      worker.import(client, project)
    end
  end
end
