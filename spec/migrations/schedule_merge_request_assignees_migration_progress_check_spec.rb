# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20190402224749_schedule_merge_request_assignees_migration_progress_check.rb')

RSpec.describe ScheduleMergeRequestAssigneesMigrationProgressCheck do
  describe '#up' do
    it 'schedules MergeRequestAssigneesMigrationProgressCheck background job' do
      expect(BackgroundMigrationWorker).to receive(:perform_async)
                                             .with(described_class::MIGRATION)
                                             .and_call_original

      subject.up
    end
  end
end
