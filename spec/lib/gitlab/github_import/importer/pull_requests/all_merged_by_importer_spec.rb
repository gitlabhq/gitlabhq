# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::PullRequests::AllMergedByImporter, feature_category: :importers do
  let(:client) { double }

  let_it_be(:project) { create(:project, import_source: 'http://somegithub.com') }

  subject { described_class.new(project, client) }

  it { is_expected.to include_module(Gitlab::GithubImport::ParallelScheduling) }

  describe '#representation_class' do
    it { expect(subject.representation_class).to eq(Gitlab::GithubImport::Representation::PullRequest) }
  end

  describe '#importer_class' do
    it { expect(subject.importer_class).to eq(Gitlab::GithubImport::Importer::PullRequests::MergedByImporter) }
  end

  describe '#sidekiq_worker_class' do
    it { expect(subject.sidekiq_worker_class).to eq(Gitlab::GithubImport::PullRequests::ImportMergedByWorker) }
  end

  describe '#collection_method' do
    it { expect(subject.collection_method).to eq(:pull_requests_merged_by) }
  end

  describe '#id_for_already_imported_cache' do
    it { expect(subject.id_for_already_imported_cache(instance_double(MergeRequest, id: 1))).to eq(1) }
  end

  describe '#each_object_to_import', :clean_gitlab_redis_cache do
    let!(:merge_request) do
      create(:merged_merge_request, iid: 999, source_project: project, target_project: project)
    end

    it 'fetches the merged pull requests data' do
      pull_request = double

      allow(client)
        .to receive(:pull_request)
        .exactly(:once) # ensure to be cached on the second call
        .with('http://somegithub.com', 999)
        .and_return(pull_request)

      expect { |b| subject.each_object_to_import(&b) }
        .to yield_with_args(pull_request)

      subject.each_object_to_import
    end

    it 'skips cached merge requests' do
      Gitlab::Cache::Import::Caching.set_add(
        "github-importer/already-imported/#{project.id}/pull_requests_merged_by",
        merge_request.id
      )

      expect(client).not_to receive(:pull_request)

      subject.each_object_to_import
    end
  end
end
