# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RedoRemoveCreateLearnGitlabWorkerJobInstances, :migration, feature_category: :onboarding do
  describe '#up' do
    it 'calls sidekiq_remove_jobs with correct argument' do
      expect_next_instance_of(described_class) do |migration|
        expect(migration).to receive(:sidekiq_remove_jobs)
                               .with({ job_klasses: %w[Onboarding::CreateLearnGitlabWorker] })
      end

      migrate!
    end
  end
end
