# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillUserDetailOnboardingUrl, feature_category: :onboarding do
  let(:users) { table(:users) }
  let(:user_details) { table(:user_details) }
  let(:organizations) { table(:organizations) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }
  let(:first_user) do
    users.create!(projects_limit: 0, email: 'user1@example.com', organization_id: organization.id)
  end

  let!(:user_detail) do
    user_details.create!(
      user_id: first_user.id,
      onboarding_status: { role: 0,
                           step_url: described_class::OLD_STEP_URL }
    )
  end

  let(:last_user) { users.create!(projects_limit: 0, email: 'user3@example.com', organization_id: organization.id) }
  let!(:user_details_unchanged) do
    user_details.create!(
      user_id: last_user.id,
      onboarding_status: { role: 0,
                           step_url: described_class::NEW_STEP_URL }
    )
  end

  subject(:migration) do
    described_class.new(
      start_id: first_user.id,
      end_id: last_user.id,
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

      expect(user_detail.reload.onboarding_status).to eq({
        'role' => 0, 'step_url' => described_class::NEW_STEP_URL
      })
    end

    it 'does not update records that already have the new step_url' do
      expect { migration.perform }.not_to change { user_details_unchanged.reload.onboarding_status }
    end

    it 'does not update records with different step_url values' do
      different_user = users.create!(projects_limit: 0, email: 'user4@example.com', organization_id: organization.id)
      different_detail = user_details.create!(
        user_id: different_user.id,
        onboarding_status: { role: 0, step_url: '/some/other/path' }
      )

      migration.perform

      expect(different_detail.reload.onboarding_status['step_url']).to eq('/some/other/path')
    end
  end
end
