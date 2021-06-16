# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'sidekiq.rake', :aggregate_failures, :silence_stdout do
  before do
    Rake.application.rake_require 'tasks/gitlab/sidekiq'

    stub_warn_user_is_not_gitlab
  end

  shared_examples 'migration rake task' do
    it 'runs the migrator with a mapping of workers to queues' do
      test_routes = [
        ['urgency=high', 'default'],
        ['*', nil]
      ]

      test_router = ::Gitlab::SidekiqConfig::WorkerRouter.new(test_routes)
      migrator = ::Gitlab::SidekiqMigrateJobs.new(sidekiq_set, logger: Logger.new($stdout))

      allow(::Gitlab::SidekiqConfig::WorkerRouter)
        .to receive(:global).and_return(test_router)

      expect(::Gitlab::SidekiqMigrateJobs)
        .to receive(:new).with(sidekiq_set, logger: an_instance_of(Logger)).and_return(migrator)

      expect(migrator)
        .to receive(:execute)
              .with(a_hash_including('PostReceive' => 'default',
                                     'MergeWorker' => 'default',
                                     'DeleteDiffFilesWorker' => 'delete_diff_files'))
              .and_call_original

      run_rake_task("gitlab:sidekiq:migrate_jobs:#{sidekiq_set}")

      expect($stdout.string).to include("Processing #{sidekiq_set}")
      expect($stdout.string).to include('Done')
    end
  end

  describe 'gitlab:sidekiq:migrate_jobs:schedule rake task' do
    let(:sidekiq_set) { 'schedule' }

    it_behaves_like 'migration rake task'
  end

  describe 'gitlab:sidekiq:migrate_jobs:retry rake task' do
    let(:sidekiq_set) { 'retry' }

    it_behaves_like 'migration rake task'
  end
end
