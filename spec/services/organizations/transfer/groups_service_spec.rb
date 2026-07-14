# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::Transfer::GroupsService, :aggregate_failures, feature_category: :organization do
  let_it_be(:old_organization) { create(:organization) }
  let_it_be(:new_organization) { create(:organization) }
  let_it_be(:user) { create(:user, organization: old_organization) }
  let_it_be_with_refind(:group) { create(:group, organization: old_organization) }

  let(:service) { described_class.new(group: group, new_organization: new_organization, current_user: user) }

  before_all do
    group.add_owner(user)
    new_organization.add_owner(user)
  end

  describe '#execute' do
    context 'when transfer is successful' do
      let_it_be_with_refind(:subgroup) { create(:group, parent: group, organization: old_organization) }
      let_it_be_with_refind(:nested_subgroup) { create(:group, parent: subgroup, organization: old_organization) }
      let_it_be_with_refind(:project) { create(:project, namespace: group, organization: old_organization) }
      let_it_be_with_refind(:subgroup_project) do
        create(:project, namespace: subgroup, organization: old_organization)
      end

      let_it_be_with_refind(:nested_project) do
        create(:project, namespace: nested_subgroup, organization: old_organization)
      end

      it 'returns success ServiceResponse' do
        result = service.execute
        expect(result).to be_a(ServiceResponse)
        expect(result).to be_success
        expect(result.message).to be_nil
      end

      it 'executes within a database transaction' do
        expect(Group).to receive(:transaction).and_call_original

        service.execute
      end

      it 'updates organization_id for group, all descendants and projects' do
        service.execute

        expect(group.reload.organization_id).to eq(new_organization.id)
        expect(subgroup.reload.organization_id).to eq(new_organization.id)
        expect(nested_subgroup.reload.organization_id).to eq(new_organization.id)

        expect(project.reload.organization_id).to eq(new_organization.id)
        expect(subgroup_project.reload.organization_id).to eq(new_organization.id)
        expect(nested_project.reload.organization_id).to eq(new_organization.id)

        expect(project.project_namespace.reload.organization_id).to eq(new_organization.id)
        expect(subgroup_project.project_namespace.reload.organization_id).to eq(new_organization.id)
        expect(nested_project.project_namespace.reload.organization_id).to eq(new_organization.id)

        expect(group).to be_valid
        expect(subgroup).to be_valid
        expect(nested_subgroup).to be_valid
        expect(project).to be_valid
        expect(subgroup_project).to be_valid
        expect(nested_project).to be_valid
        expect(project.project_namespace).to be_valid
        expect(subgroup_project.project_namespace).to be_valid
        expect(nested_project.project_namespace).to be_valid
      end

      describe 'visibility level updates' do
        context 'when new organization has lower visibility than some groups/projects' do
          let_it_be(:new_organization) { create(:organization, visibility_level: Gitlab::VisibilityLevel::PRIVATE, owners: user) }
          let_it_be_with_refind(:public_subgroup) do
            create(:group, :public, parent: group, organization: old_organization)
          end

          let_it_be_with_refind(:internal_subgroup) do
            create(:group, :internal, parent: group, organization: old_organization)
          end

          let_it_be_with_refind(:private_subgroup) do
            create(:group, :private, parent: group, organization: old_organization)
          end

          let_it_be_with_refind(:public_project) do
            create(:project, :public, namespace: group, organization: old_organization)
          end

          let_it_be_with_refind(:internal_project) do
            create(:project, :internal, namespace: subgroup, organization: old_organization)
          end

          let_it_be_with_refind(:private_project) do
            create(:project, :private, namespace: group, organization: old_organization)
          end

          it 'updates visibility for groups with higher visibility than organization' do
            service.execute

            expect(public_subgroup.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(internal_subgroup.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)

            expect(public_subgroup).to be_valid
            expect(internal_subgroup).to be_valid
          end

          it 'does not update visibility for groups with lower or equal visibility' do
            service.execute

            expect(private_subgroup.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(private_subgroup).to be_valid
          end

          it 'updates visibility for projects with higher visibility than organization' do
            service.execute

            expect(public_project.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(internal_project.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)

            expect(public_project).to be_valid
            expect(internal_project).to be_valid
          end

          it 'updates visibility for project namespaces with higher visibility' do
            service.execute

            expect(public_project.project_namespace.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(internal_project.project_namespace.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)

            expect(public_project).to be_valid
            expect(internal_project).to be_valid
          end

          it 'does not update visibility for projects with lower or equal visibility' do
            service.execute

            expect(private_project.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(private_project).to be_valid
          end
        end

        context 'when new organization has higher visibility than some groups/projects' do
          let_it_be(:new_organization) { create(:organization, visibility_level: Gitlab::VisibilityLevel::PUBLIC, owners: user) }
          let_it_be_with_refind(:private_subgroup) do
            create(:group, :private, parent: group, organization: old_organization)
          end

          let_it_be_with_refind(:internal_subgroup) do
            create(:group, :internal, parent: group, organization: old_organization)
          end

          let_it_be_with_refind(:private_project) do
            create(:project, :private, namespace: group, organization: old_organization)
          end

          it 'does not update visibility for groups with lower visibility' do
            service.execute

            expect(private_subgroup.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(internal_subgroup.reload.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)

            expect(private_subgroup).to be_valid
            expect(internal_subgroup).to be_valid
          end

          it 'does not update visibility for projects with lower visibility' do
            service.execute

            expect(private_project.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(private_project).to be_valid
          end
        end
      end

      it 'logs successful transfer with correct payload' do
        allow(Gitlab::AppLogger).to receive(:info).and_call_original

        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: "Group was transferred to a new organization",
            group_path: group.full_path,
            group_id: group.id,
            new_organization_path: new_organization.full_path,
            new_organization_id: new_organization.id,
            error_message: nil
          )
        ).and_call_original

        service.execute
      end

      it 'publishes a GroupTransferredEvent' do
        expect { service.execute }.to publish_event(Organizations::GroupTransferredEvent)
          .with(
            group_id: group.id,
            old_organization_id: old_organization.id,
            new_organization_id: new_organization.id
          )
      end

      context 'for runner transfers' do
        it 'enqueues TransferOrganizationWorker with correct arguments' do
          expect(Ci::Runners::TransferOrganizationWorker).to receive(:perform_async).with(
            group.id, old_organization.id, new_organization.id
          )

          service.execute
        end
      end

      context 'for oauth applications' do
        it 'updates organization_id for group-owned oauth applications' do
          app = create(:oauth_application, owner_id: group.id, owner_type: 'Namespace',
            organization: old_organization)

          service.execute

          expect(app.reload.organization_id).to eq(new_organization.id)
        end

        it 'updates organization_id for subgroup-owned oauth applications' do
          app = create(:oauth_application, owner_id: subgroup.id, owner_type: 'Namespace',
            organization: old_organization)

          service.execute

          expect(app.reload.organization_id).to eq(new_organization.id)
        end

        it 'does not update user-owned oauth applications' do
          user_app = create(:oauth_application, owner: user, organization: old_organization)

          expect { service.execute }.not_to change { user_app.reload.organization_id }
        end
      end
    end

    context 'when group is not root' do
      let_it_be(:parent_group) { create(:group, organization: old_organization) }
      let_it_be_with_refind(:subgroup) { create(:group, parent: parent_group, organization: old_organization) }
      let(:service) { described_class.new(group: subgroup, new_organization: new_organization, current_user: user) }

      it 'returns error ServiceResponse' do
        result = service.execute

        expect(result).to be_error
        expect(result.reason).to eq(:group_not_root)
        expect(result.message).to eq(
          format(
            s_('TransferOrganization|Group organization transfer failed: %{error_message}'),
            error_message:
              s_('TransferOrganization|Only top-level groups can be transferred to a different organization.')
          )
        )
      end

      it 'does not update organization_id' do
        original_organization_id = subgroup.organization_id

        service.execute

        expect(subgroup.reload.organization_id).to eq(original_organization_id)
      end
    end

    context 'when group is already in the target organization' do
      let_it_be(:group_in_new_org) { create(:group, organization: new_organization, owners: user) }
      let(:service) do
        described_class.new(group: group_in_new_org, new_organization: new_organization, current_user: user)
      end

      it 'returns error ServiceResponse' do
        result = service.execute

        expect(result).to be_error
        expect(result.reason).to eq(:already_transferred)
        expect(result.message).to eq(
          format(
            s_('TransferOrganization|Group organization transfer failed: %{error_message}'),
            error_message: s_('TransferOrganization|Group is already in the target organization.')
          )
        )
      end

      it 'does not update organization_id' do
        expect { service.execute }.not_to change { group_in_new_org.reload.organization_id }
      end

      it 'does not enqueue TransferOrganizationWorker' do
        expect(Ci::Runners::TransferOrganizationWorker).not_to receive(:perform_async)

        service.execute
      end
    end

    context 'when top-level group is at the target but descendants are not' do
      # Simulates the activation flow: Organizations::ConfirmService has
      # moved the top-level group's organization_id, but the descendants
      # and their projects still belong to the previous organization.
      let_it_be_with_refind(:top_level) { create(:group, organization: old_organization, owners: user) }
      let_it_be_with_refind(:subgroup) { create(:group, parent: top_level, organization: old_organization) }
      let_it_be_with_refind(:nested_project) do
        create(:project, namespace: subgroup, organization: old_organization)
      end

      let(:service) do
        described_class.new(group: top_level, new_organization: new_organization, current_user: user)
      end

      before do
        # Mimic Organizations::ConfirmService having moved only the top-level
        # group's organization_id forward, without touching descendants.
        top_level.update_column(:organization_id, new_organization.id)
      end

      it 'transfers the descendants to the new organization' do
        expect(service.execute).to be_success

        expect(subgroup.reload.organization_id).to eq(new_organization.id)
        expect(nested_project.reload.organization_id).to eq(new_organization.id)
        expect(nested_project.project_namespace.reload.organization_id).to eq(new_organization.id)
      end

      it 'publishes GroupTransferredEvent with the descendants source organization' do
        expect { service.execute }.to publish_event(Organizations::GroupTransferredEvent).with(
          group_id: top_level.id,
          old_organization_id: old_organization.id,
          new_organization_id: new_organization.id
        )
      end

      it 'enqueues TransferOrganizationWorker with the descendants source organization' do
        expect(Ci::Runners::TransferOrganizationWorker).to receive(:perform_async)
          .with(top_level.id, old_organization.id, new_organization.id)

        service.execute
      end
    end

    context 'when user lacks permissions' do
      context 'when user is not group owner' do
        let_it_be(:non_group_owner) { create(:user, organization: old_organization) }
        let(:service) do
          described_class.new(group: group, new_organization: new_organization, current_user: non_group_owner)
        end

        before_all do
          new_organization.add_owner(non_group_owner)
        end

        it 'returns error ServiceResponse' do
          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq(
            format(
              s_('TransferOrganization|Group organization transfer failed: %{error_message}'),
              error_message: s_('TransferOrganization|You must be an owner of both the group and new organization.')
            )
          )
        end

        it 'does not update organization_id' do
          original_organization_id = group.organization_id

          service.execute

          expect(group.reload.organization_id).to eq(original_organization_id)
        end
      end

      context 'when user is not organization owner' do
        let_it_be(:non_org_owner) { create(:user, organization: old_organization) }
        let(:service) do
          described_class.new(group: group, new_organization: new_organization, current_user: non_org_owner)
        end

        before_all do
          group.add_owner(non_org_owner)
        end

        it 'returns error ServiceResponse' do
          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq(
            format(
              s_('TransferOrganization|Group organization transfer failed: %{error_message}'),
              error_message: s_('TransferOrganization|You must be an owner of both the group and new organization.')
            )
          )
        end

        it 'does not update organization_id' do
          original_organization_id = group.organization_id

          service.execute

          expect(group.reload.organization_id).to eq(original_organization_id)
        end
      end

      context 'when user is neither group nor organization owner' do
        let_it_be(:non_owner) { create(:user, organization: old_organization) }
        let(:service) do
          described_class.new(group: group, new_organization: new_organization, current_user: non_owner)
        end

        it 'returns error ServiceResponse' do
          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq(
            format(
              s_('TransferOrganization|Group organization transfer failed: %{error_message}'),
              error_message: s_('TransferOrganization|You must be an owner of both the group and new organization.')
            )
          )
        end

        it 'does not update organization_id' do
          original_organization_id = group.organization_id

          service.execute

          expect(group.reload.organization_id).to eq(original_organization_id)
        end
      end

      context 'when user is an admin without admin mode' do
        let_it_be(:admin_user) { create(:admin) }

        let(:service) do
          described_class.new(group: group, new_organization: new_organization, current_user: admin_user)
        end

        it 'returns error ServiceResponse' do
          result = service.execute

          expect(result).to be_error
          expect(result.message).to eq(
            format(
              s_('TransferOrganization|Group organization transfer failed: %{error_message}'),
              error_message: s_('TransferOrganization|You must be an owner of both the group and new organization.')
            )
          )
        end

        it 'does not update organization_id' do
          original_organization_id = group.organization_id

          service.execute

          expect(group.reload.organization_id).to eq(original_organization_id)
        end
      end
    end

    context 'when user is admin with admin mode enabled', :enable_admin_mode do
      let_it_be(:admin_user) { create(:admin) }

      let(:service) do
        described_class.new(group: group, new_organization: new_organization, current_user: admin_user)
      end

      it 'allows transfer' do
        result = service.execute

        expect(result).to be_success
        expect(group.reload.organization_id).to eq(new_organization.id)
      end
    end

    context 'with nil new_organization' do
      let(:service) { described_class.new(group: group, new_organization: nil, current_user: user) }

      it 'returns error ServiceResponse' do
        result = service.execute

        expect(result).to be_error
        expect(result.reason).to eq(:missing_permission)
        expect(result.message).to eq(
          format(
            s_('TransferOrganization|Group organization transfer failed: %{error_message}'),
            error_message: s_('TransferOrganization|You must be an owner of both the group and new organization.')
          )
        )
      end

      it 'does not update organization_id' do
        original_organization_id = group.organization_id

        service.execute

        expect(group.reload.organization_id).to eq(original_organization_id)
      end
    end

    context 'when an exception occurs during transfer' do
      let_it_be_with_refind(:subgroup) { create(:group, parent: group, organization: old_organization) }
      let_it_be_with_refind(:nested_subgroup) { create(:group, parent: subgroup, organization: old_organization) }
      let_it_be_with_refind(:project) { create(:project, namespace: group, organization: old_organization) }
      let_it_be_with_refind(:subgroup_project) do
        create(:project, namespace: subgroup, organization: old_organization)
      end

      let_it_be_with_refind(:nested_project) do
        create(:project, namespace: nested_subgroup, organization: old_organization)
      end

      let(:error_message) { 'Transfer failed' }

      before do
        allow(ForkNetwork).to receive(:where).and_raise(StandardError, error_message)
      end

      it 'returns error ServiceResponse' do
        result = service.execute
        expect(result).to be_a(ServiceResponse)
        expect(result).to be_error
        expect(result.message).to eq(error_message)
      end

      it 'logs transfer error with correct payload' do
        expect(Gitlab::AppLogger).to receive(:error).with(
          hash_including(
            message: "Group was not transferred to a new organization",
            group_path: group.full_path,
            group_id: group.id,
            new_organization_path: new_organization.full_path,
            new_organization_id: new_organization.id,
            error_message: error_message
          )
        )

        service.execute
      end

      it_behaves_like 'rolls back organization_id updates' do
        let(:records) do
          [
            group, subgroup, nested_subgroup,
            project, subgroup_project, nested_project,
            project.project_namespace, subgroup_project.project_namespace, nested_project.project_namespace
          ]
        end
      end

      context "with runner records" do
        let_it_be(:ci_tag) { create(:ci_tag, name: "rollback-tag") }
        let_it_be_with_refind(:group_runner) do
          create(:ci_runner, :online, runner_type: :group_type, groups: [group])
        end

        let_it_be_with_refind(:group_runner_manager) do
          create(:ci_runner_machine, runner: group_runner)
        end

        let_it_be_with_refind(:group_runner_tagging) do
          create(:ci_runner_tagging, runner: group_runner, tag: ci_tag)
        end

        let_it_be_with_refind(:project_runner) do
          create(:ci_runner, :online, runner_type: :project_type, projects: [project])
        end

        let_it_be_with_refind(:project_runner_manager) do
          create(:ci_runner_machine, runner: project_runner)
        end

        let_it_be_with_refind(:project_runner_tagging) do
          create(:ci_runner_tagging, runner: project_runner, tag: ci_tag)
        end

        it_behaves_like "rolls back organization_id updates" do
          let(:records) do
            [
              group_runner, group_runner_manager, group_runner_tagging,
              project_runner, project_runner_manager, project_runner_tagging
            ]
          end
        end
      end

      context "with fork network records" do
        let_it_be_with_refind(:fork_network) do
          create(:fork_network, root_project: project)
        end

        it_behaves_like "rolls back organization_id updates" do
          let(:records) { [fork_network] }
        end
      end

      context "with visibility level changes that would have been made" do
        let_it_be(:new_organization) { create(:organization, visibility_level: Gitlab::VisibilityLevel::PRIVATE, owners: user) }
        let_it_be_with_refind(:public_subgroup) do
          create(:group, :public, parent: group, organization: old_organization)
        end

        let_it_be_with_refind(:public_project) do
          create(:project, :public, namespace: group, organization: old_organization)
        end

        it 'rolls back visibility level changes for groups due to transaction failure' do
          expect { service.execute }.not_to change { public_subgroup.reload.visibility_level }
        end

        it 'rolls back visibility level changes for projects due to transaction failure' do
          expect { service.execute }.not_to change { public_project.reload.visibility_level }
        end

        it 'rolls back visibility level changes for project namespaces due to transaction failure' do
          expect { service.execute }.not_to change { public_project.project_namespace.reload.visibility_level }
        end
      end

      it 'does not enqueue TransferOrganizationWorker' do
        expect(Ci::Runners::TransferOrganizationWorker).not_to receive(:perform_async)

        service.execute
      end

      it 'does not publish a GroupTransferredEvent' do
        expect { service.execute }.not_to publish_event(Organizations::GroupTransferredEvent)
      end
    end

    context 'when transferring fork networks' do
      let_it_be_with_refind(:project_with_fork_network) do
        create(:project, namespace: group, organization: old_organization)
      end

      let_it_be_with_refind(:fork_network) do
        create(:fork_network, root_project: project_with_fork_network)
      end

      it 'updates fork_network organization_id when root_project is in transferred group' do
        expect { service.execute }.to change { fork_network.reload.organization_id }
          .from(old_organization.id).to(new_organization.id)
      end

      it 'keeps fork_network valid after transfer' do
        service.execute

        expect(fork_network.reload).to be_valid
      end

      context 'when fork network root_project is in a subgroup' do
        let_it_be_with_refind(:subgroup) { create(:group, parent: group, organization: old_organization) }
        let_it_be_with_refind(:subgroup_project) do
          create(:project, namespace: subgroup, organization: old_organization)
        end

        let_it_be_with_refind(:subgroup_fork_network) do
          create(:fork_network, root_project: subgroup_project)
        end

        it 'updates fork_network organization_id for projects in subgroups' do
          expect { service.execute }.to change { subgroup_fork_network.reload.organization_id }
            .from(old_organization.id).to(new_organization.id)
        end
      end

      context 'when fork network root_project is NOT in the transferred group' do
        let_it_be(:other_group) { create(:group, organization: old_organization) }
        let_it_be_with_refind(:other_project) do
          create(:project, namespace: other_group, organization: old_organization)
        end

        let_it_be_with_refind(:other_fork_network) do
          create(:fork_network, root_project: other_project)
        end

        it 'does not update fork_network organization_id' do
          expect { service.execute }.not_to change { other_fork_network.reload.organization_id }
        end
      end

      context 'when no projects have fork networks' do
        let_it_be_with_refind(:project_without_fork_network) do
          create(:project, namespace: group, organization: old_organization)
        end

        before do
          ForkNetwork.delete_all
        end

        it 'completes transfer successfully' do
          expect { service.execute }.not_to raise_error
          expect(group.reload.organization_id).to eq(new_organization.id)
          expect(project_without_fork_network.reload.organization_id).to eq(new_organization.id)
        end
      end
    end

    context 'when disconnecting from gitaly' do
      let_it_be_with_reload(:project) do
        create(:project, :small_repo, namespace: group, organization: old_organization)
      end

      context 'when linked to pool repository' do
        let_it_be_with_reload(:pool_repository) do
          create(:pool_repository, :ready, source_project: project)
        end

        it 'enqueues Repositories::LeavePoolRepositoryWorker' do
          expect { service.execute }.to change { Repositories::LeavePoolRepositoryWorker.jobs.size }.by(1)
        end
      end

      context 'when not linked to pool repository' do
        before do
          project.update!(pool_repository: nil)
        end

        it 'does not enqueue Repositories::LeavePoolRepositoryWorker' do
          service.execute
          expect(Repositories::LeavePoolRepositoryWorker.jobs.size).to eq(0)
        end
      end
    end
  end

  describe '#async_execute' do
    context 'when transfer is allowed' do
      it 'enqueues the transfer worker' do
        expect(Organizations::Groups::TransferWorker).to receive(:perform_async).with(
          {
            'group_id' => group.id,
            'organization_id' => new_organization.id,
            'current_user_id' => user.id
          }
        )

        result = service.async_execute

        expect(result).to be_success
        expect(result.message).to include('initiated')
      end
    end

    context 'when group is not root' do
      let_it_be(:parent_group) { create(:group, organization: old_organization) }
      let_it_be(:subgroup_user) { create(:user, organization: old_organization) }
      let_it_be_with_refind(:subgroup) do
        create(:group, parent: parent_group, organization: old_organization, developers: subgroup_user)
      end

      let(:service) { described_class.new(group: subgroup, new_organization: new_organization, current_user: user) }

      it 'returns error ServiceResponse' do
        result = service.async_execute

        expect(result).to be_error
        expect(result.reason).to eq(:group_not_root)
        expect(result.message).to eq(
          format(
            s_('TransferOrganization|Group organization transfer failed: %{error_message}'),
            error_message:
              s_('TransferOrganization|Only top-level groups can be transferred to a different organization.')
          )
        )
      end

      it 'does not enqueue the worker' do
        expect(Organizations::Groups::TransferWorker).not_to receive(:perform_async)

        service.async_execute
      end
    end

    context 'when user lacks permissions' do
      let_it_be(:non_owner_user) { create(:user, organization: old_organization) }
      let(:service) do
        described_class.new(group: group, new_organization: new_organization, current_user: non_owner_user)
      end

      it 'returns error ServiceResponse' do
        result = service.async_execute

        expect(result).to be_error
        expect(result.reason).to eq(:missing_permission)
        expect(result.message).to eq(
          format(
            s_('TransferOrganization|Group organization transfer failed: %{error_message}'),
            error_message: s_('TransferOrganization|You must be an owner of both the group and new organization.')
          )
        )
      end

      it 'does not enqueue the worker' do
        expect(Organizations::Groups::TransferWorker).not_to receive(:perform_async)

        service.async_execute
      end
    end
  end
end
