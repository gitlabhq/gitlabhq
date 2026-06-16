# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketImport::Importers::IssuesImporter, :clean_gitlab_redis_shared_state, feature_category: :importers do
  subject(:importer) { described_class.new(project) }

  describe '#execute' do
    let(:client) { Bitbucket::Client.new(project.import_data.credentials) }
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
      allow(Bitbucket::Client).to receive(:new).and_return(client)
      allow(client).to receive(:repo).and_return(Bitbucket::Representation::Repo.new({ 'has_issues' => true }))
      allow(client).to receive(:issues_available?).and_return(true)
      page = instance_double('Bitbucket::Page', attrs: [], items: [
        Bitbucket::Representation::Issue.new({ 'id' => 1 }),
        Bitbucket::Representation::Issue.new({ 'id' => 2 })
      ])
      allow(client).to receive(:each_page).and_yield(page)
      allow(page).to receive(:next?).and_return(true)
      allow(page).to receive(:next).and_return('https://example.com/next')
    end

    context 'when the repo does not have issue tracking enabled' do
      before do
        allow(client).to receive(:repo).and_return(Bitbucket::Representation::Repo.new({ 'has_issues' => false }))
      end

      it 'does not import issues' do
        expect(Gitlab::BitbucketImport::ImportIssueWorker).not_to receive(:perform_in)

        importer.execute
      end
    end

    it 'imports each issue in parallel' do
      expect(Gitlab::BitbucketImport::ImportIssueWorker).to receive(:perform_in).twice

      waiter = importer.execute

      expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
      expect(waiter.jobs_remaining).to eq(2)
      expect(Gitlab::Cache::Import::Caching.values_from_set(importer.already_enqueued_cache_key))
        .to match_array(%w[1 2])
    end

    context 'when issue was already enqueued' do
      before do
        Gitlab::Cache::Import::Caching.set_add(importer.already_enqueued_cache_key, 1)
      end

      it 'does not schedule job for enqueued issues' do
        expect(Gitlab::BitbucketImport::ImportIssueWorker).to receive(:perform_in).once

        waiter = importer.execute

        expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
        expect(waiter.jobs_remaining).to eq(2)
      end
    end

    context 'when the client raises an error' do
      let(:exception) { StandardError.new('error fetching issues') }

      before do
        allow_next_instance_of(Bitbucket::Client) do |client|
          allow(client).to receive(:repo).and_raise(exception)
        end
      end

      it 'raises the error' do
        expect { importer.execute }.to raise_error(StandardError, 'error fetching issues')
      end
    end

    context 'when the Bitbucket Issues API is unavailable' do
      before do
        allow(client).to receive(:issues_available?).and_return(false)
      end

      it 'logs a warning and returns an empty job waiter', :aggregate_failures do
        expect(Gitlab::BitbucketImport::ImportIssueWorker).not_to receive(:perform_in)
        expect(Gitlab::BitbucketImport::Logger).to receive(:warn).with(
          hash_including(
            import_stage: 'import_issues',
            message: 'Bitbucket Issues API is unavailable, skipping issues import'
          )
        )

        waiter = importer.execute

        expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
        expect(waiter.jobs_remaining).to eq(0)
      end
    end
  end
end
