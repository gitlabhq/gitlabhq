require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180619121030_enqueue_delete_diff_files_workers.rb')

describe EnqueueDeleteDiffFilesWorkers, :migration, :sidekiq do
  it 'correctly schedules diff files deletion schedulers' do
    Sidekiq::Testing.fake! do
      expect(BackgroundMigrationWorker)
        .to receive(:perform_async)
        .with(described_class::SCHEDULER)
        .and_call_original

      migrate!

      expect(BackgroundMigrationWorker.jobs.size).to eq(1)
    end
  end
end
