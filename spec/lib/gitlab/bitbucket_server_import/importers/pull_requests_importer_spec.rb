# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importers::PullRequestsImporter, feature_category: :importers do
  let_it_be(:project) do
    create(:project, :import_started,
      import_data_attributes: {
        data: { 'project_key' => 'key', 'repo_slug' => 'slug' },
        credentials: { 'base_uri' => 'http://bitbucket.org/', 'user' => 'bitbucket', 'password' => 'password' }
      }
    )
  end

  subject(:importer) { described_class.new(project) }

  describe '#execute', :clean_gitlab_redis_cache do
    before do
      allow_next_instance_of(BitbucketServer::Client) do |client|
        allow(client).to receive(:pull_requests).and_return(
          [
            BitbucketServer::Representation::PullRequest.new({ 'id' => 1 }),
            BitbucketServer::Representation::PullRequest.new({ 'id' => 2 })
          ],
          []
        )
      end
    end

    it 'imports each pull request in parallel', :aggregate_failures do
      expect(Gitlab::BitbucketServerImport::ImportPullRequestWorker).to receive(:perform_in).twice

      waiter = importer.execute

      expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
      expect(waiter.jobs_remaining).to eq(2)
      expect(Gitlab::Cache::Import::Caching.values_from_set(importer.already_processed_cache_key))
        .to match_array(%w[1 2])
    end

    context 'when pull request was already processed' do
      before do
        Gitlab::Cache::Import::Caching.set_add(importer.already_processed_cache_key, 1)
      end

      it 'does not schedule job for processed pull requests', :aggregate_failures do
        expect(Gitlab::BitbucketServerImport::ImportPullRequestWorker).to receive(:perform_in).once

        waiter = importer.execute

        expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
        expect(waiter.jobs_remaining).to eq(2)
      end
    end
  end
end
