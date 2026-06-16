# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillUserTypeForGhostUserMigrations, feature_category: :user_profile do
  subject(:migration) do
    described_class.new(
      batch_table: :ghost_user_migrations,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 100,
      connection: ApplicationRecord.connection
    )
  end

  let(:organizations) { table(:organizations) }
  let(:users) { table(:users) }
  let(:ghost_user_migrations) { table(:ghost_user_migrations) }

  let!(:organization) { organizations.create!(name: 'organization', path: 'organization') }

  let!(:human_user) do
    users.create!(
      username: 'human_user',
      email: 'human_user@example.com',
      user_type: 0,
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let!(:project_bot) do
    users.create!(
      username: 'project_bot',
      email: 'project_bot@example.com',
      user_type: 6,
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let!(:service_account) do
    users.create!(
      username: 'service_account',
      email: 'service_account@example.com',
      user_type: 13,
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let!(:human_user_ghost_user_migration) do
    ghost_user_migrations.create!(user_id: human_user.id, user_type: nil)
  end

  let!(:project_bot_ghost_user_migration) do
    ghost_user_migrations.create!(user_id: project_bot.id, user_type: nil)
  end

  let!(:service_account_ghost_user_migration) do
    ghost_user_migrations.create!(user_id: service_account.id, user_type: nil)
  end

  it 'backfills user_type for ghost_user_migrations', :aggregate_failures do
    expect(human_user_ghost_user_migration.user_type).to be_nil
    expect(project_bot_ghost_user_migration.user_type).to be_nil
    expect(service_account_ghost_user_migration.user_type).to be_nil

    migration.perform

    expect(human_user_ghost_user_migration.reload.user_type).to eq(0)
    expect(project_bot_ghost_user_migration.reload.user_type).to eq(6)
    expect(service_account_ghost_user_migration.reload.user_type).to eq(13)
  end
end
