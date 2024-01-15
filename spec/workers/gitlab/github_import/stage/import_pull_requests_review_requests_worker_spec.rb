# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportPullRequestsReviewRequestsWorker, feature_category: :importers do
  let_it_be(:project) { create(:project) }

  let(:client) { instance_double(Gitlab::GithubImport::Client) }
  let(:importer) { instance_double(Gitlab::GithubImport::Importer::PullRequests::ReviewRequestsImporter) }
  let(:waiter) { Gitlab::JobWaiter.new(2, '123') }

  subject(:worker) { described_class.new }

  it_behaves_like Gitlab::GithubImport::StageMethods

  describe '#import' do
    it 'imports all PR review requests' do
      expect(Gitlab::GithubImport::Importer::PullRequests::ReviewRequestsImporter)
        .to receive(:new)
        .with(project, client)
        .and_return(importer)

      expect(importer).to receive(:execute).and_return(waiter)

      expect(Gitlab::GithubImport::AdvanceStageWorker)
        .to receive(:perform_async)
        .with(project.id, { '123' => 2 }, 'pull_request_reviews')

      worker.import(client, project)
    end
  end
end
