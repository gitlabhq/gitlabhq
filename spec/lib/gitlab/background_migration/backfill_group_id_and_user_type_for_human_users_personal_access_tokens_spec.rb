# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers -- We need this many for this background migration
RSpec.describe(
  Gitlab::BackgroundMigration::BackfillGroupIdAndUserTypeForHumanUsersPersonalAccessTokens,
  feature_category: :system_access
) do
  subject(:migration) do
    described_class.new(
      batch_table: :personal_access_tokens,
      batch_column: :id,
      sub_batch_size: 100,
      pause_ms: 100,
      connection: ApplicationRecord.connection
    )
  end

  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:user_details) { table(:user_details) }
  let(:personal_access_tokens) { table(:personal_access_tokens) }

  let!(:organization) { organizations.create!(name: 'organization', path: 'organization') }

  let(:group1) { namespaces.create!(name: 'group1', path: 'group1', type: 'Group1', organization_id: organization.id) }
  let(:group2) { namespaces.create!(name: 'group2', path: 'group2', type: 'Group2', organization_id: organization.id) }

  let!(:human_user) do
    users.create!(
      username: 'human_user',
      email: 'human_user@example.com',
      user_type: 0,
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let!(:human_user_details) do
    user_details.create!(
      user_id: human_user.id
    )
  end

  let!(:human_user_personal_access_token1) do
    personal_access_tokens.create!(
      name: 'human_user_personal_access_token1',
      user_id: human_user.id,
      organization_id: human_user.organization_id
    )
  end

  let!(:human_user_personal_access_token2) do
    personal_access_tokens.create!(
      name: 'human_user_personal_access_token2',
      user_id: human_user.id,
      organization_id: human_user.organization_id
    )
  end

  let!(:human_user_without_user_details) do
    users.create!(
      username: 'human_user_without_user_details',
      email: 'human_user_without_user_details@example.com',
      user_type: 0,
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let!(:human_user_without_user_details_personal_access_token1) do
    personal_access_tokens.create!(
      name: 'human_user_without_user_details_personal_access_token1',
      user_id: human_user_without_user_details.id,
      organization_id: human_user_without_user_details.organization_id
    )
  end

  let!(:human_user_without_user_details_personal_access_token2) do
    personal_access_tokens.create!(
      name: 'human_user_without_user_details_personal_access_token2',
      user_id: human_user_without_user_details.id,
      organization_id: human_user_without_user_details.organization_id
    )
  end

  let!(:enterprise_user1) do
    users.create!(
      username: 'enterprise_user1',
      email: 'enterprise_user1@example.com',
      user_type: 0,
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let!(:enterprise_user1_details) do
    user_details.create!(
      user_id: enterprise_user1.id,
      enterprise_group_id: group1.id
    )
  end

  let!(:enterprise_user1_personal_access_token1) do
    personal_access_tokens.create!(
      name: 'enterprise_user1_personal_access_token1',
      user_id: enterprise_user1.id,
      organization_id: enterprise_user1.organization_id
    )
  end

  let!(:enterprise_user1_personal_access_token2) do
    personal_access_tokens.create!(
      name: 'enterprise_user1_personal_access_token2',
      user_id: enterprise_user1.id,
      organization_id: enterprise_user1.organization_id
    )
  end

  let!(:enterprise_user2) do
    users.create!(
      username: 'enterprise_user2',
      email: 'enterprise_user2@example.com',
      user_type: 0,
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let!(:enterprise_user2_details) do
    user_details.create!(
      user_id: enterprise_user2.id,
      enterprise_group_id: group2.id
    )
  end

  let!(:enterprise_user2_personal_access_token1) do
    personal_access_tokens.create!(
      name: 'enterprise_user2_personal_access_token1',
      user_id: enterprise_user2.id,
      organization_id: enterprise_user2.organization_id
    )
  end

  let!(:enterprise_user2_personal_access_token2) do
    personal_access_tokens.create!(
      name: 'enterprise_user2_personal_access_token2',
      user_id: enterprise_user2.id,
      organization_id: enterprise_user2.organization_id
    )
  end

  let!(:project_bot_user) do
    users.create!(
      username: 'project_bot_user',
      email: 'project_bot_user@example.com',
      user_type: 6,
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let!(:project_bot_user_details) do
    user_details.create!(
      user_id: project_bot_user.id
    )
  end

  let!(:project_bot_user_personal_access_token1) do
    personal_access_tokens.create!(
      name: 'project_bot_user_personal_access_token1',
      user_id: project_bot_user.id,
      organization_id: project_bot_user.organization_id
    )
  end

  let!(:project_bot_user_personal_access_token2) do
    personal_access_tokens.create!(
      name: 'project_bot_user_personal_access_token2',
      user_id: project_bot_user.id,
      organization_id: project_bot_user.organization_id
    )
  end

  let!(:service_account_user) do
    users.create!(
      username: 'service_account_user',
      email: 'service_account_user@example.com',
      user_type: 13,
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let!(:service_account_user_details) do
    user_details.create!(
      user_id: service_account_user.id
    )
  end

  let!(:service_account_user_personal_access_token1) do
    personal_access_tokens.create!(
      name: 'service_account_user_personal_access_token1',
      user_id: service_account_user.id,
      organization_id: service_account_user.organization_id
    )
  end

  let!(:service_account_user_personal_access_token2) do
    personal_access_tokens.create!(
      name: 'service_account_user_personal_access_token2',
      user_id: service_account_user.id,
      organization_id: service_account_user.organization_id
    )
  end

  it "backfills group_id and user_type for human users' personal_access_tokens", :aggregate_failures do
    expect(human_user_personal_access_token1.group_id).to be_nil
    expect(human_user_personal_access_token1.user_type).to be_nil

    expect(human_user_personal_access_token2.group_id).to be_nil
    expect(human_user_personal_access_token2.user_type).to be_nil

    expect(human_user_without_user_details_personal_access_token1.group_id).to be_nil
    expect(human_user_without_user_details_personal_access_token1.user_type).to be_nil

    expect(human_user_without_user_details_personal_access_token2.group_id).to be_nil
    expect(human_user_without_user_details_personal_access_token2.user_type).to be_nil

    expect(enterprise_user1_personal_access_token1.group_id).to be_nil
    expect(enterprise_user1_personal_access_token1.user_type).to be_nil

    expect(enterprise_user1_personal_access_token2.group_id).to be_nil
    expect(enterprise_user1_personal_access_token2.user_type).to be_nil

    expect(enterprise_user2_personal_access_token1.group_id).to be_nil
    expect(enterprise_user2_personal_access_token1.user_type).to be_nil

    expect(enterprise_user2_personal_access_token2.group_id).to be_nil
    expect(enterprise_user2_personal_access_token2.user_type).to be_nil

    expect(project_bot_user_personal_access_token1.group_id).to be_nil
    expect(project_bot_user_personal_access_token1.user_type).to be_nil

    expect(project_bot_user_personal_access_token2.group_id).to be_nil
    expect(project_bot_user_personal_access_token2.user_type).to be_nil

    expect(service_account_user_personal_access_token1.group_id).to be_nil
    expect(service_account_user_personal_access_token1.user_type).to be_nil

    expect(service_account_user_personal_access_token2.group_id).to be_nil
    expect(service_account_user_personal_access_token2.user_type).to be_nil

    migration.perform

    expect(human_user_personal_access_token1.reload.group_id).to be_nil
    expect(human_user_personal_access_token1.reload.user_type).to eq(0)

    expect(human_user_personal_access_token2.reload.group_id).to be_nil
    expect(human_user_personal_access_token2.reload.user_type).to eq(0)

    expect(human_user_without_user_details_personal_access_token1.reload.group_id).to be_nil
    expect(human_user_without_user_details_personal_access_token1.reload.user_type).to eq(0)

    expect(human_user_without_user_details_personal_access_token2.reload.group_id).to be_nil
    expect(human_user_without_user_details_personal_access_token2.reload.user_type).to eq(0)

    expect(enterprise_user1_personal_access_token1.reload.group_id).to eq(group1.id)
    expect(enterprise_user1_personal_access_token1.reload.user_type).to eq(0)

    expect(enterprise_user1_personal_access_token2.reload.group_id).to eq(group1.id)
    expect(enterprise_user1_personal_access_token2.reload.user_type).to eq(0)

    expect(enterprise_user2_personal_access_token1.reload.group_id).to eq(group2.id)
    expect(enterprise_user2_personal_access_token1.reload.user_type).to eq(0)

    expect(enterprise_user2_personal_access_token2.reload.group_id).to eq(group2.id)
    expect(enterprise_user2_personal_access_token2.reload.user_type).to eq(0)

    expect(project_bot_user_personal_access_token1.reload.group_id).to be_nil
    expect(project_bot_user_personal_access_token1.reload.user_type).to be_nil

    expect(project_bot_user_personal_access_token2.reload.group_id).to be_nil
    expect(project_bot_user_personal_access_token2.reload.user_type).to be_nil

    expect(service_account_user_personal_access_token1.reload.group_id).to be_nil
    expect(service_account_user_personal_access_token1.reload.user_type).to be_nil

    expect(service_account_user_personal_access_token2.reload.group_id).to be_nil
    expect(service_account_user_personal_access_token2.reload.user_type).to be_nil
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
