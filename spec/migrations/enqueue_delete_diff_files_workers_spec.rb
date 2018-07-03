require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180619121030_enqueue_delete_diff_files_workers.rb')

describe EnqueueDeleteDiffFilesWorkers, :migration, :sidekiq do
  let(:merge_request_diffs) { table(:merge_request_diffs) }
  let(:merge_requests) { table(:merge_requests) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 4)

    namespaces.create!(id: 1, name: 'gitlab', path: 'gitlab')
    projects.create!(id: 1, namespace_id: 1, name: 'gitlab', path: 'gitlab')

    merge_requests.create!(id: 1, target_project_id: 1, source_project_id: 1, target_branch: 'feature', source_branch: 'master', state: 'merged')

    merge_request_diffs.create!(id: 1, merge_request_id: 1, state: 'collected')
    merge_request_diffs.create!(id: 2, merge_request_id: 1, state: 'without_files')
    merge_request_diffs.create!(id: 3, merge_request_id: 1, state: 'collected')
    merge_request_diffs.create!(id: 4, merge_request_id: 1, state: 'collected')
    merge_request_diffs.create!(id: 5, merge_request_id: 1, state: 'empty')
    merge_request_diffs.create!(id: 6, merge_request_id: 1, state: 'collected')
    merge_request_diffs.create!(id: 7, merge_request_id: 1, state: 'collected')

    merge_requests.update(1, latest_merge_request_diff_id: 6)
  end

  it 'correctly schedules diff file deletion workers schedulers' do
    Sidekiq::Testing.fake! do
      # First scheduling batch
      expect(BackgroundMigrationWorker).to receive(:perform_async)
        .with(described_class::SCHEDULER, [[[1], [3], [4], [6]], 1])
        .and_call_original

      # Second scheduling batch
      expect(BackgroundMigrationWorker).to receive(:perform_async)
        .with(described_class::SCHEDULER, [[[7]], 2])
        .and_call_original

      migrate!

      expect(BackgroundMigrationWorker.jobs.size).to eq(2)
    end
  end
end
