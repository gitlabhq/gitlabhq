# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers -- We need this many for this background migration
RSpec.describe Gitlab::BackgroundMigration::BackfillGroupIdAndUserTypeForNonhumanAccessTokens, feature_category: :system_access do
  context 'for service account PATs' do
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
    let(:projects) { table(:projects) }
    let(:users) { table(:users) }
    let(:user_details) { table(:user_details) }
    let(:personal_access_tokens) { table(:personal_access_tokens) }

    let!(:organization) { organizations.create!(name: 'organization', path: 'organization') }

    let(:group1) do
      namespaces.create!(
        name: 'group1',
        path: 'group1',
        type: 'Group',
        organization_id: organization.id
      ).tap do |ns|
        ns.update!(traversal_ids: [ns.id])
      end
    end

    let!(:human_user) do
      users.create!(
        username: 'human_user',
        email: 'human_user@example.com',
        user_type: 0,
        projects_limit: 10,
        organization_id: organization.id
      )
    end

    let!(:human_user_namespace) do
      namespaces.create!(
        name: 'HumanUserNamespace',
        path: 'human_user',
        type: 'User',
        owner_id: human_user.id,
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

    ################################################
    # project1: Project not part of a group
    ################################################

    let!(:project1_namespace) do
      namespaces.create!(
        name: 'Project1',
        path: 'project1',
        type: 'Project',
        traversal_ids: [human_user_namespace.id],
        organization_id: organization.id
      ).tap do |ns|
        ns.update!(traversal_ids: [human_user_namespace.id, ns.id])
      end
    end

    let!(:project1) do
      projects.create!(
        name: 'Project1',
        path: 'project1',
        namespace_id: human_user_namespace.id,
        project_namespace_id: project1_namespace.id,
        organization_id: organization.id
      )
    end

    let!(:project1_bot_user) do
      users.create!(
        username: 'project1_bot_user',
        email: 'project1_bot_user@example.com',
        user_type: 6,
        projects_limit: 10,
        organization_id: organization.id
      )
    end

    let!(:project1_bot_user_details) do
      user_details.create!(
        user_id: project1_bot_user.id,
        bot_namespace_id: project1_namespace.id
      )
    end

    let!(:project1_bot_user_personal_access_token1) do
      personal_access_tokens.create!(
        name: 'project_bot_user_personal_access_token1',
        user_id: project1_bot_user.id,
        organization_id: project1_bot_user.organization_id
      )
    end

    ################################################
    # Service Account user
    ################################################

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
        user_id: service_account_user.id,
        provisioned_by_group_id: group1.id
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

    ################################################
    # Service Account in non-top-level-group
    ################################################

    let(:group2_parent) do
      namespaces.create!(
        name: 'group2parent',
        path: 'group2parent',
        type: 'Group',
        organization_id: organization.id
      ).tap do |ns|
        ns.update!(traversal_ids: [ns.id])
      end
    end

    let(:group2) do
      namespaces.create!(
        name: 'group2',
        path: 'group2',
        type: 'Group',
        parent_id: group2_parent.id,
        organization_id: organization.id
      ).tap do |ns|
        ns.update!(traversal_ids: [group2_parent.id, ns.id])
      end
    end

    let!(:group2_service_account_user) do
      users.create!(
        username: 'group2_service_account_user',
        email: 'group2_service_account_user@example.com',
        user_type: 13,
        projects_limit: 10,
        organization_id: organization.id
      )
    end

    let!(:group2_service_account_user_details) do
      user_details.create!(
        user_id: group2_service_account_user.id,
        provisioned_by_group_id: group2.id
      )
    end

    let!(:group2_service_account_user_personal_access_token1) do
      personal_access_tokens.create!(
        name: 'group2_service_account_user_personal_access_token1',
        user_id: group2_service_account_user.id,
        organization_id: group2_service_account_user.organization_id
      )
    end

    ################################################
    # Begin Specs
    ################################################

    it "backfills group_id and user_type for service account personal access tokens", :aggregate_failures do
      expect(service_account_user_personal_access_token1.group_id).to be_nil
      expect(service_account_user_personal_access_token1.user_type).to be_nil

      expect(service_account_user_personal_access_token2.group_id).to be_nil
      expect(service_account_user_personal_access_token2.user_type).to be_nil

      expect(group2_service_account_user_personal_access_token1.group_id).to be_nil
      expect(group2_service_account_user_personal_access_token1.user_type).to be_nil

      migration.perform

      expect(service_account_user_personal_access_token1.reload.group_id).to eq(group1.id)
      expect(service_account_user_personal_access_token1.reload.user_type).to eq(13)

      expect(service_account_user_personal_access_token2.reload.group_id).to eq(group1.id)
      expect(service_account_user_personal_access_token2.reload.user_type).to eq(13)

      expect(group2_service_account_user_personal_access_token1.reload.group_id).to eq(group2_parent.id)
      expect(group2_service_account_user_personal_access_token1.reload.user_type).to eq(13)
    end

    it "does not backfill human users' personal access tokens", :aggregate_failures do
      expect(human_user_personal_access_token1.group_id).to be_nil
      expect(human_user_personal_access_token1.user_type).to be_nil

      expect(enterprise_user1_personal_access_token1.group_id).to be_nil
      expect(enterprise_user1_personal_access_token1.user_type).to be_nil

      expect(project1_bot_user_personal_access_token1.group_id).to be_nil
      expect(project1_bot_user_personal_access_token1.user_type).to be_nil

      migration.perform

      expect(human_user_personal_access_token1.reload.group_id).to be_nil
      expect(human_user_personal_access_token1.reload.user_type).to be_nil

      expect(enterprise_user1_personal_access_token1.reload.group_id).to be_nil
      expect(enterprise_user1_personal_access_token1.reload.user_type).to be_nil

      expect(project1_bot_user_personal_access_token1.reload.group_id).to be_nil
      expect(project1_bot_user_personal_access_token1.reload.user_type).to eq(6)
    end
  end

  context 'for resource access tokens' do
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
    let(:projects) { table(:projects) }
    let(:users) { table(:users) }
    let(:user_details) { table(:user_details) }
    let(:personal_access_tokens) { table(:personal_access_tokens) }

    let!(:organization) { organizations.create!(name: 'organization', path: 'organization') }

    let(:group1) { namespaces.create!(name: 'group1', path: 'group1', type: 'Group', organization_id: organization.id) }

    let!(:human_user) do
      users.create!(
        username: 'human_user',
        email: 'human_user@example.com',
        user_type: 0,
        projects_limit: 10,
        organization_id: organization.id
      )
    end

    let!(:human_user_namespace) do
      namespaces.create!(
        name: 'HumanUserNamespace',
        path: 'human_user',
        type: 'User',
        owner_id: human_user.id,
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

    ################################################
    # project1: Project not part of a group
    ################################################

    let!(:project1_namespace) do
      namespaces.create!(
        name: 'Project1',
        path: 'project1',
        type: 'Project',
        traversal_ids: [human_user_namespace.id],
        organization_id: organization.id
      ).tap do |ns|
        ns.update!(traversal_ids: [human_user_namespace.id, ns.id])
      end
    end

    let!(:project1) do
      projects.create!(
        name: 'Project1',
        path: 'project1',
        namespace_id: human_user_namespace.id,
        project_namespace_id: project1_namespace.id,
        organization_id: organization.id
      )
    end

    let!(:project1_bot_user) do
      users.create!(
        username: 'project1_bot_user',
        email: 'project1_bot_user@example.com',
        user_type: 6,
        projects_limit: 10,
        organization_id: organization.id
      )
    end

    let!(:project1_bot_user_details) do
      user_details.create!(
        user_id: project1_bot_user.id,
        bot_namespace_id: project1_namespace.id
      )
    end

    let!(:project1_bot_user_personal_access_token1) do
      personal_access_tokens.create!(
        name: 'project_bot_user_personal_access_token1',
        user_id: project1_bot_user.id,
        organization_id: project1_bot_user.organization_id
      )
    end

    let!(:project1_bot_user_personal_access_token2) do
      personal_access_tokens.create!(
        name: 'project_bot_user_personal_access_token2',
        user_id: project1_bot_user.id,
        organization_id: project1_bot_user.organization_id
      )
    end

    ################################################
    # Service Account user
    ################################################

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

    ################################################
    # project2: Project part of a top-level group
    ################################################

    let!(:project2_group) do
      namespaces.create!(
        name: 'Project2Group',
        path: 'project2group',
        type: 'Group',
        organization_id: organization.id
      ).tap do |ns|
        ns.update!(traversal_ids: [ns.id])
      end
    end

    let!(:project2_namespace) do
      namespaces.create!(
        name: 'Project2Namespace',
        path: 'project2namespace',
        type: 'Project',
        parent_id: project2_group.id,
        organization_id: organization.id
      ).tap do |ns|
        ns.update!(traversal_ids: [project2_group.id, ns.id])
      end
    end

    let!(:project2) do
      projects.create!(
        name: 'Project2',
        path: 'project2',
        namespace_id: project2_group.id,
        project_namespace_id: project2_namespace.id,
        organization_id: organization.id
      )
    end

    let!(:project2_bot_user) do
      users.create!(
        username: 'project2_bot_user',
        email: 'project2_bot_user@example.com',
        user_type: 6,
        projects_limit: 10,
        organization_id: organization.id
      )
    end

    let!(:project2_bot_user_details) do
      user_details.create!(
        user_id: project2_bot_user.id,
        bot_namespace_id: project2_namespace.id
      )
    end

    let!(:project2_bot_user_personal_access_token1) do
      personal_access_tokens.create!(
        name: 'project2_bot_user_personal_access_token1',
        user_id: project2_bot_user.id,
        organization_id: project2_bot_user.organization_id
      )
    end

    ################################################
    # project3: Project part of a top-level group
    ################################################

    let!(:project3_parent_group) do
      namespaces.create!(
        name: 'project3ParentGroup',
        path: 'project3parentgroup',
        type: 'Group',
        organization_id: organization.id
      ).tap do |ns|
        ns.update!(traversal_ids: [ns.id])
      end
    end

    let!(:project3_group) do
      namespaces.create!(
        name: 'project3Group',
        path: 'project3group',
        type: 'Group',
        parent_id: project3_parent_group.id,
        organization_id: organization.id
      ).tap do |ns|
        ns.update!(traversal_ids: [project3_parent_group.id, ns.id])
      end
    end

    let!(:project3_namespace) do
      namespaces.create!(
        name: 'project3Namespace',
        path: 'project3namespace',
        type: 'Project',
        parent_id: project3_group.id,
        organization_id: organization.id
      ).tap do |ns|
        ns.update!(traversal_ids: [project3_parent_group.id, project3_group.id, ns.id])
      end
    end

    let!(:project3) do
      projects.create!(
        name: 'project3',
        path: 'project3',
        namespace_id: project3_group.id,
        project_namespace_id: project3_namespace.id,
        organization_id: organization.id
      )
    end

    let!(:project3_bot_user) do
      users.create!(
        username: 'project3_bot_user',
        email: 'project3_bot_user@example.com',
        user_type: 6,
        projects_limit: 10,
        organization_id: organization.id
      )
    end

    let!(:project3_bot_user_details) do
      user_details.create!(
        user_id: project3_bot_user.id,
        bot_namespace_id: project3_namespace.id
      )
    end

    let!(:project3_bot_user_personal_access_token1) do
      personal_access_tokens.create!(
        name: 'project3_bot_user_personal_access_token1',
        user_id: project3_bot_user.id,
        organization_id: project3_bot_user.organization_id
      )
    end

    ################################################
    # group4: Group access token in sub-group
    ################################################

    let!(:group4_parent_group) do
      namespaces.create!(
        name: 'group4ParentGroup',
        path: 'group4parentgroup',
        type: 'Group',
        organization_id: organization.id
      ).tap do |ns|
        ns.update!(traversal_ids: [ns.id])
      end
    end

    let!(:group4_group) do
      namespaces.create!(
        name: 'group4Group',
        path: 'group4group',
        type: 'Group',
        parent_id: group4_parent_group.id,
        organization_id: organization.id
      ).tap do |ns|
        ns.update!(traversal_ids: [group4_parent_group.id, ns.id])
      end
    end

    let!(:group4_bot_user) do
      users.create!(
        username: 'group4_bot_user',
        email: 'group4_bot_user@example.com',
        user_type: 6,
        projects_limit: 10,
        organization_id: organization.id
      )
    end

    let!(:group4_bot_user_details) do
      user_details.create!(
        user_id: group4_bot_user.id,
        bot_namespace_id: group4_group.id
      )
    end

    let!(:group4_bot_user_personal_access_token1) do
      personal_access_tokens.create!(
        name: 'group4_bot_user_personal_access_token1',
        user_id: group4_bot_user.id,
        organization_id: group4_bot_user.organization_id
      )
    end

    ################################################
    # group5: Group access token in top-level-group
    ################################################

    let!(:group5_group) do
      namespaces.create!(
        name: 'group5Group',
        path: 'group5group',
        type: 'Group',
        organization_id: organization.id
      ).tap do |ns|
        ns.update!(traversal_ids: [ns.id])
      end
    end

    let!(:group5_bot_user) do
      users.create!(
        username: 'group5_bot_user',
        email: 'group5_bot_user@example.com',
        user_type: 6,
        projects_limit: 10,
        organization_id: organization.id
      )
    end

    let!(:group5_bot_user_details) do
      user_details.create!(
        user_id: group5_bot_user.id,
        bot_namespace_id: group5_group.id
      )
    end

    let!(:group5_bot_user_personal_access_token1) do
      personal_access_tokens.create!(
        name: 'group5_bot_user_personal_access_token1',
        user_id: group5_bot_user.id,
        organization_id: group5_bot_user.organization_id
      )
    end

    ################################################
    # Begin Specs
    ################################################

    it "backfills group_id and user_type for resource access tokens", :aggregate_failures do
      expect(project1_bot_user_personal_access_token1.group_id).to be_nil
      expect(project1_bot_user_personal_access_token1.user_type).to be_nil

      expect(project1_bot_user_personal_access_token2.group_id).to be_nil
      expect(project1_bot_user_personal_access_token2.user_type).to be_nil

      expect(project2_bot_user_personal_access_token1.group_id).to be_nil
      expect(project2_bot_user_personal_access_token1.user_type).to be_nil

      expect(project3_bot_user_personal_access_token1.group_id).to be_nil
      expect(project3_bot_user_personal_access_token1.user_type).to be_nil

      expect(group4_bot_user_personal_access_token1.group_id).to be_nil
      expect(group4_bot_user_personal_access_token1.user_type).to be_nil

      expect(group5_bot_user_personal_access_token1.group_id).to be_nil
      expect(group5_bot_user_personal_access_token1.user_type).to be_nil

      migration.perform

      expect(project1_bot_user_personal_access_token1.reload.group_id).to be_nil
      expect(project1_bot_user_personal_access_token1.reload.user_type).to eq(6)

      expect(project1_bot_user_personal_access_token2.reload.group_id).to be_nil
      expect(project1_bot_user_personal_access_token2.reload.user_type).to eq(6)

      expect(project2_bot_user_personal_access_token1.reload.group_id).to eq(project2_group.id)
      expect(project2_bot_user_personal_access_token1.reload.user_type).to eq(6)

      expect(project3_bot_user_personal_access_token1.reload.group_id).to eq(project3_parent_group.id)
      expect(project3_bot_user_personal_access_token1.reload.user_type).to eq(6)

      expect(group4_bot_user_personal_access_token1.reload.group_id).to eq(group4_parent_group.id)
      expect(group4_bot_user_personal_access_token1.reload.user_type).to eq(6)

      expect(group5_bot_user_personal_access_token1.reload.group_id).to eq(group5_group.id)
      expect(group5_bot_user_personal_access_token1.reload.user_type).to eq(6)
    end

    it "does not backfill human users' personal access tokens", :aggregate_failures do
      expect(human_user_personal_access_token1.group_id).to be_nil
      expect(human_user_personal_access_token1.user_type).to be_nil

      expect(human_user_personal_access_token2.group_id).to be_nil
      expect(human_user_personal_access_token2.user_type).to be_nil

      expect(enterprise_user1_personal_access_token1.group_id).to be_nil
      expect(enterprise_user1_personal_access_token1.user_type).to be_nil

      migration.perform

      expect(human_user_personal_access_token1.reload.group_id).to be_nil
      expect(human_user_personal_access_token1.reload.user_type).to be_nil

      expect(human_user_personal_access_token2.reload.group_id).to be_nil
      expect(human_user_personal_access_token2.reload.user_type).to be_nil

      expect(enterprise_user1_personal_access_token1.reload.group_id).to be_nil
      expect(enterprise_user1_personal_access_token1.reload.user_type).to be_nil
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
