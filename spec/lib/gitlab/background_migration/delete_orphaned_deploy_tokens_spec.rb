# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DeleteOrphanedDeployTokens, feature_category: :continuous_delivery do
  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }
  let!(:group) { table(:namespaces).create!(name: 'group', path: 'group', organization_id: organization.id) }

  let!(:project) do
    table(:projects).create!(name: 'project', path: 'project', namespace_id: group.id,
      project_namespace_id: group.id, organization_id: organization.id)
  end

  let!(:valid_project_deploy_token) do
    token = table(:deploy_tokens).create!(name: 'token1', expires_at: 1.week.from_now)
    table(:project_deploy_tokens).create!(project_id: project.id, deploy_token_id: token.id)

    token
  end

  let!(:valid_group_deploy_token) do
    token = table(:deploy_tokens).create!(name: 'token2', expires_at: 1.week.from_now)
    table(:group_deploy_tokens).create!(group_id: group.id, deploy_token_id: token.id)

    token
  end

  let!(:invalid_deploy_token1) { table(:deploy_tokens).create!(name: 'token3', expires_at: 1.week.from_now) }
  let!(:invalid_deploy_token2) { table(:deploy_tokens).create!(name: 'token4', expires_at: 1.week.from_now) }

  let!(:starting_id) { table(:deploy_tokens).pluck(:id).min }
  let!(:end_id) { table(:deploy_tokens).pluck(:id).max }

  let!(:migration) do
    described_class.new(
      start_id: starting_id,
      end_id: end_id,
      batch_table: :deploy_tokens,
      batch_column: :id,
      sub_batch_size: 3,
      pause_ms: 2,
      connection: ::ApplicationRecord.connection
    )
  end

  it 'removes deploy tokens with no project or group join table record' do
    expect(table(:deploy_tokens).count).to eq(4)

    migration.perform

    expect(table(:deploy_tokens).count).to eq(2)

    expect(valid_project_deploy_token.reload).to eq(valid_project_deploy_token)
    expect(valid_group_deploy_token.reload).to eq(valid_group_deploy_token)
    expect(table(:deploy_tokens).where(id: [invalid_deploy_token1.id, invalid_deploy_token2.id])).to be_empty
  end
end
