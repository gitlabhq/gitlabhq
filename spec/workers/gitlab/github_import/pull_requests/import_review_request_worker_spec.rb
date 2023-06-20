# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::PullRequests::ImportReviewRequestWorker, feature_category: :importers do
  subject(:worker) { described_class.new }

  describe '#import' do
    let(:import_state) { build_stubbed(:import_state, :started) }

    let(:project) do
      instance_double('Project', full_path: 'foo/bar', id: 1, import_state: import_state)
    end

    let(:client) { instance_double('Gitlab::GithubImport::Client') }
    let(:importer) { instance_double('Gitlab::GithubImport::Importer::IssueEventImporter') }

    let(:review_request_hash) do
      {
        'merge_request_id' => 6501124486,
        'users' => [
          { 'id' => 4, 'login' => 'alice' },
          { 'id' => 5, 'login' => 'bob' }
        ]
      }
    end

    it 'imports an pull request review requests' do
      allow(import_state).to receive(:in_progress?).and_return(true)

      expect(Gitlab::GithubImport::Importer::PullRequests::ReviewRequestImporter)
        .to receive(:new)
        .with(
          an_instance_of(Gitlab::GithubImport::Representation::PullRequests::ReviewRequests),
          project,
          client
        )
        .and_return(importer)

      expect(importer).to receive(:execute)

      expect(Gitlab::GithubImport::ObjectCounter)
        .to receive(:increment).with(project, :pull_request_review_request, :imported)

      worker.import(project, client, review_request_hash)
    end
  end
end
