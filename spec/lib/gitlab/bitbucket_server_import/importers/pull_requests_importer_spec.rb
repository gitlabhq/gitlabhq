# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::Importers::PullRequestsImporter, feature_category: :importers do
  let_it_be(:project) do
    create(:project, :with_import_url, :import_started, :empty_repo,
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
            BitbucketServer::Representation::PullRequest.new(
              {
                'id' => 1,
                'state' => 'MERGED',
                'fromRef' => { 'latestCommit' => 'aaaa1' },
                'toRef' => { 'latestCommit' => 'aaaa2' }
              }
            ),
            BitbucketServer::Representation::PullRequest.new(
              {
                'id' => 2,
                'state' => 'DECLINED',
                'fromRef' => { 'latestCommit' => 'bbbb1' },
                'toRef' => { 'latestCommit' => 'bbbb2' }
              }
            ),
            BitbucketServer::Representation::PullRequest.new(
              {
                'id' => 3,
                'state' => 'OPEN',
                'fromRef' => { 'latestCommit' => 'cccc1' },
                'toRef' => { 'latestCommit' => 'cccc2' }
              }
            )
          ],
          []
        )
      end
    end

    it 'imports each pull request in parallel', :aggregate_failures do
      expect(Gitlab::BitbucketServerImport::ImportPullRequestWorker).to receive(:perform_in).thrice

      waiter = importer.execute

      expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
      expect(waiter.jobs_remaining).to eq(3)
      expect(Gitlab::Cache::Import::Caching.values_from_set(importer.already_processed_cache_key))
        .to match_array(%w[1 2 3])
    end

    context 'when pull request was already processed' do
      before do
        Gitlab::Cache::Import::Caching.set_add(importer.already_processed_cache_key, 1)
      end

      it 'does not schedule job for processed pull requests', :aggregate_failures do
        expect(Gitlab::BitbucketServerImport::ImportPullRequestWorker).to receive(:perform_in).twice

        waiter = importer.execute

        expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
        expect(waiter.jobs_remaining).to eq(3)
      end
    end

    context 'when pull requests are in merged or declined status' do
      it 'fetches latest commits from the remote repository' do
        expect(project.repository).to receive(:fetch_remote).with(
          project.import_url,
          refmap: %w[aaaa1 aaaa2 bbbb1 bbbb2],
          prune: false
        )

        importer.execute
      end

      context 'when feature flag "fetch_commits_for_bitbucket_server" is disabled' do
        before do
          stub_feature_flags(fetch_commits_for_bitbucket_server: false)
        end

        it 'does not fetch anything' do
          expect(project.repository).not_to receive(:fetch_remote)
          importer.execute
        end
      end

      context 'when there are no commits to process' do
        before do
          Gitlab::Cache::Import::Caching.set_add(importer.already_processed_cache_key, 1)
          Gitlab::Cache::Import::Caching.set_add(importer.already_processed_cache_key, 2)
        end

        it 'does not fetch anything' do
          expect(project.repository).not_to receive(:fetch_remote)

          importer.execute
        end
      end

      context 'when fetch process is failed' do
        let(:exception) { ArgumentError.new('blank or empty URL') }

        before do
          allow(project.repository).to receive(:fetch_remote).and_raise(exception)
        end

        it 'rescues and logs the exception' do
          expect(Gitlab::Import::ImportFailureService)
            .to receive(:track)
            .with(
              project_id: project.id,
              exception: exception,
              error_source: described_class.name
            ).and_call_original

          importer.execute
        end
      end
    end
  end
end
