# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteTwitterIdentities, feature_category: :system_access do
  let(:users_table) { table(:users) }
  let(:identities_table) { table(:identities) }
  let(:organization_table) { table(:organizations) }

  let(:organization) { organization_table.create!(name: 'organization', path: 'organization') }
  let!(:user) do
    users_table.create!(name: 'user-a', email: 'user-a@example.com', projects_limit: 10,
      organization_id: organization.id)
  end

  let!(:twitter_identity) { identities_table.create!(user_id: user.id, provider: 'twitter') }
  let!(:nontwitter_identity) { identities_table.create!(user_id: user.id, provider: 'definitely-not-twitter') }

  let(:migration) do
    start_id, end_id = identities_table.pick('MIN(id), MAX(id)')

    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :identities,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 0,
      job_arguments: [],
      connection: ApplicationRecord.connection
    )
  end

  subject(:migrate) { migration.perform }

  it 'deletes twitter identities' do
    expect { migrate }.to change { identities_table.where(provider: 'twitter').count }.from(1).to(0)
  end

  it 'keeps non-twitter identities' do
    expect { migrate }.not_to change { identities_table.where.not(provider: 'twitter').count }.from(1)
  end
end
