# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeRestoreOptInToGitlabCom, feature_category: :activation do
  describe '#up' do
    let(:migration_arguments) do
      {
        job_class_name: 'RestoreOptInToGitlabCom',
        table_name: :user_details,
        column_name: :user_id,
        job_arguments: ['temp_user_details_issue18240'],
        finalize: true
      }
    end

    it 'skips the check for self-managed instances' do
      expect_next_instance_of(described_class) do |instance|
        expect(instance).not_to receive(:ensure_batched_background_migration_is_finished)
      end

      migrate!
    end

    it 'ensures the migration is completed for SaaS', :saas do
      expect_next_instance_of(described_class) do |instance|
        expect(instance)
          .to receive(:ensure_batched_background_migration_is_finished)
          .with(migration_arguments)
      end

      migrate!
    end
  end
end
