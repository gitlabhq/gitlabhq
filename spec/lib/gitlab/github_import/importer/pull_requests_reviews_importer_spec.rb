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
