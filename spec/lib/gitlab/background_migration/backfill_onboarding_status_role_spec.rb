# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillOnboardingStatusRole, feature_category: :onboarding do
  let(:users) { table(:users) }
  let(:user_details) { table(:user_details) }

  let(:first_user) { users.create!(projects_limit: 0, email: 'user1@example.com', role: 0) }

  let!(:user_detail) do
    user_details.create!(
      user_id: first_user.id,
      onboarding_status: { role: 0 }
    )
  end

  let!(:user_detail_to_change) do
    user_details.create!(
      user_id: users.create!(projects_limit: 0, email: 'user2@example.com', role: 1).id,
      onboarding_status: {}
    )
  end

  let(:last_user) { users.create!(projects_limit: 0, email: 'user3@example.com') }
  let!(:user_detail_not_to_be_set) do
    user_details.create!(
      user_id: last_user.id,
      onboarding_status: {}
    )
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

      expect(user_detail_to_change.reload.onboarding_status).to eq({ 'role' => 1 })
      expect(user_detail.reload.onboarding_status).to eq({ 'role' => 0 })
      expect(user_detail_not_to_be_set.reload.onboarding_status).to eq({})
    end
  end
end
