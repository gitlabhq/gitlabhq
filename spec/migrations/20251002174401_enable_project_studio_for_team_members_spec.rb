# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe EnableProjectStudioForTeamMembers, feature_category: :navigation do
  let(:migration) { described_class.new }
  let(:groups) { table(:namespaces) }
  let(:group_members) { table(:members) }
  let(:user_preferences) { table(:user_preferences) }
  let(:users) { table(:users) }
  let(:organizations) { table(:organizations) }

  let(:organization) { organizations.create!(path: 'org') }
  let!(:gitlab_com_group) do
    groups.create!(name: 'gitlab-com', path: 'gitlab-com', type: 'Group', organization_id: organization.id)
  end

  let!(:other_group) { groups.create!(name: 'other', path: 'other', type: 'Group', organization_id: organization.id) }

  let!(:user1) do
    users.create!(email: 'user1@example.com', username: 'user1', projects_limit: 10, organization_id: organization.id)
  end

  let!(:user2) do
    users.create!(email: 'user2@example.com', username: 'user2', projects_limit: 10, organization_id: organization.id)
  end

  let!(:user3) do
    users.create!(email: 'user3@example.com', username: 'user3', projects_limit: 10, organization_id: organization.id)
  end

  let!(:user_without_access) do
    users.create!(email: 'user4@example.com', username: 'user4', projects_limit: 10, organization_id: organization.id)
  end

  let!(:user1_preference) do
    user_preferences.create!(user_id: user1.id, project_studio_enabled: false)
  end

  let!(:user2_preference) do
    user_preferences.create!(user_id: user2.id, project_studio_enabled: false)
  end

  let!(:user3_preference) do
    user_preferences.create!(user_id: user3.id, project_studio_enabled: false)
  end

  let!(:user_without_access_preference) do
    user_preferences.create!(user_id: user_without_access.id, project_studio_enabled: false)
  end

  before do
    group_members.create!(
      source_id: gitlab_com_group.id,
      source_type: 'Namespace',
      user_id: user1.id,
      notification_level: 3,
      access_level: 30,
      member_namespace_id: gitlab_com_group.id,
      type: 'GroupMember'
    )

    group_members.create!(
      source_id: gitlab_com_group.id,
      source_type: 'Namespace',
      user_id: user2.id,
      notification_level: 3,
      access_level: 30,
      member_namespace_id: gitlab_com_group.id,
      type: 'GroupMember'
    )

    group_members.create!(
      source_id: gitlab_com_group.id,
      source_type: 'Namespace',
      user_id: user_without_access.id,
      notification_level: 3,
      access_level: 0,
      member_namespace_id: gitlab_com_group.id,
      type: 'GroupMember'
    )

    group_members.create!(
      source_id: other_group.id,
      source_type: 'Namespace',
      user_id: user3.id,
      notification_level: 3,
      access_level: 30,
      member_namespace_id: other_group.id,
      type: 'GroupMember'
    )
  end

  describe '#up' do
    context 'when on GitLab.com', :saas do
      it 'enables project_studio_enabled for gitlab-com group members' do
        expect { migration.up }.to change {
          user_preferences.where(project_studio_enabled: true).count
        }.from(0).to(2)

        expect(user1_preference.reload.project_studio_enabled).to be true
        expect(user2_preference.reload.project_studio_enabled).to be true
        expect(user3_preference.reload.project_studio_enabled).to be false
        expect(user_without_access_preference.reload.project_studio_enabled).to be false
      end

      context 'when gitlab-com group does not exist' do
        before do
          gitlab_com_group.delete
        end

        it 'does not change any user preferences' do
          expect { migration.up }.not_to change {
            user_preferences.where(project_studio_enabled: true).count
          }
        end
      end

      context 'when gitlab-com group has no members' do
        before do
          group_members.where(source_id: gitlab_com_group.id).delete_all
        end

        it 'does not change any user preferences' do
          expect { migration.up }.not_to change {
            user_preferences.where(project_studio_enabled: true).count
          }
        end
      end
    end

    context 'when not on GitLab.com' do
      it 'does not change any user preferences' do
        expect { migration.up }.not_to change {
          user_preferences.where(project_studio_enabled: true).count
        }

        expect(user1_preference.reload.project_studio_enabled).to be false
        expect(user2_preference.reload.project_studio_enabled).to be false
        expect(user3_preference.reload.project_studio_enabled).to be false
        expect(user_without_access_preference.reload.project_studio_enabled).to be false
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
