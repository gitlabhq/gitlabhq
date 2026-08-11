# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::UpdateStepUrlToWelcomePath, feature_category: :onboarding do
  let(:users) { table(:users) }
  let(:user_details) { table(:user_details) }
  let(:organizations) { table(:organizations) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }

  let!(:user_with_company_url) do
    user = users.create!(projects_limit: 0, email: 'user1@example.com', organization_id: organization.id)
    user_details.create!(
      user_id: user.id,
      onboarding_status: { role: 0, step_url: described_class::COMPANY_STEP_URL }
    )
  end

  let!(:user_with_groups_new_url) do
    user = users.create!(projects_limit: 0, email: 'user2@example.com', organization_id: organization.id)
    user_details.create!(
      user_id: user.id,
      onboarding_status: { role: 1, step_url: described_class::GROUPS_NEW_STEP_URL }
    )
  end

  let!(:user_with_welcome_url) do
    user = users.create!(projects_limit: 0, email: 'user3@example.com', organization_id: organization.id)
    user_details.create!(
      user_id: user.id,
      onboarding_status: { role: 0, step_url: described_class::NEW_STEP_URL }
    )
  end

  let!(:user_with_other_url) do
    user = users.create!(projects_limit: 0, email: 'user4@example.com', organization_id: organization.id)
    user_details.create!(
      user_id: user.id,
      onboarding_status: { role: 0, step_url: '/some/other/path' }
    )
  end

  subject(:migration) do
    described_class.new(
      start_id: user_details.minimum(:user_id),
      end_id: user_details.maximum(:user_id),
      batch_table: :user_details,
      batch_column: :user_id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    it 'updates step_url from old paths to welcome path', :aggregate_failures do
      migration.perform

      expect(user_with_company_url.reload.onboarding_status).to eq(
        'role' => 0, 'step_url' => described_class::NEW_STEP_URL
      )
      expect(user_with_groups_new_url.reload.onboarding_status).to eq(
        'role' => 1, 'step_url' => described_class::NEW_STEP_URL
      )
    end

    it 'does not update records that already have the welcome step_url' do
      expect { migration.perform }.not_to change { user_with_welcome_url.reload.onboarding_status }
    end

    it 'does not update records with different step_url values' do
      expect { migration.perform }.not_to change { user_with_other_url.reload.onboarding_status }
    end
  end
end
