# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::PullRequestsReviewsImporter do
  let(:client) { double }
  let(:project) { create(:project, import_source: 'github/repo') }

  subject { described_class.new(project, client) }

  it { is_expected.to include_module(Gitlab::GithubImport::ParallelScheduling) }

  describe '#representation_class' do
    it { expect(subject.representation_class).to eq(Gitlab::GithubImport::Representation::PullRequestReview) }
  end

  describe '#importer_class' do
    it { expect(subject.importer_class).to eq(Gitlab::GithubImport::Importer::PullRequestReviewImporter) }
  end

  describe '#collection_method' do
    it { expect(subject.collection_method).to eq(:pull_request_reviews) }
  end

  describe '#id_for_already_imported_cache' do
    it { expect(subject.id_for_already_imported_cache(double(id: 1))).to eq(1) }
  end

  describe '#each_object_to_import', :clean_gitlab_redis_cache do
    context 'when github_review_importer_query_only_unimported_merge_requests is enabled' do
      before do
        stub_feature_flags(github_review_importer_query_only_unimported_merge_requests: true)
      end

      let(:merge_request) do
        create(
          :merged_merge_request,
          iid: 999,
          source_project: project,
          target_project: project
        )
      end

      let(:review) { double(id: 1) }

      it 'fetches the pull requests reviews data' do
        page = double(objects: [review], number: 1)

        expect(review)
          .to receive(:merge_request_id=)
          .with(merge_request.id)

        expect(client)
          .to receive(:each_page)
          .exactly(:once) # ensure to be cached on the second call
          .with(:pull_request_reviews, 'github/repo', merge_request.iid, page: 1)
          .and_yield(page)

        expect { |b| subject.each_object_to_import(&b) }
          .to yield_with_args(review)

        subject.each_object_to_import {}
      end

      it 'skips cached pages' do
        Gitlab::GithubImport::PageCounter
          .new(project, "merge_request/#{merge_request.id}/pull_request_reviews")
          .set(2)

        expect(review).not_to receive(:merge_request_id=)

        expect(client)
          .to receive(:each_page)
          .exactly(:once) # ensure to be cached on the second call
          .with(:pull_request_reviews, 'github/repo', merge_request.iid, page: 2)

        subject.each_object_to_import {}
      end

      it 'skips cached merge requests' do
        Gitlab::Cache::Import::Caching.set_add(
          "github-importer/merge_request/already-imported/#{project.id}",
          merge_request.id
        )

        expect(review).not_to receive(:merge_request_id=)

        expect(client).not_to receive(:each_page)

        subject.each_object_to_import {}
      end
    end

    context 'when github_review_importer_query_only_unimported_merge_requests is disabled' do
      before do
        stub_feature_flags(github_review_importer_query_only_unimported_merge_requests: false)
      end

      it 'fetchs the merged pull requests data' do
        merge_request = create(
          :merged_merge_request,
          iid: 999,
          source_project: project,
          target_project: project
        )

        review = double

        expect(review)
          .to receive(:merge_request_id=)
          .with(merge_request.id)

        allow(client)
          .to receive(:pull_request_reviews)
          .exactly(:once) # ensure to be cached on the second call
          .with('github/repo', merge_request.iid)
          .and_return([review])

        expect { |b| subject.each_object_to_import(&b) }
          .to yield_with_args(review)

        subject.each_object_to_import {}
      end
    end
  end
end
