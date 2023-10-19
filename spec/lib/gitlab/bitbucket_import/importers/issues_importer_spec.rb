# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::Importers::IssuesImporter, feature_category: :importers do
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
        allow(client).to receive(:issues).and_return(
          [
            Bitbucket::Representation::Issue.new({ 'id' => 1 }),
            Bitbucket::Representation::Issue.new({ 'id' => 2 })
          ],
          []
        )
      end
    end

    it 'imports each issue in parallel', :aggregate_failures do
      expect(Gitlab::BitbucketImport::ImportIssueWorker).to receive(:perform_in).twice

      waiter = importer.execute

      expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
      expect(waiter.jobs_remaining).to eq(2)
      expect(Gitlab::Cache::Import::Caching.values_from_set(importer.already_enqueued_cache_key))
        .to match_array(%w[1 2])
    end

    context 'when the client raises an error' do
      before do
        allow_next_instance_of(Bitbucket::Client) do |client|
          allow(client).to receive(:issues).and_raise(StandardError)
        end
      end

      it 'tracks the failure and does not fail' do
        expect(Gitlab::Import::ImportFailureService).to receive(:track).once

        importer.execute
      end
    end

    context 'when issue was already enqueued' do
      before do
        Gitlab::Cache::Import::Caching.set_add(importer.already_enqueued_cache_key, 1)
      end

      it 'does not schedule job for enqueued issues', :aggregate_failures do
        expect(Gitlab::BitbucketImport::ImportIssueWorker).to receive(:perform_in).once

        waiter = importer.execute

        expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
        expect(waiter.jobs_remaining).to eq(2)
      end
    end
  end
end
