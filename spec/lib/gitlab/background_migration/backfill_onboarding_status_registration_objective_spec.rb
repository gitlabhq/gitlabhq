# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillOnboardingStatusRegistrationObjective, feature_category: :onboarding do
  let(:users) { table(:users) }
  let(:user_details) { table(:user_details) }
  let(:first_user) { users.create!(projects_limit: 0, email: 'user1@example.com') }
  let!(:user_detail) do
    user_details.create!(
      user_id: first_user.id,
      registration_objective: 0,
      onboarding_status: { 'registration_objective' => 0 }
    )
  end

  let(:second_user) { users.create!(projects_limit: 0, email: 'user2@example.com') }
  let!(:user_detail_to_change) do
    user_details.create!(
      user_id: second_user.id,
      registration_objective: 4,
      onboarding_status: {}
    )
  end

  let(:last_user) { users.create!(projects_limit: 0, email: 'user3@example.com') }
  let!(:user_detail_not_to_be_set) do
    user_details.create!(
      user_id: last_user.id,
      registration_objective: nil,
      onboarding_status: {}
    )
  end

  subject(:migration) do
    described_class.new(
      start_id: user_detail.user_id,
      end_id: user_detail_not_to_be_set.user_id,
      batch_table: :user_details,
      batch_column: :user_id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    it 'updates the correct data' do
      migration.perform

      expect(user_detail.reload.onboarding_status).to eq({ 'registration_objective' => 0 })
      expect(user_detail_to_change.reload.onboarding_status).to eq({ 'registration_objective' => 4 })
      expect(user_detail_not_to_be_set.reload.onboarding_status).to eq({})
    end
  end
end
