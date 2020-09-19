# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::ProjectCreateService do
  let_it_be(:group_parent) { create(:group, :private) }
  let_it_be(:group) { create(:group, :private, parent: group_parent) }
  let_it_be(:group_child) { create(:group, :private, parent: group) }

  let_it_be(:group_project) { create(:project, group: group) }

  let_it_be(:parent_group_user) { create(:user) }
  let_it_be(:group_user) { create(:user) }
  let_it_be(:child_group_user) { create(:user) }

  let(:access_level) { Gitlab::Access::MAINTAINER }

  subject(:service) { described_class.new(group_project) }

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
          project_id: group_project.id,
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
          project_id: group_project.id,
          user_id: parent_group_user.id,
          access_level: access_level)
        expect(project_authorization).to exist
      end
    end

    context 'membership overrides' do
      context 'group hierarchy' do
        before do
          create(:group_member, access_level: Gitlab::Access::REPORTER, group: group_parent, user: group_user)
          create(:group_member, access_level: Gitlab::Access::DEVELOPER, group: group, user: group_user)
          ProjectAuthorization.delete_all
        end

        it 'creates project authorization' do
          expect { service.execute }.to(
            change { ProjectAuthorization.count }.from(0).to(1))

          project_authorization = ProjectAuthorization.where(
            project_id: group_project.id,
            user_id: group_user.id,
            access_level: Gitlab::Access::DEVELOPER)
          expect(project_authorization).to exist
        end
      end

      context 'group sharing' do
        let!(:shared_with_group) { create(:group) }

        before do
          create(:group_member, access_level: Gitlab::Access::REPORTER, group: group, user: group_user)
          create(:group_member, access_level: Gitlab::Access::MAINTAINER, group: shared_with_group, user: group_user)
          create(:group_member, :minimal_access, source: shared_with_group, user: create(:user))

          create(:group_group_link, shared_group: group, shared_with_group: shared_with_group, group_access: Gitlab::Access::DEVELOPER)

          ProjectAuthorization.delete_all
        end

        it 'creates project authorization' do
          expect { service.execute }.to(
            change { ProjectAuthorization.count }.from(0).to(1))

          project_authorization = ProjectAuthorization.where(
            project_id: group_project.id,
            user_id: group_user.id,
            access_level: Gitlab::Access::DEVELOPER)
          expect(project_authorization).to exist
        end

        it 'does not create project authorization for user with minimal access' do
          expect { service.execute }.to(
            change { ProjectAuthorization.count }.from(0).to(1))
        end
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

    context 'member with minimal access' do
      before do
        create(:group_member, :minimal_access, user: group_user, source: group)
      end

      it 'does not create project authorization' do
        expect { service.execute }.not_to(
          change { ProjectAuthorization.count }.from(0))
      end
    end

    context 'project has more user than BATCH_SIZE' do
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
            { user_id: user.id, project_id: group_project.id, access_level: access_level }
          end

          expect(ProjectAuthorization).to(
            receive(:insert_all).with(array_including(attributes)).and_call_original)
        end

        expect { service.execute }.to(
          change { ProjectAuthorization.count }.from(0).to(batch_size + 1))
      end
    end

    context 'ignores existing project authorizations' do
      before do
        # ProjectAuthorizations is also created because of an after_commit
        # callback on Member model
        create(:group_member, access_level: access_level, group: group, user: group_user)
      end

      it 'does not create project authorization' do
        project_authorization = ProjectAuthorization.where(
          project_id: group_project.id,
          user_id: group_user.id,
          access_level: access_level)

        expect { service.execute }.not_to(
          change { project_authorization.reload.exists? }.from(true))
      end
    end
  end
end
