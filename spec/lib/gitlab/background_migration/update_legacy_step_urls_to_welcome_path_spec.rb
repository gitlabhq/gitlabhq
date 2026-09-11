# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::UpdateLegacyStepUrlsToWelcomePath, feature_category: :onboarding do
  let(:users) { table(:users) }
  let(:user_details) { table(:user_details) }
  let(:organizations) { table(:organizations) }

  let(:organization) { organizations.create!(name: 'organization', path: 'organization') }

  let!(:user_with_company_url_and_query_string) do
    user = users.create!(projects_limit: 0, email: 'user1@example.com', organization_id: organization.id)
    user_details.create!(
      user_id: user.id,
      onboarding_status: {
        role: 0,
        step_url: "#{described_class::COMPANY_STEP_URL_PREFIX}/new?glm_source=about.gitlab.com&glm_content=free-trial"
      }
    )
  end

  let!(:user_with_bare_company_url) do
    user = users.create!(projects_limit: 0, email: 'user2@example.com', organization_id: organization.id)
    user_details.create!(
      user_id: user.id,
      onboarding_status: { role: 0, step_url: described_class::COMPANY_STEP_URL_PREFIX }
    )
  end

  let!(:user_with_groups_new_url) do
    user = users.create!(projects_limit: 0, email: 'user3@example.com', organization_id: organization.id)
    user_details.create!(
      user_id: user.id,
      onboarding_status: { role: 1, step_url: described_class::GROUPS_NEW_STEP_URL_PREFIX }
    )
  end

  let!(:user_with_groups_new_url_and_query_string) do
    user = users.create!(projects_limit: 0, email: 'user9@example.com', organization_id: organization.id)
    user_details.create!(
      user_id: user.id,
      onboarding_status: {
        role: 1,
        step_url: "#{described_class::GROUPS_NEW_STEP_URL_PREFIX}?glm_source=about.gitlab.com"
      }
    )
  end

  let!(:user_with_welcome_url) do
    user = users.create!(projects_limit: 0, email: 'user4@example.com', organization_id: organization.id)
    user_details.create!(
      user_id: user.id,
      onboarding_status: { role: 0, step_url: described_class::NEW_STEP_URL }
    )
  end

  let!(:user_with_other_url) do
    user = users.create!(projects_limit: 0, email: 'user5@example.com', organization_id: organization.id)
    user_details.create!(
      user_id: user.id,
      onboarding_status: { role: 0, step_url: '/some/other/path' }
    )
  end

  let!(:user_with_non_prefix_match) do
    user = users.create!(projects_limit: 0, email: 'user6@example.com', organization_id: organization.id)
    user_details.create!(
      user_id: user.id,
      onboarding_status: { role: 0, step_url: "/foo#{described_class::COMPANY_STEP_URL_PREFIX}" }
    )
  end

  let!(:user_with_missing_step_url) do
    user = users.create!(projects_limit: 0, email: 'user7@example.com', organization_id: organization.id)
    user_details.create!(
      user_id: user.id,
      onboarding_status: { role: 0 }
    )
  end

  let!(:user_with_empty_onboarding_status) do
    user = users.create!(projects_limit: 0, email: 'user8@example.com', organization_id: organization.id)
    user_details.create!(
      user_id: user.id,
      onboarding_status: {}
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
    it 'updates step_url from legacy paths to welcome path', :aggregate_failures do
      migration.perform

      expect(user_with_company_url_and_query_string.reload.onboarding_status).to eq(
        'role' => 0, 'step_url' => described_class::NEW_STEP_URL
      )
      expect(user_with_bare_company_url.reload.onboarding_status).to eq(
        'role' => 0, 'step_url' => described_class::NEW_STEP_URL
      )
      expect(user_with_groups_new_url.reload.onboarding_status).to eq(
        'role' => 1, 'step_url' => described_class::NEW_STEP_URL
      )
      expect(user_with_groups_new_url_and_query_string.reload.onboarding_status).to eq(
        'role' => 1, 'step_url' => described_class::NEW_STEP_URL
      )
    end

    it 'does not update records that already have the welcome step_url' do
      expect { migration.perform }.not_to change { user_with_welcome_url.reload.onboarding_status }
    end

    it 'does not update records with unrelated step_url values' do
      expect { migration.perform }.not_to change { user_with_other_url.reload.onboarding_status }
    end

    it 'does not update records where the legacy path is not a prefix match' do
      expect { migration.perform }.not_to change { user_with_non_prefix_match.reload.onboarding_status }
    end

    it 'does not update records with no step_url key' do
      expect { migration.perform }.not_to change { user_with_missing_step_url.reload.onboarding_status }
    end

    it 'does not update records with empty onboarding_status' do
      expect { migration.perform }.not_to change { user_with_empty_onboarding_status.reload.onboarding_status }
    end
  end
end
