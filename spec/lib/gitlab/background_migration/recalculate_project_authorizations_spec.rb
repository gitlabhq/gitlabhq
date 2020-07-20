# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RecalculateProjectAuthorizations, schema: 20200204113223 do
  let(:users_table) { table(:users) }
  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }
  let(:project_authorizations_table) { table(:project_authorizations) }
  let(:members_table) { table(:members) }
  let(:group_group_links) { table(:group_group_links) }
  let(:project_group_links) { table(:project_group_links) }

  let(:user) { users_table.create!(id: 1, email: 'user@example.com', projects_limit: 10) }
  let(:group) { namespaces_table.create!(type: 'Group', name: 'group', path: 'group') }

  subject { described_class.new.perform([user.id]) }

  context 'missing authorization' do
    context 'personal project' do
      before do
        user_namespace = namespaces_table.create!(owner_id: user.id, name: 'User', path: 'user')
        projects_table.create!(id: 1,
                               name: 'personal-project',
                               path: 'personal-project',
                               visibility_level: 0,
                               namespace_id: user_namespace.id)
      end

      it 'creates correct authorization' do
        expect { subject }.to change { project_authorizations_table.count }.from(0).to(1)
        expect(project_authorizations_table.all).to(
          match_array([have_attributes(user_id: 1, project_id: 1, access_level: 40)]))
      end
    end

    context 'group membership' do
      before do
        projects_table.create!(id: 1, name: 'group-project', path: 'group-project',
                               visibility_level: 0, namespace_id: group.id)
        members_table.create!(user_id: user.id, source_id: group.id, source_type: 'Namespace',
                              type: 'GroupMember', access_level: 20, notification_level: 3)
      end

      it 'creates correct authorization' do
        expect { subject }.to change { project_authorizations_table.count }.from(0).to(1)
        expect(project_authorizations_table.all).to(
          match_array([have_attributes(user_id: 1, project_id: 1, access_level: 20)]))
      end
    end

    context 'inherited group membership' do
      before do
        sub_group = namespaces_table.create!(type: 'Group', name: 'subgroup',
                                             path: 'subgroup', parent_id: group.id)
        projects_table.create!(id: 1, name: 'group-project', path: 'group-project',
                               visibility_level: 0, namespace_id: sub_group.id)
        members_table.create!(user_id: user.id, source_id: group.id, source_type: 'Namespace',
                              type: 'GroupMember', access_level: 20, notification_level: 3)
      end

      it 'creates correct authorization' do
        expect { subject }.to change { project_authorizations_table.count }.from(0).to(1)
        expect(project_authorizations_table.all).to(
          match_array([have_attributes(user_id: 1, project_id: 1, access_level: 20)]))
      end
    end

    context 'project membership' do
      before do
        project = projects_table.create!(id: 1, name: 'group-project', path: 'group-project',
                                         visibility_level: 0, namespace_id: group.id)
        members_table.create!(user_id: user.id, source_id: project.id, source_type: 'Project',
                              type: 'ProjectMember', access_level: 20, notification_level: 3)
      end

      it 'creates correct authorization' do
        expect { subject }.to change { project_authorizations_table.count }.from(0).to(1)
        expect(project_authorizations_table.all).to(
          match_array([have_attributes(user_id: 1, project_id: 1, access_level: 20)]))
      end
    end

    context 'shared group' do
      before do
        members_table.create!(user_id: user.id, source_id: group.id, source_type: 'Namespace',
                              type: 'GroupMember', access_level: 30, notification_level: 3)

        shared_group = namespaces_table.create!(type: 'Group', name: 'shared group',
                                                path: 'shared-group')
        projects_table.create!(id: 1, name: 'project', path: 'project', visibility_level: 0,
                               namespace_id: shared_group.id)

        group_group_links.create(shared_group_id: shared_group.id, shared_with_group_id: group.id,
                                 group_access: 20)
      end

      it 'creates correct authorization' do
        expect { subject }.to change { project_authorizations_table.count }.from(0).to(1)
        expect(project_authorizations_table.all).to(
          match_array([have_attributes(user_id: 1, project_id: 1, access_level: 20)]))
      end
    end

    context 'shared project' do
      before do
        members_table.create!(user_id: user.id, source_id: group.id, source_type: 'Namespace',
                              type: 'GroupMember', access_level: 30, notification_level: 3)

        another_group = namespaces_table.create!(type: 'Group', name: 'another group', path: 'another-group')
        shared_project = projects_table.create!(id: 1, name: 'shared project', path: 'shared-project',
                                                visibility_level: 0, namespace_id: another_group.id)

        project_group_links.create(project_id: shared_project.id, group_id: group.id, group_access: 20)
      end

      it 'creates correct authorization' do
        expect { subject }.to change { project_authorizations_table.count }.from(0).to(1)
        expect(project_authorizations_table.all).to(
          match_array([have_attributes(user_id: 1, project_id: 1, access_level: 20)]))
      end
    end
  end

  context 'unapproved access requests' do
    context 'group membership' do
      before do
        projects_table.create!(id: 1, name: 'group-project', path: 'group-project',
                               visibility_level: 0, namespace_id: group.id)
        members_table.create!(user_id: user.id, source_id: group.id, source_type: 'Namespace',
                              type: 'GroupMember', access_level: 20, requested_at: Time.now, notification_level: 3)
      end

      it 'does not create authorization' do
        expect { subject }.not_to change { project_authorizations_table.count }.from(0)
      end
    end

    context 'inherited group membership' do
      before do
        sub_group = namespaces_table.create!(type: 'Group', name: 'subgroup', path: 'subgroup',
                                             parent_id: group.id)
        projects_table.create!(id: 1, name: 'group-project', path: 'group-project',
                               visibility_level: 0, namespace_id: sub_group.id)
        members_table.create!(user_id: user.id, source_id: group.id, source_type: 'Namespace',
                              type: 'GroupMember', access_level: 20, requested_at: Time.now, notification_level: 3)
      end

      it 'does not create authorization' do
        expect { subject }.not_to change { project_authorizations_table.count }.from(0)
      end
    end

    context 'project membership' do
      before do
        project = projects_table.create!(id: 1, name: 'group-project', path: 'group-project',
                                         visibility_level: 0, namespace_id: group.id)
        members_table.create!(user_id: user.id, source_id: project.id, source_type: 'Project',
                              type: 'ProjectMember', access_level: 20, requested_at: Time.now, notification_level: 3)
      end

      it 'does not create authorization' do
        expect { subject }.not_to change { project_authorizations_table.count }.from(0)
      end
    end

    context 'shared group' do
      before do
        members_table.create!(user_id: user.id, source_id: group.id, source_type: 'Namespace',
                              type: 'GroupMember', access_level: 30, requested_at: Time.now, notification_level: 3)

        shared_group = namespaces_table.create!(type: 'Group', name: 'shared group',
                                                path: 'shared-group')
        projects_table.create!(id: 1, name: 'project', path: 'project', visibility_level: 0,
                               namespace_id: shared_group.id)

        group_group_links.create(shared_group_id: shared_group.id, shared_with_group_id: group.id,
                                 group_access: 20)
      end

      it 'does not create authorization' do
        expect { subject }.not_to change { project_authorizations_table.count }.from(0)
      end
    end

    context 'shared project' do
      before do
        members_table.create!(user_id: user.id, source_id: group.id, source_type: 'Namespace',
                              type: 'GroupMember', access_level: 30, requested_at: Time.now, notification_level: 3)

        another_group = namespaces_table.create!(type: 'Group', name: 'another group', path: 'another-group')
        shared_project = projects_table.create!(id: 1, name: 'shared project', path: 'shared-project',
                                                visibility_level: 0, namespace_id: another_group.id)

        project_group_links.create(project_id: shared_project.id, group_id: group.id, group_access: 20)
      end

      it 'does not create authorization' do
        expect { subject }.not_to change { project_authorizations_table.count }.from(0)
      end
    end
  end

  context 'incorrect authorization' do
    before do
      project = projects_table.create!(id: 1, name: 'group-project', path: 'group-project',
                                       visibility_level: 0, namespace_id: group.id)
      members_table.create!(user_id: user.id, source_id: group.id, source_type: 'Namespace',
                            type: 'GroupMember', access_level: 30, notification_level: 3)

      project_authorizations_table.create!(user_id: user.id, project_id: project.id,
                                           access_level: 10)
    end

    it 'fixes authorization' do
      expect { subject }.not_to change { project_authorizations_table.count }.from(1)
      expect(project_authorizations_table.all).to(
        match_array([have_attributes(user_id: 1, project_id: 1, access_level: 30)]))
    end
  end

  context 'unwanted authorization' do
    before do
      project = projects_table.create!(name: 'group-project', path: 'group-project',
                                       visibility_level: 0, namespace_id: group.id)

      project_authorizations_table.create!(user_id: user.id, project_id: project.id,
                                           access_level: 10)
    end

    it 'deletes authorization' do
      expect { subject }.to change { project_authorizations_table.count }.from(1).to(0)
    end
  end

  context 'deleted user' do
    it 'does not fail' do
      expect { described_class.new.perform([non_existing_record_id]) }.not_to raise_error
    end
  end
end
