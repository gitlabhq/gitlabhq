# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::Users::TransferService, :with_current_organization, feature_category: :organization do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:old_organization) { current_organization }
  let_it_be(:new_organization) { create(:organization) }
  let_it_be_with_refind(:group) { create(:group, organization: old_organization) }

  let(:service) { described_class.new(group: group, new_organization: new_organization, current_user: current_user) }

  before_all do
    group.add_owner(current_user)
  end

  describe '#execute' do
    context 'when transfer is successful' do
      let_it_be_with_refind(:user1) { create(:user, organization: old_organization) }
      let_it_be_with_refind(:user2) { create(:user, organization: old_organization) }
      let_it_be_with_refind(:user3) { create(:user, organization: old_organization) }
      let_it_be_with_refind(:user_namespace1) { create(:namespace, owner: user1, organization: old_organization) }
      let_it_be_with_refind(:user_namespace2) { create(:namespace, owner: user2, organization: old_organization) }
      let_it_be_with_refind(:project1) { create(:project, namespace: user_namespace1, organization: old_organization) }
      let_it_be_with_refind(:project2) { create(:project, namespace: user_namespace2, organization: old_organization) }

      before_all do
        group.add_maintainer(user1)
        group.add_developer(user2)
        group.add_guest(user3)
      end

      it 'returns success ServiceResponse' do
        result = service.execute
        expect(result).to be_a(ServiceResponse)
        expect(result).to be_success
      end

      it 'executes within a database transaction when called standalone' do
        allow(User.connection).to receive(:transaction_open?).and_return(false)

        expect(User).to receive(:transaction).and_call_original

        service.execute
      end

      it 'updates organization_id for users in the group' do
        service.execute

        expect(user1.reload.organization_id).to eq(new_organization.id)
        expect(user2.reload.organization_id).to eq(new_organization.id)
        expect(user3.reload.organization_id).to eq(new_organization.id)
      end

      it 'updates organization_id for user namespaces' do
        service.execute

        expect(user_namespace1.reload.organization_id).to eq(new_organization.id)
        expect(user_namespace2.reload.organization_id).to eq(new_organization.id)
      end

      it 'updates organization_id for projects and project namespaces' do
        service.execute

        expect(project1.reload.organization_id).to eq(new_organization.id)
        expect(project2.reload.organization_id).to eq(new_organization.id)
        expect(project1.project_namespace.reload.organization_id).to eq(new_organization.id)
        expect(project2.project_namespace.reload.organization_id).to eq(new_organization.id)
      end

      describe 'visibility level updates' do
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

          let_it_be_with_refind(:public_project) do
            create(:project, :public, namespace: public_user_namespace, organization: old_organization)
          end

          let_it_be_with_refind(:internal_project) do
            create(:project, :internal, namespace: internal_user_namespace, organization: old_organization)
          end

          let_it_be_with_refind(:private_project) do
            create(:project, :private, namespace: private_user_namespace, organization: old_organization)
          end

          it 'updates visibility for user namespaces with higher visibility than organization' do
            service.execute

            expect(public_user_namespace.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(internal_user_namespace.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
          end

          it 'does not update visibility for user namespaces with lower or equal visibility' do
            service.execute

            expect(private_user_namespace.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
          end

          it 'updates visibility for projects with higher visibility than organization' do
            service.execute

            expect(public_project.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(internal_project.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
          end

          it 'updates visibility for project namespaces with higher visibility' do
            service.execute

            expect(public_project.project_namespace.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(internal_project.project_namespace.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
          end

          it 'does not update visibility for projects with lower or equal visibility' do
            service.execute

            expect(private_project.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
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

          let_it_be_with_refind(:private_project) do
            create(:project,
              visibility_level: Gitlab::VisibilityLevel::PRIVATE,
              namespace: private_user_namespace,
              organization: old_organization)
          end

          it 'does not update visibility for user namespaces with lower visibility' do
            service.execute

            expect(private_user_namespace.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
            expect(internal_user_namespace.reload.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
          end

          it 'does not update visibility for projects with lower visibility' do
            service.execute

            expect(private_project.reload.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
          end
        end
      end

      describe 'transaction error handling' do
        context 'when an outer transaction is already open and error occurs' do
          before do
            allow(User.connection).to receive(:transaction_open?).and_return(true)
          end

          it 're-raises errors' do
            allow(service).to receive(:update_users).with(any_args)
                                                    .and_raise(ActiveRecord::RecordNotUnique, 'Database error')

            expect { service.execute }.to raise_error(StandardError, 'Database error')
          end
        end

        context 'when no outer transaction is open and an error occurs' do
          before do
            allow(User.connection).to receive(:transaction_open?).and_return(false)
          end

          it 'rescues errors' do
            allow(service).to receive(:update_users).with(any_args)
                                                    .and_raise(ActiveRecord::RecordNotUnique, 'Database error')

            result = service.execute

            expect(result).to be_error
            expect(result.message).to eq('Database error')
          end
        end
      end
    end

    context 'when transfer validation fails' do
      let_it_be_with_refind(:user1) { create(:user, organization: create(:organization)) }

      before_all do
        group.add_maintainer(user1)
      end

      it 'returns error ServiceResponse' do
        result = service.execute
        expect(result).to be_a(ServiceResponse)
        expect(result).to be_error
      end

      it 'sets error message' do
        result = service.execute

        expected_message = s_("TransferOrganization|Cannot transfer users to a different organization " \
          "if all users do not belong to the same organization as the top-level group.")
        expect(result.message).to eq(expected_message)
        expect(service.can_transfer_error).to eq(expected_message)
      end

      it 'does not update organization_id for users' do
        original_organization_id = user1.organization_id

        service.execute

        expect(user1.reload.organization_id).to eq(original_organization_id)
      end
    end
  end

  describe '#can_transfer?' do
    context 'when all users belong to the same organization as the group' do
      let_it_be(:user1) { create(:user, organization: old_organization) }
      let_it_be(:user2) { create(:user, organization: old_organization) }

      before_all do
        group.add_maintainer(user1)
        group.add_developer(user2)
      end

      it 'returns true' do
        expect(service.can_transfer?).to be true
      end
    end

    context 'when some users belong to different organizations' do
      let_it_be(:user1) { create(:user, organization: old_organization) }
      let_it_be(:user2) { create(:user, organization: create(:organization)) }

      before_all do
        group.add_maintainer(user1)
        group.add_developer(user2)
      end

      it 'returns false' do
        expect(service.can_transfer?).to be false
      end
    end

    context 'when group has no users besides owners' do
      let_it_be_with_refind(:empty_group) { create(:group, organization: old_organization) }
      let(:empty_service) do
        described_class.new(group: empty_group, new_organization: new_organization, current_user: current_user)
      end

      it 'returns false' do
        expect(empty_service.can_transfer?).to be false
      end
    end
  end

  describe '#error' do
    context 'when transfer is possible' do
      let_it_be(:user1) { create(:user, organization: old_organization) }

      before_all do
        group.add_maintainer(user1)
      end

      it 'returns nil' do
        expect(service.can_transfer_error).to be_nil
      end
    end

    context 'when transfer is not possible' do
      let_it_be(:user1) { create(:user, organization: create(:organization)) }

      before_all do
        group.add_maintainer(user1)
      end

      it 'returns error message' do
        expected_message = s_("TransferOrganization|Cannot transfer users to a different organization " \
          "if all users do not belong to the same organization as the top-level group.")
        expect(service.can_transfer_error).to eq(expected_message)
      end
    end
  end
end
