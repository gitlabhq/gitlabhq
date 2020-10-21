# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MergeRequestAssigneesMigrationProgressCheck do
  context 'rescheduling' do
    context 'when there are ongoing and no dead jobs' do
      it 'reschedules check' do
        allow(Gitlab::BackgroundMigration).to receive(:exists?)
                                                .with('PopulateMergeRequestAssigneesTable')
                                                .and_return(true)

        allow(Gitlab::BackgroundMigration).to receive(:dead_jobs?)
                                                .with('PopulateMergeRequestAssigneesTable')
                                                .and_return(false)

        expect(BackgroundMigrationWorker).to receive(:perform_in).with(described_class::RESCHEDULE_DELAY, described_class.name)

        described_class.new.perform
      end
    end

    context 'when there are ongoing and dead jobs' do
      it 'reschedules check' do
        allow(Gitlab::BackgroundMigration).to receive(:exists?)
                                                .with('PopulateMergeRequestAssigneesTable')
                                                .and_return(true)

        allow(Gitlab::BackgroundMigration).to receive(:dead_jobs?)
                                                .with('PopulateMergeRequestAssigneesTable')
                                                .and_return(true)

        expect(BackgroundMigrationWorker).to receive(:perform_in).with(described_class::RESCHEDULE_DELAY, described_class.name)

        described_class.new.perform
      end
    end

    context 'when there retrying jobs and no scheduled' do
      it 'reschedules check' do
        allow(Gitlab::BackgroundMigration).to receive(:exists?)
                                                .with('PopulateMergeRequestAssigneesTable')
                                                .and_return(false)

        allow(Gitlab::BackgroundMigration).to receive(:retrying_jobs?)
                                                .with('PopulateMergeRequestAssigneesTable')
                                                .and_return(true)

        expect(BackgroundMigrationWorker).to receive(:perform_in).with(described_class::RESCHEDULE_DELAY, described_class.name)

        described_class.new.perform
      end
    end
  end

  context 'when there are no scheduled, or retrying or dead' do
    before do
      stub_feature_flags(multiple_merge_request_assignees: false)
    end

    it 'enables feature' do
      allow(Gitlab::BackgroundMigration).to receive(:exists?)
                                              .with('PopulateMergeRequestAssigneesTable')
                                              .and_return(false)

      allow(Gitlab::BackgroundMigration).to receive(:retrying_jobs?)
                                              .with('PopulateMergeRequestAssigneesTable')
                                              .and_return(false)

      allow(Gitlab::BackgroundMigration).to receive(:dead_jobs?)
                                              .with('PopulateMergeRequestAssigneesTable')
                                              .and_return(false)

      described_class.new.perform

      expect(Feature.enabled?(:multiple_merge_request_assignees, type: :licensed)).to eq(true)
    end
  end

  context 'when there are only dead jobs' do
    it 'raises DeadJobsError error' do
      allow(Gitlab::BackgroundMigration).to receive(:exists?)
                                              .with('PopulateMergeRequestAssigneesTable')
                                              .and_return(false)

      allow(Gitlab::BackgroundMigration).to receive(:retrying_jobs?)
                                              .with('PopulateMergeRequestAssigneesTable')
                                              .and_return(false)

      allow(Gitlab::BackgroundMigration).to receive(:dead_jobs?)
                                              .with('PopulateMergeRequestAssigneesTable')
                                              .and_return(true)

      expect { described_class.new.perform }
        .to raise_error(described_class::DeadJobsError,
                        "Only dead background jobs in the queue for #{described_class::WORKER}")
    end
  end
end
