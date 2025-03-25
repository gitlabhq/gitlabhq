# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillFinishOnboardingForEnterpriseUser, feature_category: :onboarding do
  let(:users) { table(:users) }
  let(:user_details) { table(:user_details) }

  let(:first_user) do
    record = users.create!(email: 'user1@example.com', projects_limit: 0, onboarding_in_progress: true)
    user_details.create!(user_id: record.id, enterprise_group_id: non_existing_record_id)

    record
  end

  let(:regular_user) do
    record = users.create!(email: 'user2@example.com', projects_limit: 0, onboarding_in_progress: true)
    user_details.create!(user_id: record.id)

    record
  end

  let(:user_not_in_onboarding) do
    record = users.create!(email: 'user3@example.com', projects_limit: 0, onboarding_in_progress: false)
    user_details.create!(user_id: record.id, enterprise_group_id: non_existing_record_id)

    record
  end

  let(:last_user) do
    record = users.create!(email: 'user4@example.com', projects_limit: 0, onboarding_in_progress: true)
    user_details.create!(user_id: record.id, enterprise_group_id: non_existing_record_id)

    record
  end

  subject(:migration) do
    described_class.new(
      start_id: first_user.id,
      end_id: last_user.id,
      batch_table: :users,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    it 'updates the correct data' do
      migration.perform

      expect(first_user.reload.onboarding_in_progress).to be(false)
      expect(regular_user.reload.onboarding_in_progress).to be(true)
      expect(user_not_in_onboarding.reload.onboarding_in_progress).to be(false)
      expect(last_user.reload.onboarding_in_progress).to be(false)
    end
  end
end
