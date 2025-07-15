# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::Importers::PullRequestsImporter, :clean_gitlab_redis_shared_state, feature_category: :importers do
  subject(:importer) { described_class.new(project) }

  describe '#execute' do
    let_it_be(:project) do
      create(:project, :import_started,
        import_data_attributes: {
          data: {
            'project_key' => 'key',
            'repo_slug' => 'slug'
          },
          credentials: { 'base_uri' => 'http://bitbucket.org/', 'user' => 'bitbucket', 'password' => 'password' }
        }
      )
    end

    before do
      allow_next_instance_of(Bitbucket::Client) do |client|
        page = instance_double('Bitbucket::Page', attrs: [], items: [
          Bitbucket::Representation::PullRequest.new({ 'id' => 1, 'state' => 'OPENED' }),
          Bitbucket::Representation::PullRequest.new({ 'id' => 2, 'state' => 'DECLINED' }),
          Bitbucket::Representation::PullRequest.new({ 'id' => 3, 'state' => 'MERGED' })
        ])

        allow(client).to receive(:each_page).and_yield(page)
        allow(page).to receive(:next?).and_return(true)
        allow(page).to receive(:next).and_return('https://example.com/next')
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

    context 'when the client raises an error' do
      before do
        allow_next_instance_of(Bitbucket::Client) do |client|
          allow(client).to receive(:pull_requests).and_raise(StandardError.new('error fetching PRs'))
        end
      end

      it 'raises the error' do
        expect { importer.execute }.to raise_error(StandardError, 'error fetching PRs')
      end
    end
  end
end
