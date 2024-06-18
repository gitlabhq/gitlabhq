# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FinalizeBackfillEpicBasicFieldsToWorkItemRecord, feature_category: :database do
  describe '#up' do
    let(:migration_arguments) do
      {
        job_class_name: 'BackfillEpicBasicFieldsToWorkItemRecord',
        table_name: 'epics',
        column_name: 'id',
        job_arguments: ['group_id'],
        finalize: true
      }
    end

    it 'ensures the migration is completed for self-managed instances' do
      allow(Gitlab).to receive(:com_except_jh?).and_return(false)
      allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)

      expect_next_instance_of(described_class) do |instance|
        expect(instance).to receive(:ensure_batched_background_migration_is_finished).with(migration_arguments)
      end

      migrate!
    end

    it 'skips the check for GitLab.com, dev, or test' do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)
      allow(Gitlab).to receive(:dev_or_test_env?).and_return(true)

      expect_next_instance_of(described_class) do |instance|
        expect(instance).not_to receive(:ensure_batched_background_migration_is_finished)
      end

      migrate!
    end
  end
end
