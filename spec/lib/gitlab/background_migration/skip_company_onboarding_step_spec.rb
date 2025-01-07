# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::SkipCompanyOnboardingStep, feature_category: :onboarding do
  let(:users) { table(:users) }
  let(:user_details) { table(:user_details) }

  let(:first_user) { create_onbooarding_user('user1@example.com') }

  let!(:user_detail_to_change) do
    user_details.create!(
      user_id: first_user.id,
      onboarding_status: { step_url: 'https://gitlab.com/users/sign_up/company/new?glm=blah', email_opt_in: true }
    )
  end

  let!(:user_detail_to_change2) do
    user_details.create!(
      user_id: create_onbooarding_user('user2@example.com').id,
      onboarding_status: { step_url: 'https://sorta.com/users/sign_up/company/new' }
    )
  end

  let(:unchanged_onboarding_status) do
    { step_url: 'https://gitlab.com/users/sign_up/company/new?glm=blah', registration_type: 'trial' }
  end

  let!(:user_detail_with_registration_type) do
    user_details.create!(
      user_id: create_onbooarding_user('user3@example.com').id,
      onboarding_status: unchanged_onboarding_status
    )
  end

  let!(:user_detail_not_on_company_step) do
    user_details.create!(
      user_id: create_onbooarding_user('user4@example.com').id,
      onboarding_status: { step_url: 'https://gitlab.com/something/else' }
    )
  end

  let(:last_user) { users.create!(email: 'user5@example.com', projects_limit: 0, onboarding_in_progress: false) }

  let!(:user_detail_not_in_onboarding) do
    user_details.create!(
      user_id: last_user.id,
      onboarding_status: { step_url: 'https://gitlab.com/users/sign_up/company/new?glm=blah' }
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

      expect(user_detail_to_change.reload.onboarding_status)
        .to eq({ 'step_url' => "#{Gitlab.config.gitlab.url}/users/sign_up/groups/new", 'email_opt_in' => true })
      expect(user_detail_to_change2.reload.onboarding_status)
        .to eq({ 'step_url' => "#{Gitlab.config.gitlab.url}/users/sign_up/groups/new" })

      expect(user_detail_with_registration_type.reload.onboarding_status)
        .to eq(unchanged_onboarding_status.stringify_keys)
      expect(user_detail_not_on_company_step.reload.onboarding_status)
        .to eq({ 'step_url' => 'https://gitlab.com/something/else' })
      expect(user_detail_not_in_onboarding.reload.onboarding_status)
        .to eq({ 'step_url' => 'https://gitlab.com/users/sign_up/company/new?glm=blah' })
    end
  end

  def create_onbooarding_user(email)
    users.create!(
      email: email,
      projects_limit: 0,
      onboarding_in_progress: true
    )
  end
end
