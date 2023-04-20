# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::PullRequests::ReviewRequestsImporter, :clean_gitlab_redis_cache,
  feature_category: :importers do
  subject(:importer) { described_class.new(project, client) }

  let_it_be(:project) { create(:project, import_source: 'foo') }

  let(:client) { instance_double(Gitlab::GithubImport::Client) }
  let(:review_request_struct) { Struct.new(:merge_request_id, :users, keyword_init: true) }
  let(:user_struct) { Struct.new(:id, :login, keyword_init: true) }

  shared_context 'when project with merge requests' do
    let_it_be(:merge_request_1) { create(:merge_request, source_project: project, target_branch: 'feature1') }
    let_it_be(:merge_request_2) { create(:merge_request, source_project: project, target_branch: 'feature2') }

    let(:importer_stub) { instance_double('Gitlab::GithubImport::Importer::NoteAttachmentsImporter') }
    let(:importer_attrs) do
      [instance_of(Gitlab::GithubImport::Representation::PullRequests::ReviewRequests), project, client]
    end

    let(:review_requests_1) do
      {
        users: [
          { id: 4, login: 'alice' },
          { id: 5, login: 'bob' }
        ]
      }
    end

    let(:review_requests_2) do
      {
        users: [{ id: 4, login: 'alice' }]
      }
    end

    before do
      allow(client).to receive(:pull_request_review_requests)
        .with(project.import_source, merge_request_1.iid).and_return(review_requests_1)
      allow(client).to receive(:pull_request_review_requests)
        .with(project.import_source, merge_request_2.iid).and_return(review_requests_2)
    end
  end

  describe '#sequential_import' do
    include_context 'when project with merge requests'

    it 'imports each project merge request reviewers' do
      expect_next_instances_of(
        Gitlab::GithubImport::Importer::PullRequests::ReviewRequestImporter, 2, false, *importer_attrs
      ) do |note_attachments_importer|
        expect(note_attachments_importer).to receive(:execute)
      end

      importer.sequential_import
    end

    context 'when merge request is already processed' do
      before do
        Gitlab::Cache::Import::Caching.set_add(
          "github-importer/pull_requests/pull_request_review_requests/already-imported/#{project.id}",
          merge_request_1.iid
        )
      end

      it "doesn't import this merge request reviewers" do
        expect_next_instance_of(
          Gitlab::GithubImport::Importer::PullRequests::ReviewRequestImporter, *importer_attrs
        ) do |note_attachments_importer|
          expect(note_attachments_importer).to receive(:execute)
        end

        importer.sequential_import
      end
    end
  end

  describe '#parallel_import' do
    include_context 'when project with merge requests'

    let(:expected_worker_payload) do
      [
        [
          project.id,
          {
            merge_request_id: merge_request_1.id,
            merge_request_iid: merge_request_1.iid,
            users: [
              { id: 4, login: 'alice' },
              { id: 5, login: 'bob' }
            ]
          },
          instance_of(String)
        ],
        [
          project.id,
          {
            merge_request_id: merge_request_2.id,
            merge_request_iid: merge_request_2.iid,
            users: [
              { id: 4, login: 'alice' }
            ]
          },
          instance_of(String)
        ]
      ]
    end

    it 'schedule import for each merge request reviewers' do
      expect(Gitlab::GithubImport::PullRequests::ImportReviewRequestWorker)
        .to receive(:perform_in).with(1.second, *expected_worker_payload.first)

      expect(Gitlab::GithubImport::PullRequests::ImportReviewRequestWorker)
        .to receive(:perform_in).with(1.second, *expected_worker_payload.second)

      importer.parallel_import
    end

    context 'when merge request is already processed' do
      before do
        Gitlab::Cache::Import::Caching.set_add(
          "github-importer/pull_requests/pull_request_review_requests/already-imported/#{project.id}",
          merge_request_1.iid
        )
      end

      it "doesn't schedule import this merge request reviewers" do
        expect(Gitlab::GithubImport::PullRequests::ImportReviewRequestWorker)
          .to receive(:perform_in).with(1.second, *expected_worker_payload.second)

        importer.parallel_import
      end
    end
  end
end
