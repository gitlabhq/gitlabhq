# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Stage::ImportPullRequestsReviewRequestsWorker, feature_category: :importers do
  subject(:worker) { described_class.new }

  let(:project) { instance_double(Project, id: 1, import_state: import_state) }
  let(:import_state) { instance_double(ProjectImportState) }
  let(:client) { instance_double(Gitlab::GithubImport::Client) }
  let(:importer) { instance_double(Gitlab::GithubImport::Importer::PullRequests::ReviewRequestsImporter) }
  let(:waiter) { Gitlab::JobWaiter.new(2, '123') }

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
