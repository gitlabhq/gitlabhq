# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::Users::TransferService, :aggregate_failures, feature_category: :organization do
  let_it_be(:old_organization) { create(:organization) }
  let_it_be(:new_organization) { create(:organization) }
  let_it_be_with_refind(:group) { create(:group, organization: old_organization) }

  let(:users) { group.users_with_descendants }
  let(:service) { described_class.new(users: users, new_organization: new_organization) }

  describe '#execute' do
    context 'when users belong to different organizations' do
      let_it_be(:other_organization) { create(:organization) }
      let_it_be_with_refind(:user1) { create(:user, organization: old_organization) }
      let_it_be_with_refind(:user2) { create(:user, organization: other_organization) }

      let(:users) { User.id_in([user1.id, user2.id]) }

      before_all do
        group.add_maintainer(user1)
        group.add_developer(user2)
      end

      it 'returns error ServiceResponse with appropriate message' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq(
          s_("TransferOrganization|Cannot transfer users to a different organization " \
            "if all users do not belong to the same organization as the top-level group.")
        )
      end

      it 'does not update user organization_id' do
        expect { service.execute }.not_to change { user1.reload.organization_id }
        expect { service.execute }.not_to change { user2.reload.organization_id }
      end
    end

    context 'when old organization does not exist' do
      let_it_be_with_refind(:user1) { create(:user, organization: old_organization) }

      before_all do
        group.add_maintainer(user1)
      end

      before do
        allow(Organizations::Organization).to receive(:find_by_id).and_return(nil)
      end

      it 'returns error ServiceResponse with appropriate message' do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq(
          s_("TransferOrganization|Cannot transfer users because the existing organization could not be found.")
        )
      end

      it 'does not update user organization_id' do
        expect { service.execute }.not_to change { user1.reload.organization_id }
      end
    end

    context 'when called within an existing transaction (outer transaction)' do
      let_it_be_with_refind(:user1) { create(:user, organization: old_organization) }

      before_all do
        group.add_developer(user1)
      end

      it 'detects the existing transaction and does not create a nested one' do
        # RSpec tests run inside a transaction, so transaction_open? returns true
        expect(User.connection.transaction_open?).to be true
        expect(User).not_to receive(:transaction)

        service.execute
      end

      it 'returns success ServiceResponse' do
        result = service.execute

        expect(result).to be_a(ServiceResponse)
        expect(result).to be_success
      end

      context 'when an error occurs' do
        before do
          allow(service).to receive(:perform_transfer).and_raise(StandardError, 'Transfer failed')
        end

        it 're-raises the exception to allow outer transaction to roll back' do
          expect { service.execute }.to raise_error(StandardError, 'Transfer failed')
        end

        it 'does not return an error ServiceResponse' do
          # The exception should be raised, not caught and converted to ServiceResponse
          expect(service.execute).not_to be_a(ServiceResponse)
        rescue StandardError
          # Expected to raise
        end
      end

      context 'when ActiveRecord::Rollback is raised' do
        before do
          allow(service).to receive(:perform_transfer).and_raise(ActiveRecord::Rollback)
        end

        it 're-raises the rollback to propagate to outer transaction' do
          expect { service.execute }.to raise_error(ActiveRecord::Rollback)
        end
      end
    end

    context 'when managing its own transaction' do
      let_it_be_with_refind(:user1) { create(:user, organization: old_organization) }

      before_all do
        group.add_developer(user1)
      end

      before do
        # Simulate being outside a transaction by stubbing transaction_open?
        allow(User.connection).to receive(:transaction_open?).and_return(false)
      end

      it 'creates its own transaction' do
        expect(User).to receive(:transaction).and_call_original

        service.execute
      end

      context 'when an error occurs' do
        before do
          allow(service).to receive(:perform_transfer).and_raise(StandardError, 'Transfer failed')
        end

        it 'does not re-raise the exception' do
          expect { service.execute }.not_to raise_error
        end

        it 'returns an error ServiceResponse' do
          result = service.execute

          expect(result).to be_a(ServiceResponse)
          expect(result).to be_error
          expect(result.message).to eq('Transfer failed')
        end
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

    context 'with todos authored by bots' do
      let_it_be_with_refind(:user1) { create(:user, organization: old_organization) }
      let_it_be_with_refind(:user2) { create(:user, organization: old_organization) }
      let_it_be_with_refind(:support_bot_old) { Users::Internal.for_organization(old_organization).support_bot }
      let_it_be_with_refind(:human_author) { create(:user, organization: old_organization) }
      let_it_be_with_refind(:project) { create(:project, namespace: group, organization: old_organization) }
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
        security_bot_old = Users::Internal.for_organization(old_organization).security_bot
        automation_bot_old = Users::Internal.for_organization(old_organization).automation_bot
        admin_bot_old = Users::Internal.for_organization(old_organization).admin_bot
        duo_code_review_bot_old = Users::Internal.for_organization(old_organization).duo_code_review_bot

        ghost_todo = create(:todo, user: user1, author: ghost_old, target: issue, project: project)
        support_bot_todo = create(:todo, user: user1, author: support_bot_old, target: issue, project: project)
        alert_bot_todo = create(:todo, user: user1, author: alert_bot_old, target: issue, project: project)
        security_bot_todo = create(:todo, user: user2, author: security_bot_old, target: issue, project: project)
        automation_bot_todo = create(:todo, user: user1, author: automation_bot_old, target: issue, project: project)
        admin_bot_todo = create(:todo, user: user1, author: admin_bot_old, target: issue, project: project)
        duo_code_review_bot_todo =
          create(:todo, user: user2, author: duo_code_review_bot_old, target: issue, project: project)

        # Pre-create the new organization bots before the transfer
        service.prepare_bots

        # Get references to the new bots that were just created
        ghost_new = Users::Internal.for_organization(new_organization).ghost
        support_bot_new = Users::Internal.for_organization(new_organization).support_bot
        alert_bot_new = Users::Internal.for_organization(new_organization).alert_bot
        security_bot_new = Users::Internal.for_organization(new_organization).security_bot
        automation_bot_new = Users::Internal.for_organization(new_organization).automation_bot
        admin_bot_new = Users::Internal.for_organization(new_organization).admin_bot
        duo_code_review_bot_new = Users::Internal.for_organization(new_organization).duo_code_review_bot

        service.execute

        expect(ghost_todo.reload.author_id).to eq(ghost_new.id)
        expect(support_bot_todo.reload.author_id).to eq(support_bot_new.id)
        expect(alert_bot_todo.reload.author_id).to eq(alert_bot_new.id)
        expect(security_bot_todo.reload.author_id).to eq(security_bot_new.id)
        expect(automation_bot_todo.reload.author_id).to eq(automation_bot_new.id)
        expect(admin_bot_todo.reload.author_id).to eq(admin_bot_new.id)
        expect(duo_code_review_bot_todo.reload.author_id).to eq(duo_code_review_bot_new.id)

        expect(ghost_todo).to be_valid
        expect(support_bot_todo).to be_valid
        expect(alert_bot_todo).to be_valid
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

    context 'with nested groups' do
      let_it_be_with_refind(:subgroup) { create(:group, parent: group, organization: old_organization) }
      let_it_be_with_refind(:nested_subgroup) { create(:group, parent: subgroup, organization: old_organization) }
      let_it_be_with_refind(:user1) { create(:user, organization: old_organization) }
      let_it_be_with_refind(:user2) { create(:user, organization: old_organization) }
      let_it_be_with_refind(:user3) { create(:user, organization: old_organization) }

      before_all do
        group.add_maintainer(user1)
        subgroup.add_developer(user2)
        nested_subgroup.add_guest(user3)
      end

      it 'updates all users from the group hierarchy' do
        service.execute

        expect(user1.reload.organization_id).to eq(new_organization.id)
        expect(user2.reload.organization_id).to eq(new_organization.id)
        expect(user3.reload.organization_id).to eq(new_organization.id)
      end
    end
  end

  describe '#can_transfer_users?' do
    context 'when all users belong to the same organization as the group' do
      let_it_be_with_refind(:user1) { create(:user, organization: old_organization) }
      let_it_be_with_refind(:user2) { create(:user, organization: old_organization) }

      before_all do
        group.add_maintainer(user1)
        group.add_developer(user2)
      end

      it 'returns true' do
        expect(service.can_transfer_users?).to be true
      end
    end

    context 'when some users belong to different organizations' do
      let_it_be(:other_organization) { create(:organization) }
      let_it_be_with_refind(:user1) { create(:user, organization: old_organization) }
      let_it_be_with_refind(:user2) { create(:user, organization: other_organization) }

      # Override users to include both users even though they belong to different organizations
      let(:users) { User.where(id: [user1.id, user2.id]) }

      before_all do
        group.add_maintainer(user1)
        group.add_developer(user2)
      end

      it 'returns false' do
        expect(service.can_transfer_users?).to be false
      end
    end

    context 'when old organization does not exist' do
      let_it_be_with_refind(:user1) { create(:user, organization: old_organization) }

      before_all do
        group.add_maintainer(user1)
      end

      before do
        allow(Organizations::Organization).to receive(:find_by_id).and_return(nil)
      end

      it 'returns false' do
        expect(service.can_transfer_users?).to be false
      end
    end

    context 'with nested groups' do
      let_it_be_with_refind(:subgroup) { create(:group, parent: group, organization: old_organization) }
      let_it_be(:other_organization) { create(:organization) }
      let_it_be_with_refind(:user1) { create(:user, organization: old_organization) }
      let_it_be_with_refind(:user2) { create(:user, organization: other_organization) }

      let(:users) { User.where(id: [user1.id, user2.id]) }

      before_all do
        group.add_maintainer(user1)
        subgroup.add_developer(user2)
      end

      it 'checks users across the entire group hierarchy' do
        expect(service.can_transfer_users?).to be false
      end
    end
  end
end
