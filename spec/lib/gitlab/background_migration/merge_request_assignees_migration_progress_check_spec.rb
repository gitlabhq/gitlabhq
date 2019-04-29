# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::MergeRequestAssigneesMigrationProgressCheck do
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

      expect(Feature).to receive(:enable).with(:multiple_merge_request_assignees)

      described_class.new.perform
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
