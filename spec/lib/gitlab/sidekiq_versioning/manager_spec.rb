require 'spec_helper'

describe Gitlab::SidekiqVersioning::Manager do
  before do
    Sidekiq::Manager.prepend described_class
  end

  describe '#initialize' do
    it 'listens on all expanded supported versionless and versioned queues' do
      allow(Gitlab::SidekiqConfig).to receive(:redis_queues).and_return(%w[repository_fork:v0])

      manager = Sidekiq::Manager.new(queues: %w[post_receive repository_fork cronjob unknown])

      queues = manager.options[:queues]

      expect(queues).to include('post_receive')
      expect(queues).to include("post_receive:v#{PostReceive.version}")

      expect(queues).to include('repository_fork')
      expect(queues).to include("repository_fork:v0")
      expect(queues).to include("repository_fork:v#{RepositoryForkWorker.version}")

      expect(queues).to include('cronjob')
      expect(queues).to include('cronjob:stuck_import_jobs')
      expect(queues).to include("cronjob:stuck_import_jobs:v#{StuckImportJobsWorker.version}")
      expect(queues).to include('cronjob:stuck_merge_jobs')
      expect(queues).to include("cronjob:stuck_merge_jobs:v#{StuckImportJobsWorker.version}")

      expect(queues).to include('unknown')
    end
  end
end
