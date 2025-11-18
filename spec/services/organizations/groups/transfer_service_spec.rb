# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::Groups::TransferService, :aggregate_failures, feature_category: :organization do
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
          let_it_be(:new_organization) { create(:organization, visibility_level: Gitlab::VisibilityLevel::PRIVATE) }
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

          before_all do
            new_organization.add_owner(user)
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
          let_it_be(:new_organization) { create(:organization, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }
          let_it_be_with_refind(:private_subgroup) do
            create(:group, :private, parent: group, organization: old_organization)
          end

          let_it_be_with_refind(:internal_subgroup) do
            create(:group, :internal, parent: group, organization: old_organization)
          end

          let_it_be_with_refind(:private_project) do
            create(:project, :private, namespace: group, organization: old_organization)
          end

          before_all do
            new_organization.add_owner(user)
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

        context 'when new organization has same visibility as groups/projects' do
          let_it_be(:new_organization) { create(:organization, visibility_level: Gitlab::VisibilityLevel::INTERNAL) }
          let_it_be_with_refind(:internal_subgroup) do
            create(:group, :internal, parent: group, organization: old_organization)
          end

          let_it_be_with_refind(:internal_project) do
            create(:project, :internal, namespace: group, organization: old_organization)
          end

          it 'does not update visibility for groups with equal visibility' do
            service.execute

            expect(internal_subgroup.reload.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
            expect(internal_subgroup).to be_valid
          end

          it 'does not update visibility for projects with equal visibility' do
            service.execute

            expect(internal_project.reload.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
            expect(internal_project).to be_valid
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

      it 'updates users successfully' do
        service.execute

        expect(user.reload.organization_id).to eq(new_organization.id)
        expect(user).to be_valid
      end

      context 'with todos authored by bots' do
        let_it_be_with_refind(:user1) { create(:user, organization: old_organization) }
        let_it_be_with_refind(:user2) { create(:user, organization: old_organization) }
        let_it_be_with_refind(:support_bot_old) { Users::Internal.for_organization(old_organization).support_bot }
        let_it_be_with_refind(:human_author) { create(:user, organization: old_organization) }
        let_it_be_with_refind(:issue) { create(:issue, project: project) }

        let_it_be_with_refind(:human_authored_todo) do
          create(:todo, user: user1, author: human_author, target: issue, project: project)
        end

        before_all do
          group.add_developer(user1)
          group.add_developer(user2)
        end

        it 'updates all bot-authored todos to use new organization bots' do
          # Create todos for all bot types
          ghost_old = Users::Internal.for_organization(old_organization).ghost
          alert_bot_old = Users::Internal.for_organization(old_organization).alert_bot
          migration_bot_old = Users::Internal.for_organization(old_organization).migration_bot
          security_bot_old = Users::Internal.for_organization(old_organization).security_bot
          automation_bot_old = Users::Internal.for_organization(old_organization).automation_bot
          admin_bot_old = Users::Internal.for_organization(old_organization).admin_bot
          duo_code_review_bot_old = Users::Internal.for_organization(old_organization).duo_code_review_bot

          ghost_todo = create(:todo, user: user1, author: ghost_old, target: issue, project: project)
          support_bot_todo = create(:todo, user: user1, author: support_bot_old, target: issue, project: project)
          alert_bot_todo = create(:todo, user: user1, author: alert_bot_old, target: issue, project: project)
          migration_bot_todo = create(:todo, user: user2, author: migration_bot_old, target: issue, project: project)
          security_bot_todo = create(:todo, user: user2, author: security_bot_old, target: issue, project: project)
          automation_bot_todo = create(:todo, user: user1, author: automation_bot_old, target: issue, project: project)
          admin_bot_todo = create(:todo, user: user1, author: admin_bot_old, target: issue, project: project)
          duo_code_review_bot_todo =
            create(:todo, user: user2, author: duo_code_review_bot_old, target: issue, project: project)

          service.execute

          ghost_new = Users::Internal.for_organization(new_organization).ghost
          support_bot_new = Users::Internal.for_organization(new_organization).support_bot
          alert_bot_new = Users::Internal.for_organization(new_organization).alert_bot
          migration_bot_new = Users::Internal.for_organization(new_organization).migration_bot
          security_bot_new = Users::Internal.for_organization(new_organization).security_bot
          automation_bot_new = Users::Internal.for_organization(new_organization).automation_bot
          admin_bot_new = Users::Internal.for_organization(new_organization).admin_bot
          duo_code_review_bot_new = Users::Internal.for_organization(new_organization).duo_code_review_bot

          expect(ghost_todo.reload.author_id).to eq(ghost_new.id)
          expect(support_bot_todo.reload.author_id).to eq(support_bot_new.id)
          expect(alert_bot_todo.reload.author_id).to eq(alert_bot_new.id)
          expect(migration_bot_todo.reload.author_id).to eq(migration_bot_new.id)
          expect(security_bot_todo.reload.author_id).to eq(security_bot_new.id)
          expect(automation_bot_todo.reload.author_id).to eq(automation_bot_new.id)
          expect(admin_bot_todo.reload.author_id).to eq(admin_bot_new.id)
          expect(duo_code_review_bot_todo.reload.author_id).to eq(duo_code_review_bot_new.id)

          expect(ghost_todo).to be_valid
          expect(support_bot_todo).to be_valid
          expect(alert_bot_todo).to be_valid
          expect(migration_bot_todo).to be_valid
          expect(security_bot_todo).to be_valid
          expect(automation_bot_todo).to be_valid
          expect(admin_bot_todo).to be_valid
          expect(duo_code_review_bot_todo).to be_valid
        end

        it 'does not update human-authored todos' do
          expect { service.execute }.not_to change { human_authored_todo.reload.author_id }
        end

        it 'does not update todos for users not in the transferred group' do
          non_group_user = create(:user, organization: old_organization)
          non_group_todo = create(:todo, user: non_group_user, author: support_bot_old, target: issue, project: project)

          expect { service.execute }.not_to change { non_group_todo.reload.author_id }
        end
      end

      context 'with user transfers' do
        let_it_be_with_refind(:user1) { create(:user, organization: old_organization) }
        let_it_be_with_refind(:user2) { create(:user, organization: old_organization) }
        let_it_be_with_refind(:user3) { create(:user, organization: old_organization) }
        let_it_be_with_refind(:user_namespace1) { create(:namespace, owner: user1, organization: old_organization) }
        let_it_be_with_refind(:user_namespace2) { create(:namespace, owner: user2, organization: old_organization) }
        let_it_be_with_refind(:user_project1) do
          create(:project, namespace: user_namespace1, organization: old_organization)
        end

        let_it_be_with_refind(:user_project2) do
          create(:project, namespace: user_namespace2, organization: old_organization)
        end

        before_all do
          group.add_maintainer(user1)
          group.add_developer(user2)
          group.add_guest(user3)
        end

        it 'updates organization_id for users in the group' do
          service.execute

          expect(user1.reload.organization_id).to eq(new_organization.id)
          expect(user2.reload.organization_id).to eq(new_organization.id)
          expect(user3.reload.organization_id).to eq(new_organization.id)

          expect(user1).to be_valid
          expect(user2).to be_valid
          expect(user3).to be_valid
        end

        it 'updates organization_id for user namespaces' do
          service.execute

          expect(user_namespace1.reload.organization_id).to eq(new_organization.id)
          expect(user_namespace2.reload.organization_id).to eq(new_organization.id)

          expect(user_namespace1).to be_valid
          expect(user_namespace2).to be_valid
        end

        it 'updates organization_id for projects and project namespaces under user namespaces' do
          service.execute

          expect(user_project1.reload.organization_id).to eq(new_organization.id)
          expect(user_project2.reload.organization_id).to eq(new_organization.id)
          expect(user_project1.project_namespace.reload.organization_id).to eq(new_organization.id)
          expect(user_project2.project_namespace.reload.organization_id).to eq(new_organization.id)

          expect(user_project1).to be_valid
          expect(user_project2).to be_valid
          expect(user_project1.project_namespace).to be_valid
          expect(user_project2.project_namespace).to be_valid
        end

        context 'when new organization has lower visibility than some user namespaces/projects' do
          let_it_be(:new_organization) { create(:organization, visibility_level: Gitlab::VisibilityLevel::PRIVATE) }
          let_it_be_with_refind(:public_user_namespace) do
            create(:namespace,
              visibility_level: Gitlab::VisibilityLevel::PUBLIC, owner: user1, organization: old_organization)
          end

          let_it_be_with_refind(:internal_user_namespace) do
            create(:namespace,
              visibility_level: Gitlab::VisibilityLevel::INTERNAL, owner: user2, organization: old_organization)
          end

          let_it_be_with_refind(:private_user_namespace) do
            create(:namespace,
              visibility_level: Gitlab::VisibilityLevel::PRIVATE, owner: user3, organization: old_organization)
          end

          let_it_be_with_refind(:public_user_project) do
            create(:project, :public, namespace: public_user_namespace, organization: old_organization)
          end

          let_it_be_with_refind(:internal_user_project) do
            create(:project, :internal, namespace: internal_user_namespace, organization: old_organization)
          end

          let_it_be_with_refind(:private_user_project) do
            create(:project, :private, namespace: private_user_namespace, organization: old_organization)
          end

          before_all do
            new_organization.add_owner(user)
          end

          it 'updates visibility for user namespaces with higher visibility than organization' do
            service.execute

            expect(public_user_namespace.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(internal_user_namespace.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)

            expect(public_user_namespace).to be_valid
            expect(internal_user_namespace).to be_valid
          end

          it 'does not update visibility for user namespaces with lower or equal visibility' do
            service.execute

            expect(private_user_namespace.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(private_user_namespace).to be_valid
          end

          it 'updates visibility for projects under user namespaces with higher visibility than organization' do
            service.execute

            expect(public_user_project.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(internal_user_project.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)

            expect(public_user_project).to be_valid
            expect(internal_user_project).to be_valid
          end

          it 'updates visibility for project namespaces under user namespaces with higher visibility' do
            service.execute

            expect(public_user_project.project_namespace.reload.visibility_level)
              .to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(internal_user_project.project_namespace.reload.visibility_level)
              .to eq(Gitlab::VisibilityLevel::PRIVATE)

            expect(public_user_project.project_namespace).to be_valid
            expect(internal_user_project.project_namespace).to be_valid
          end

          it 'does not update visibility for projects under user namespaces with lower or equal visibility' do
            service.execute

            expect(private_user_project.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(private_user_project).to be_valid
          end
        end

        context 'when new organization has higher visibility than some user namespaces/projects' do
          let_it_be(:new_organization) { create(:organization, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }
          let_it_be_with_refind(:private_user_namespace) do
            create(:namespace,
              visibility_level: Gitlab::VisibilityLevel::PRIVATE, owner: user1, organization: old_organization)
          end

          let_it_be_with_refind(:internal_user_namespace) do
            create(:namespace,
              visibility_level: Gitlab::VisibilityLevel::INTERNAL, owner: user2, organization: old_organization)
          end

          let_it_be_with_refind(:private_user_project) do
            create(:project,
              visibility_level: Gitlab::VisibilityLevel::PRIVATE,
              namespace: private_user_namespace,
              organization: old_organization)
          end

          before_all do
            new_organization.add_owner(user)
          end

          it 'does not update visibility for user namespaces with lower visibility' do
            service.execute

            expect(private_user_namespace.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(internal_user_namespace.reload.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)

            expect(private_user_namespace).to be_valid
            expect(internal_user_namespace).to be_valid
          end

          it 'does not update visibility for projects under user namespaces with lower visibility' do
            service.execute

            expect(private_user_project.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(private_user_project).to be_valid
          end
        end
      end
    end

    context 'when transfer validation fails' do
      let(:validator_error) { "Transfer not allowed" }

      before do
        allow_next_instance_of(Organizations::Groups::TransferValidator) do |validator|
          allow(validator).to receive_messages(can_transfer?: false, error_message: validator_error)
        end
      end

      it 'returns error ServiceResponse' do
        result = service.execute
        expect(result).to be_a(ServiceResponse)
        expect(result).to be_error
      end

      it 'sets formatted error message' do
        result = service.execute

        expect(result.message).to eq("Group organization transfer failed: #{validator_error}")
      end

      it 'does not update organization_id' do
        original_organization_id = group.organization_id

        service.execute

        expect(group.reload.organization_id).to eq(original_organization_id)
      end

      it 'does not update organization_id for projects' do
        project = create(:project, namespace: group, organization: old_organization)
        original_organization_id = project.organization_id

        service.execute

        expect(project.reload.organization_id).to eq(original_organization_id)
      end
    end

    context 'when user transfer service validation fails' do
      let(:error) { "User transfer not allowed" }

      before do
        allow_next_instance_of(Organizations::Groups::TransferValidator) do |validator|
          allow(validator).to receive_messages(can_transfer_users?: false, cannot_transfer_users_error: error)
        end
      end

      it 'returns error ServiceResponse' do
        result = service.execute
        expect(result).to be_a(ServiceResponse)
        expect(result).to be_error
      end

      it 'sets formatted error message' do
        result = service.execute

        expect(result.message).to eq("Group organization transfer failed: #{error}")
      end
    end

    context 'when user transfer service raises an exception within User.transaction' do
      let_it_be_with_refind(:subgroup) { create(:group, parent: group, organization: old_organization) }
      let_it_be_with_refind(:nested_subgroup) { create(:group, parent: subgroup, organization: old_organization) }
      let_it_be_with_refind(:project) { create(:project, namespace: group, organization: old_organization) }
      let_it_be_with_refind(:subgroup_project) do
        create(:project, namespace: subgroup, organization: old_organization)
      end

      let_it_be_with_refind(:nested_project) do
        create(:project, namespace: nested_subgroup, organization: old_organization)
      end

      let(:error_message) { 'User transfer failed' }

      before do
        allow_next_instance_of(described_class) do |group_service|
          allow(group_service).to receive(:transfer_users).and_raise(ActiveRecord::RecordNotUnique, error_message)
        end
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

      it 'rolls back all organization ID changes due to transaction failure' do
        service.execute

        expect(group.reload.organization_id).to eq(old_organization.id)
        expect(subgroup.reload.organization_id).to eq(old_organization.id)
        expect(nested_subgroup.reload.organization_id).to eq(old_organization.id)

        expect(project.reload.organization_id).to eq(old_organization.id)
        expect(subgroup_project.reload.organization_id).to eq(old_organization.id)
        expect(nested_project.reload.organization_id).to eq(old_organization.id)

        expect(project.project_namespace.reload.organization_id).to eq(old_organization.id)
        expect(subgroup_project.project_namespace.reload.organization_id).to eq(old_organization.id)
        expect(nested_project.project_namespace.reload.organization_id).to eq(old_organization.id)
      end

      context 'with visibility level changes that would have been made' do
        let_it_be(:new_organization) { create(:organization, visibility_level: Gitlab::VisibilityLevel::PRIVATE) }
        let_it_be_with_refind(:public_subgroup) do
          create(:group, :public, parent: group, organization: old_organization)
        end

        let_it_be_with_refind(:public_project) do
          create(:project, :public, namespace: group, organization: old_organization)
        end

        before_all do
          new_organization.add_owner(user)
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

      it 'does not update user organization due to transaction failure' do
        expect { service.execute }.not_to change { user.reload.organization_id }
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

    context 'when transfer validation fails' do
      let(:validator_error) { "Transfer not allowed" }

      before do
        allow_next_instance_of(Organizations::Groups::TransferValidator) do |validator|
          allow(validator).to receive_messages(can_transfer?: false, error_message: validator_error)
        end
      end

      it 'returns error ServiceResponse' do
        result = service.async_execute

        expect(result).to be_error
        expect(result.message).to eq("Group organization transfer failed: #{validator_error}")
      end

      it 'does not enqueue the worker' do
        expect(Organizations::Groups::TransferWorker).not_to receive(:perform_async)

        service.async_execute
      end
    end
  end
end
