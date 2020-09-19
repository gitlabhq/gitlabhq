# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::ProjectGroupLinkCreateService do
  let_it_be(:group_parent) { create(:group, :private) }
  let_it_be(:group) { create(:group, :private, parent: group_parent) }
  let_it_be(:group_child) { create(:group, :private, parent: group) }

  let_it_be(:parent_group_user) { create(:user) }
  let_it_be(:group_user) { create(:user) }

  let_it_be(:project) { create(:project, :private, group: create(:group, :private)) }

  let(:access_level) { Gitlab::Access::MAINTAINER }
  let(:group_access) { nil }

  subject(:service) { described_class.new(project, group, group_access) }

  describe '#perform' do
    context 'direct group members' do
      before do
        create(:group_member, access_level: access_level, group: group, user: group_user)
        ProjectAuthorization.delete_all
      end

      it 'creates project authorization' do
        expect { service.execute }.to(
          change { ProjectAuthorization.count }.from(0).to(1))

        project_authorization = ProjectAuthorization.where(
          project_id: project.id,
          user_id: group_user.id,
          access_level: access_level)

        expect(project_authorization).to exist
      end
    end

    context 'inherited group members' do
      before do
        create(:group_member, access_level: access_level, group: group_parent, user: parent_group_user)
        ProjectAuthorization.delete_all
      end

      it 'creates project authorization' do
        expect { service.execute }.to(
          change { ProjectAuthorization.count }.from(0).to(1))

        project_authorization = ProjectAuthorization.where(
          project_id: project.id,
          user_id: parent_group_user.id,
          access_level: access_level)
        expect(project_authorization).to exist
      end
    end

    context 'with group_access' do
      let(:group_access) { Gitlab::Access::REPORTER }

      before do
        create(:group_member, access_level: access_level, group: group_parent, user: parent_group_user)
        ProjectAuthorization.delete_all
      end

      it 'creates project authorization' do
        expect { service.execute }.to(
          change { ProjectAuthorization.count }.from(0).to(1))

        project_authorization = ProjectAuthorization.where(
          project_id: project.id,
          user_id: parent_group_user.id,
          access_level: group_access)
        expect(project_authorization).to exist
      end
    end

    context 'membership overrides' do
      before do
        create(:group_member, access_level: Gitlab::Access::REPORTER, group: group_parent, user: group_user)
        create(:group_member, access_level: Gitlab::Access::DEVELOPER, group: group, user: group_user)
        ProjectAuthorization.delete_all
      end

      it 'creates project authorization' do
        expect { service.execute }.to(
          change { ProjectAuthorization.count }.from(0).to(1))

        project_authorization = ProjectAuthorization.where(
          project_id: project.id,
          user_id: group_user.id,
          access_level: Gitlab::Access::DEVELOPER)
        expect(project_authorization).to exist
      end
    end

    context 'no group member' do
      it 'does not create project authorization' do
        expect { service.execute }.not_to(
          change { ProjectAuthorization.count }.from(0))
      end
    end

    context 'unapproved access requests' do
      before do
        create(:group_member, :guest, :access_request, user: group_user, group: group)
      end

      it 'does not create project authorization' do
        expect { service.execute }.not_to(
          change { ProjectAuthorization.count }.from(0))
      end
    end

    context 'minimal access member' do
      before do
        create(:group_member, :minimal_access, user: group_user, source: group)
      end

      it 'does not create project authorization' do
        expect { service.execute }.not_to(
          change { ProjectAuthorization.count }.from(0))
      end
    end

    context 'project has more users than BATCH_SIZE' do
      let(:batch_size) { 2 }
      let(:users) { create_list(:user, batch_size + 1 ) }

      before do
        stub_const("#{described_class.name}::BATCH_SIZE", batch_size)

        users.each do |user|
          create(:group_member, access_level: access_level, group: group_parent, user: user)
        end

        ProjectAuthorization.delete_all
      end

      it 'bulk creates project authorizations in batches' do
        users.each_slice(batch_size) do |batch|
          attributes = batch.map do |user|
            { user_id: user.id, project_id: project.id, access_level: access_level }
          end

          expect(ProjectAuthorization).to(
            receive(:insert_all).with(array_including(attributes)).and_call_original)
        end

        expect { service.execute }.to(
          change { ProjectAuthorization.count }.from(0).to(batch_size + 1))
      end
    end

    context 'users have existing project authorizations' do
      before do
        create(:group_member, access_level: access_level, group: group, user: group_user)
        ProjectAuthorization.delete_all

        create(:project_authorization, user_id: group_user.id,
                                       project_id: project.id,
                                       access_level: existing_access_level)
      end

      context 'when access level is the same' do
        let(:existing_access_level) { access_level }

        it 'does not create project authorization' do
          project_authorization = ProjectAuthorization.where(
            project_id: project.id,
            user_id: group_user.id,
            access_level: existing_access_level)

          expect(ProjectAuthorization).not_to receive(:insert_all)

          expect { service.execute }.not_to(
            change { project_authorization.reload.exists? }.from(true))
        end
      end

      context 'when existing access level is lower' do
        let(:existing_access_level) { Gitlab::Access::DEVELOPER }

        it 'creates new project authorization' do
          project_authorization = ProjectAuthorization.where(
            project_id: project.id,
            user_id: group_user.id,
            access_level: access_level)

          expect { service.execute }.to(
            change { project_authorization.reload.exists? }.from(false).to(true))
        end

        it 'deletes previous project authorization' do
          project_authorization = ProjectAuthorization.where(
            project_id: project.id,
            user_id: group_user.id,
            access_level: existing_access_level)

          expect { service.execute }.to(
            change { project_authorization.reload.exists? }.from(true).to(false))
        end
      end

      context 'when existing access level is higher' do
        let(:existing_access_level) { Gitlab::Access::OWNER }

        it 'does not create project authorization' do
          project_authorization = ProjectAuthorization.where(
            project_id: project.id,
            user_id: group_user.id,
            access_level: existing_access_level)

          expect(ProjectAuthorization).not_to receive(:insert_all)

          expect { service.execute }.not_to(
            change { project_authorization.reload.exists? }.from(true))
        end
      end
    end
  end
end
