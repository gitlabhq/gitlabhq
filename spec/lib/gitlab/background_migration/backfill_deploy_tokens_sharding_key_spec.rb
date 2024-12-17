# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillDeployTokensShardingKey, feature_category: :continuous_delivery do
  let!(:organization) { table(:organizations).create!(name: 'organization', path: 'organization') }

  let!(:group1) { table(:namespaces).create!(name: 'group1', path: 'group1', organization_id: organization.id) }
  let!(:group2) { table(:namespaces).create!(name: 'group2', path: 'group2', organization_id: organization.id) }

  let!(:project1) do
    table(:projects).create!(name: 'project1', path: 'project1', namespace_id: group1.id,
      project_namespace_id: group1.id, organization_id: organization.id)
  end

  let!(:project2) do
    table(:projects).create!(name: 'project2', path: 'project2', namespace_id: group2.id,
      project_namespace_id: group2.id, organization_id: organization.id)
  end

  let!(:deploy_token1) do
    token = table(:deploy_tokens).create!(name: 'token1', expires_at: 1.week.from_now)
    table(:project_deploy_tokens).create!(project_id: project1.id, deploy_token_id: token.id)

    token
  end

  let!(:deploy_token2) do
    token = table(:deploy_tokens).create!(name: 'token2', expires_at: 1.week.from_now)
    table(:project_deploy_tokens).create!(project_id: project2.id, deploy_token_id: token.id)

    token
  end

  let!(:deploy_token3) do
    token = table(:deploy_tokens).create!(name: 'token3', expires_at: 1.week.from_now)
    table(:group_deploy_tokens).create!(group_id: group1.id, deploy_token_id: token.id)

    token
  end

  let!(:deploy_token4) do
    token = table(:deploy_tokens).create!(name: 'token4', expires_at: 1.week.from_now)
    table(:group_deploy_tokens).create!(group_id: group2.id, deploy_token_id: token.id)

    token
  end

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

  it 'backfills the missing project_id or namespace_id' do
    expect(table(:deploy_tokens).where(project_id: nil, group_id: nil).count).to eq(4)

    migration.perform

    expect(table(:deploy_tokens).where(project_id: nil, group_id: nil).count).to eq(0)
    expect(table(:deploy_tokens).where.not(project_id: nil).where.not(group_id: nil).count).to eq(0)

    expect(deploy_token1.reload.project_id).to eq(project1.id)
    expect(deploy_token2.reload.project_id).to eq(project2.id)
    expect(deploy_token3.reload.group_id).to eq(group1.id)
    expect(deploy_token4.reload.group_id).to eq(group2.id)
  end
end
