# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RemoveFreeUserCapEmailWorkers, :migration, feature_category: :onboarding do
  describe '#up' do
    it 'calls sidekiq_remove_jobs with correct argument' do
      deprecated_job_classes = %w[
        Namespaces::FreeUserCap::BackfillNotificationClearingJobsWorker
        Namespaces::FreeUserCap::BackfillNotificationJobsWorker
        Namespaces::FreeUserCap::NotificationClearingWorker
        Namespaces::FreeUserCap::OverLimitNotificationWorker
      ]

      expect_next_instance_of(described_class) do |migration|
        expect(migration).to receive(:sidekiq_remove_jobs)
                               .with({ job_klasses: deprecated_job_classes })
      end

      migrate!
    end
  end
end
