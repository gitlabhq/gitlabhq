# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::Importers::PullRequestsImporter, feature_category: :importers do
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
      allow_next_instance_of(Bitbucket::Client) do |client|
        allow(client).to receive(:pull_requests).and_return(
          [
            Bitbucket::Representation::PullRequest.new({ 'id' => 1, 'state' => 'OPENED' }),
            Bitbucket::Representation::PullRequest.new({ 'id' => 2, 'state' => 'DECLINED' }),
            Bitbucket::Representation::PullRequest.new({ 'id' => 3, 'state' => 'MERGED' })
          ],
          []
        )
      end
    end

    it 'imports each pull request in parallel' do
      expect(Gitlab::BitbucketImport::ImportPullRequestWorker).to receive(:perform_in).exactly(3).times

      waiter = importer.execute

      expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
      expect(waiter.jobs_remaining).to eq(3)
      expect(Gitlab::Cache::Import::Caching.values_from_set(importer.already_enqueued_cache_key))
        .to match_array(%w[1 2 3])
    end

    context 'when the client raises an error' do
      before do
        allow_next_instance_of(Bitbucket::Client) do |client|
          allow(client).to receive(:pull_requests).and_raise(StandardError)
        end
      end

      it 'tracks the failure and does not fail' do
        expect(Gitlab::Import::ImportFailureService).to receive(:track).once

        expect(importer.execute).to be_a(Gitlab::JobWaiter)
      end
    end

    context 'when pull request was already enqueued' do
      before do
        Gitlab::Cache::Import::Caching.set_add(importer.already_enqueued_cache_key, 1)
      end

      it 'does not schedule job for enqueued pull requests' do
        expect(Gitlab::BitbucketImport::ImportPullRequestWorker).to receive(:perform_in).twice

        waiter = importer.execute

        expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
        expect(waiter.jobs_remaining).to eq(3)
      end
    end
  end
end
