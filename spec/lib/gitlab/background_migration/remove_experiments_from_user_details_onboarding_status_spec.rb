# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RemoveExperimentsFromUserDetailsOnboardingStatus, feature_category: :onboarding do
  let(:users) { table(:users) }
  let(:user_details) { table(:user_details) }
  let(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }

  let!(:user_with_experiments) do
    user = users.create!(
      username: 'user1',
      email: 'user1@example.com',
      projects_limit: 10,
      organization_id: organization.id
    )
    user_details.create!(
      user_id: user.id,
      onboarding_status: { step_url: '/welcome', experiments: ['foo'], role: 1 }
    )
  end

  let!(:user_without_experiments) do
    user = users.create!(
      username: 'user2',
      email: 'user2@example.com',
      projects_limit: 10,
      organization_id: organization.id
    )
    user_details.create!(
      user_id: user.id,
      onboarding_status: { step_url: '/welcome', role: 2 }
    )
  end

  let!(:user_with_empty_onboarding_status) do
    user = users.create!(
      username: 'user3',
      email: 'user3@example.com',
      projects_limit: 10,
      organization_id: organization.id
    )
    user_details.create!(user_id: user.id, onboarding_status: {})
  end

  describe '#up' do
    subject(:migrate) do
      described_class.new(
        batch_table: :user_details,
        batch_column: :user_id,
        sub_batch_size: 1,
        pause_ms: 2.minutes,
        connection: ApplicationRecord.connection
      ).perform
    end

    it 'removes experiments key from onboarding_status' do
      migrate

      user_detail = user_details.find_by(user_id: user_with_experiments.id)
      status = user_detail.onboarding_status

      expect(status).not_to have_key('experiments')
      expect(status['step_url']).to eq('/welcome')
      expect(status['role']).to eq(1)
    end

    it 'does not modify records without experiments key' do
      expect { migrate }.not_to change {
        user_details.find_by(user_id: user_without_experiments.id).onboarding_status
      }
    end

    it 'does not modify records with empty onboarding_status' do
      expect { migrate }.not_to change {
        user_details.find_by(user_id: user_with_empty_onboarding_status.id).onboarding_status
      }
    end
  end
end
