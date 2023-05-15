# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportPullRequestsMergedByWorker, feature_category: :importers do
  let(:project) { create(:project) }
  let(:import_state) { create(:import_state, project: project) }
  let(:worker) { described_class.new }

  describe '#import' do
    it 'imports all the pull requests' do
      importer = double(:importer)
      client = double(:client)
      waiter = Gitlab::JobWaiter.new(2, '123')

      expect(Gitlab::GithubImport::Importer::PullRequests::AllMergedByImporter)
        .to receive(:new)
        .with(project, client)
        .and_return(importer)

      expect(importer)
        .to receive(:execute)
        .and_return(waiter)

      expect(import_state)
        .to receive(:refresh_jid_expiration)

      expect(Gitlab::GithubImport::AdvanceStageWorker)
        .to receive(:perform_async)
        .with(project.id, { '123' => 2 }, :pull_request_review_requests)

      worker.import(client, project)
    end
  end
end
