# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe EnableProjectStudioForEarlyAccessParticipants, feature_category: :navigation do
  let(:migration) { described_class.new }
  let(:namespaces) { table(:namespaces) }
  let(:namespace_members) { table(:members) }
  let(:namespace_settings) { table(:namespace_settings) }
  let(:user_preferences) { table(:user_preferences) }
  let(:users) { table(:users) }
  let(:organizations) { table(:organizations) }

  let(:organization) { organizations.create!(path: 'org') }

  let!(:group_with_experimental_features) do
    group = namespaces.create!(
      name: "Group with experimental features enabled",
      path: "experimental-group",
      type: 'Group',
      organization_id: organization.id
    )
    namespace_settings.create!(namespace_id: group.id, experiment_features_enabled: true)
    group
  end

  let!(:standard_group) do
    group = namespaces.create!(
      name: "Standard group",
      path: "standard-group",
      type: 'Group',
      organization_id: organization.id
    )
    namespace_settings.create!(namespace_id: group.id, experiment_features_enabled: false)
    group
  end

  let!(:experimental_user_in_experimental_group) do
    users.create!(
      email: 'experimental_user_in_experimental_group@example.com',
      username: 'experimental_user_in_experimental_group',
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let!(:experimental_user_in_standard_group) do
    users.create!(
      email: 'experimental_user_in_standard_group@example.com',
      username: 'experimental_user_in_standard_group',
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let!(:experimental_user_without_group) do
    users.create!(
      email: 'experimental_user_without_group@example.com',
      username: 'experimental_user_without_group',
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let!(:standard_user) do
    users.create!(
      email: 'standard_user@example.com',
      username: 'standard_user',
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let!(:standard_user_in_experimental_group) do
    users.create!(
      email: 'standard_user_in_experimental_group@example.com',
      username: 'standard_user_in_experimental_group',
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let!(:experimental_user_in_experimental_group_preference) do
    user_preferences.create!(
      user_id: experimental_user_in_experimental_group.id,
      early_access_program_participant: true
    )
  end

  let!(:experimental_user_in_standard_group_preference) do
    user_preferences.create!(
      user_id: experimental_user_in_standard_group.id,
      early_access_program_participant: true
    )
  end

  let!(:experimental_user_without_group_preference) do
    user_preferences.create!(
      user_id: experimental_user_without_group.id,
      early_access_program_participant: true
    )
  end

  let!(:standard_user_preference) do
    user_preferences.create!(
      user_id: standard_user.id,
      early_access_program_participant: false
    )
  end

  let!(:standard_user_in_experimental_group_preference) do
    user_preferences.create!(
      user_id: standard_user_in_experimental_group.id,
      early_access_program_participant: false
    )
  end

  before do
    namespace_members.create!(
      source_id: group_with_experimental_features.id,
      source_type: 'Namespace',
      user_id: experimental_user_in_experimental_group.id,
      notification_level: 3,
      access_level: 30,
      member_namespace_id: group_with_experimental_features.id,
      type: 'GroupMember'
    )

    namespace_members.create!(
      source_id: standard_group.id,
      source_type: 'Namespace',
      user_id: experimental_user_in_standard_group.id,
      notification_level: 3,
      access_level: 30,
      member_namespace_id: standard_group.id,
      type: 'GroupMember'
    )

    namespace_members.create!(
      source_id: group_with_experimental_features.id,
      source_type: 'Namespace',
      user_id: standard_user_in_experimental_group.id,
      notification_level: 3,
      access_level: 30,
      member_namespace_id: group_with_experimental_features.id,
      type: 'GroupMember'
    )
  end

  describe '#up' do
    context 'when on GitLab.com', :saas do
      it 'enables project_studio_enabled and early_access_studio_participant for correct users' do
        expect { migration.up }.to change {
          user_preferences.where(project_studio_enabled: true).count
        }.from(0).to(2).and change {
          user_preferences.where(early_access_studio_participant: true).count
        }.from(0).to(2)

        expect(experimental_user_in_experimental_group_preference.reload.project_studio_enabled).to be true
        expect(experimental_user_in_experimental_group_preference.reload.early_access_studio_participant).to be true
        expect(standard_user_in_experimental_group_preference.reload.project_studio_enabled).to be true
        expect(standard_user_in_experimental_group_preference.reload.early_access_studio_participant).to be true

        expect(experimental_user_in_standard_group_preference.reload.project_studio_enabled).to be false
        expect(experimental_user_in_standard_group_preference.reload.early_access_studio_participant).to be false
        expect(experimental_user_without_group_preference.reload.project_studio_enabled).to be false
        expect(experimental_user_without_group_preference.reload.early_access_studio_participant).to be false
        expect(standard_user_preference.reload.project_studio_enabled).to be false
        expect(standard_user_preference.reload.early_access_studio_participant).to be false
      end

      context 'with multiple experimental groups' do
        let!(:second_experimental_group) do
          group = namespaces.create!(
            name: "Second experimental group",
            path: "second-experimental-group",
            type: 'Group',
            organization_id: organization.id
          )
          namespace_settings.create!(namespace_id: group.id, experiment_features_enabled: true)
          group
        end

        let!(:user_in_second_experimental_group) do
          users.create!(
            email: 'user_in_second_experimental_group@example.com',
            username: 'user_in_second_experimental_group',
            projects_limit: 10,
            organization_id: organization.id
          )
        end

        let!(:user_in_second_experimental_group_preference) do
          user_preferences.create!(
            user_id: user_in_second_experimental_group.id,
            early_access_program_participant: false
          )
        end

        before do
          namespace_members.create!(
            source_id: second_experimental_group.id,
            source_type: 'Namespace',
            user_id: user_in_second_experimental_group.id,
            notification_level: 3,
            access_level: 30,
            member_namespace_id: second_experimental_group.id,
            type: 'GroupMember'
          )
        end

        it 'processes users from multiple experimental groups in batches' do
          expect { migration.up }.to change {
            user_preferences.where(project_studio_enabled: true).count
          }.from(0).to(3).and change {
            user_preferences.where(early_access_studio_participant: true).count
          }.from(0).to(3)

          expect(experimental_user_in_experimental_group_preference.reload.project_studio_enabled).to be true
          expect(experimental_user_in_experimental_group_preference.reload.early_access_studio_participant).to be true
          expect(standard_user_in_experimental_group_preference.reload.project_studio_enabled).to be true
          expect(standard_user_in_experimental_group_preference.reload.early_access_studio_participant).to be true
          expect(user_in_second_experimental_group_preference.reload.project_studio_enabled).to be true
          expect(user_in_second_experimental_group_preference.reload.early_access_studio_participant).to be true
        end
      end
    end

    context 'when not on GitLab.com' do
      it 'does not change any user preferences' do
        expect { migration.up }.not_to change {
          [
            user_preferences.where(project_studio_enabled: true).count,
            user_preferences.where(early_access_studio_participant: true).count
          ]
        }
      end
    end
  end

  describe '#down' do
    it 'is a no-op' do
      expect { migration.down }.not_to change {
        user_preferences.where(project_studio_enabled: true).count
      }
    end
  end
end
