require 'spec_helper'

describe Gitlab::GithubImport::Stage::ImportPullRequestsWorker do
  let(:project) { create(:project) }
  let(:worker) { described_class.new }

  describe '#import' do
    it 'imports all the pull requests' do
      importer = double(:importer)
      client = double(:client)
      waiter = Gitlab::JobWaiter.new(2, '123')

      expect(Gitlab::GithubImport::Importer::PullRequestsImporter)
        .to receive(:new)
        .with(project, client)
        .and_return(importer)

      expect(importer)
        .to receive(:execute)
        .and_return(waiter)

      expect(project)
        .to receive(:refresh_import_jid_expiration)

      expect(Gitlab::GithubImport::AdvanceStageWorker)
        .to receive(:perform_async)
        .with(project.id, { '123' => 2 }, :issues_and_diff_notes)

      worker.import(client, project)
    end
  end
end
