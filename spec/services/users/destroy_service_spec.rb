# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::DestroyService, feature_category: :user_management do
  let!(:user)      { create(:user) }
  let!(:admin)     { create(:admin) }
  let!(:namespace) { user.namespace }
  let!(:project)   { create(:project, namespace: namespace) }
  let(:service)    { described_class.new(admin) }
  let(:gitlab_shell) { Gitlab::Shell.new }

  describe "Initiates user deletion and deletes all their personal projects", :enable_admin_mode do
    context 'no options are given' do
      it 'creates GhostUserMigration record to handle migration in a worker' do
        expect { service.execute(user) }
          .to(
            change do
              Users::GhostUserMigration.where(user: user, initiator_user: admin).exists?
            end.from(false).to(true))
      end

      it 'will delete the personal project' do
        expect_next_instance_of(Projects::DestroyService) do |destroy_service|
          expect(destroy_service).to receive(:execute).once.and_return(true)
        end

        service.execute(user)
      end
    end

    context 'personal projects in pending_delete' do
      before do
        project.pending_delete = true
        project.save!
      end

      it 'destroys a personal project in pending_delete' do
        expect_next_instance_of(Projects::DestroyService) do |destroy_service|
          expect(destroy_service).to receive(:execute).once.and_return(true)
        end

        service.execute(user)
      end
    end

    context "solo owned groups present" do
      let(:solo_owned)  { create(:group) }
      let(:member)      { create(:group_member) }
      let(:user)        { member.user }

      before do
        solo_owned.group_members = [member]
      end

      it 'returns the user with attached errors' do
        expect(service.execute(user)).to be(user)
        expect(user.errors.full_messages).to(
          contain_exactly('You must transfer ownership or delete groups before you can remove user'))
      end

      it 'does not delete the user, nor the group' do
        service.execute(user)

        expect(User.find(user.id)).to eq user
        expect(Group.find(solo_owned.id)).to eq solo_owned
      end
    end

    context "deletions with solo owned groups" do
      let(:solo_owned)      { create(:group) }
      let(:member)          { create(:group_member) }
      let(:user)            { member.user }

      before do
        solo_owned.group_members = [member]
        service.execute(user, delete_solo_owned_groups: true)
      end

      it 'deletes solo owned groups' do
        expect { Group.find(solo_owned.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'deletions with inherited group owners' do
      let(:group) { create(:group, :nested) }
      let(:user) { create(:user) }
      let(:inherited_owner) { create(:user) }

      before do
        group.parent.add_owner(inherited_owner)
        group.add_owner(user)

        service.execute(user, delete_solo_owned_groups: true)
      end

      it 'does not delete the group' do
        expect(Group.exists?(id: group)).to be_truthy
      end
    end

    describe "user personal's repository removal" do
      context 'storages' do
        before do
          perform_enqueued_jobs { service.execute(user) }
        end

        context 'legacy storage' do
          let!(:project) { create(:project, :empty_repo, :legacy_storage, namespace: user.namespace) }

          it 'removes repository' do
            expect(
              gitlab_shell.repository_exists?(project.repository_storage, "#{project.disk_path}.git")
            ).to be_falsey
          end
        end

        context 'hashed storage' do
          let!(:project) { create(:project, :empty_repo, namespace: user.namespace) }

          it 'removes repository' do
            expect(
              gitlab_shell.repository_exists?(project.repository_storage, "#{project.disk_path}.git")
            ).to be_falsey
          end
        end
      end

      context 'repository removal status is taken into account' do
        it 'raises exception' do
          expect_next_instance_of(::Projects::DestroyService) do |destroy_service|
            expect(destroy_service).to receive(:execute).and_return(false)
          end

          expect { service.execute(user) }
            .to raise_error(Users::DestroyService::DestroyError, "Project #{project.id} can't be deleted")
        end
      end
    end

    describe "calls the before/after callbacks" do
      it 'of project_members' do
        expect_any_instance_of(ProjectMember).to receive(:run_callbacks).with(:find).once
        expect_any_instance_of(ProjectMember).to receive(:run_callbacks).with(:initialize).once
        expect_any_instance_of(ProjectMember).to receive(:run_callbacks).with(:destroy).once

        service.execute(user)
      end

      it 'of group_members' do
        group_member = create(:group_member)
        group_member.group.group_members.create!(user: user, access_level: 40)

        expect_any_instance_of(GroupMember).to receive(:run_callbacks).with(:find).once
        expect_any_instance_of(GroupMember).to receive(:run_callbacks).with(:initialize).once
        expect_any_instance_of(GroupMember).to receive(:run_callbacks).with(:destroy).once

        service.execute(user)
      end
    end

    describe 'prometheus metrics', :prometheus do
      context 'scheduled records' do
        context 'with a single record' do
          it 'updates the scheduled records gauge' do
            service.execute(user)

            gauge = Gitlab::Metrics.registry.get(:gitlab_ghost_user_migration_scheduled_records_total)
            expect(gauge.get).to eq(1)
          end
        end

        context 'with approximate count due to large number of records' do
          it 'updates the scheduled records gauge' do
            allow(Users::GhostUserMigration)
              .to(receive_message_chain(:limit, :count).and_return(1001))
            allow(Users::GhostUserMigration).to(receive(:minimum)).and_return(42)
            allow(Users::GhostUserMigration).to(receive(:maximum)).and_return(9042)

            service.execute(user)

            gauge = Gitlab::Metrics.registry.get(:gitlab_ghost_user_migration_scheduled_records_total)
            expect(gauge.get).to eq(9000)
          end
        end
      end

      context 'lag' do
        it 'update the lag gauge', :freeze_time do
          create(:ghost_user_migration, created_at: 10.minutes.ago)

          service.execute(user)

          gauge = Gitlab::Metrics.registry.get(:gitlab_ghost_user_migration_lag_seconds)
          expect(gauge.get).to eq(600)
        end
      end
    end
  end

  describe "Deletion permission checks" do
    it 'does not delete the user when user is not an admin' do
      other_user = create(:user)

      expect { described_class.new(other_user).execute(user) }.to raise_error(Gitlab::Access::AccessDeniedError)

      expect(Users::GhostUserMigration).not_to be_exists
    end

    context 'when admin mode is enabled', :enable_admin_mode do
      it 'allows admins to delete anyone' do
        expect { described_class.new(admin).execute(user) }
          .to(
            change do
              Users::GhostUserMigration.where(user: user, initiator_user: admin).exists?
            end.from(false).to(true))
      end
    end

    context 'when admin mode is disabled' do
      it 'disallows admins to delete anyone' do
        expect { described_class.new(admin).execute(user) }.to raise_error(Gitlab::Access::AccessDeniedError)

        expect(Users::GhostUserMigration).not_to be_exists
      end
    end

    context 'when running the service twice for a user with no personal projects' do
      let!(:project) { nil }

      it 'does not create a second ghost user migration and does not raise an exception' do
        expect { described_class.new(user).execute(user) }
          .to change { Users::GhostUserMigration.where(user: user).count }.by(1)

        expect do
          expect { described_class.new(user).execute(user) }.not_to raise_exception
        end.not_to change { Users::GhostUserMigration.where(user: user).count }
      end
    end

    it 'allows users to delete their own account' do
      expect { described_class.new(user).execute(user) }
        .to(
          change do
            Users::GhostUserMigration.where(user: user, initiator_user: user).exists?
          end.from(false).to(true))
    end

    it 'allows user to be deleted if skip_authorization: true' do
      other_user = create(:user)

      expect do
        described_class.new(user)
                       .execute(other_user, skip_authorization: true)
      end.to(
        change do
          Users::GhostUserMigration.where(user: other_user, initiator_user: user).exists?
        end.from(false).to(true))
    end

    describe 'user is the only organization owner' do
      let(:organization) { create(:organization) }

      before do
        organization.add_owner(user)
      end

      it 'returns the user with attached errors' do
        described_class.new(user).execute(user)

        expect(user.errors.full_messages).to(
          contain_exactly('You must transfer ownership of organizations before you can remove user'))
      end
    end
  end
end
