require 'spec_helper'
require Rails.root.join('db', 'migrate', '20180521162137_migrate_remaining_mr_metrics_populating_background_migration.rb')

describe MigrateRemainingMrMetricsPopulatingBackgroundMigration, :migration, :sidekiq, :redis do
  let(:mr_with_event) { create(:merge_request) }
  let!(:merged_event) { create(:event, :merged, target: mr_with_event) }
  let!(:closed_event) { create(:event, :closed, target: mr_with_event) }

  before do
    # Make sure no metrics are created and kept through after_* callbacks.
    mr_with_event.metrics.destroy!
  end

  # This is mainly an integration test. PopulateMergeRequestMetricsWithEventsData worker
  # already has exclusive unit tests.
  it 'migrates remaining MRs without metrics' do
    migrate!

    mr_with_event.reload

    expect(mr_with_event.metrics).to have_attributes(latest_closed_by_id: closed_event.author_id,
                                                     merged_by_id: merged_event.author_id)
    expect(mr_with_event.metrics.latest_closed_at.to_s).to eq(closed_event.updated_at.to_s)
  end
end
