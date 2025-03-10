# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillFinishOnboardingForGroupSaml, feature_category: :onboarding do
  let(:users) { table(:users) }
  let(:identities) { table(:identities) }

  let(:first_user_with_saml) do
    users.create!(email: 'user1@example.com', projects_limit: 0, onboarding_in_progress: true)
  end

  let!(:first_user_identity) { identities.create!(user_id: first_user_with_saml.id, provider: 'group_saml') }

  let!(:user_with_saml_not_in_onboarding) do
    record = users.create!(email: 'user2@example.com', projects_limit: 0, onboarding_in_progress: false)
    identities.create!(user_id: record.id, provider: 'group_saml')
    record
  end

  let!(:user_with_identity_not_group_saml) do
    record = users.create!(email: 'user3@example.com', projects_limit: 0, onboarding_in_progress: true)
    identities.create!(user_id: record.id, provider: 'foo')
    record
  end

  let!(:last_user_no_identity) do
    users.create!(email: 'user4@example.com', projects_limit: 0, onboarding_in_progress: true)
  end

  let(:last_user_with_identity) do
    users.create!(email: 'user5@example.com', projects_limit: 0, onboarding_in_progress: true)
  end

  let!(:last_user_not_saml_identity) { identities.create!(user_id: last_user_with_identity.id, provider: 'foo') }
  let!(:last_user_identity) { identities.create!(user_id: last_user_with_identity.id, provider: 'group_saml') }

  subject(:migration) do
    described_class.new(
      start_id: first_user_identity.id,
      end_id: last_user_identity.id,
      batch_table: :identities,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe '#perform' do
    it 'updates the correct data' do
      migration.perform

      expect(first_user_with_saml.reload.onboarding_in_progress).to be(false)
      expect(user_with_saml_not_in_onboarding.reload.onboarding_in_progress).to be(false)
      expect(user_with_identity_not_group_saml.reload.onboarding_in_progress).to be(true)
      expect(last_user_no_identity.reload.onboarding_in_progress).to be(true)
      expect(last_user_with_identity.reload.onboarding_in_progress).to be(false)
    end
  end
end
