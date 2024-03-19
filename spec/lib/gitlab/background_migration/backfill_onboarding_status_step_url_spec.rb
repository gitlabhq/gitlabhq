# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillOnboardingStatusStepUrl, feature_category: :onboarding do
  let(:users) { table(:users) }
  let(:user_details) { table(:user_details) }

  let(:first_user) { users.create!(email: 'user1@example.com', projects_limit: 0, onboarding_in_progress: true) }

  let!(:user_detail) do
    user_details.create!(
      user_id: first_user.id,
      onboarding_step_url: '_foo_',
      onboarding_status: { step_url: '_bar_', email_opt_in: false }
    )
  end

  let!(:user_detail_to_change) do
    user_details.create!(
      user_id: users.create!(email: 'user2@example.com', projects_limit: 0, onboarding_in_progress: true).id,
      onboarding_step_url: '_foo_',
      onboarding_status: {}
    )
  end

  let(:last_user) { users.create!(email: 'user3@example.com', projects_limit: 0, onboarding_in_progress: false) }

  let!(:user_detail_not_in_onboarding) do
    user_details.create!(
      user_id: last_user.id,
      onboarding_step_url: '_foo_',
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

      expect(user_detail_to_change.reload.onboarding_status).to eq({ 'step_url' => '_foo_' })
      expect(user_detail.reload.onboarding_status).to eq({ 'step_url' => '_bar_', 'email_opt_in' => false })
      expect(user_detail_not_in_onboarding.reload.onboarding_status).to eq({})
    end
  end
end
