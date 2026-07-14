# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::ActivateService, feature_category: :organization do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:organization) { create(:organization, :confirmed, owners: user) }
  let_it_be(:top_level_group) { create(:group, organization: organization, owners: user) }
  let_it_be(:other_top_level_group) { create(:group, organization: organization, owners: user) }

  let(:current_user) { user }
  let(:organization_id) { organization.id }
  let(:params) { { organization_id: organization_id } }

  subject(:response) { described_class.new(current_user, params).execute }

  describe '#execute' do
    context 'when all validations pass' do
      before do
        allow_next_instance_of(Organizations::Transfer::GroupsService) do |service|
          allow(service).to receive(:execute).and_return(ServiceResponse.success)
        end
      end

      it 'transitions the organization state to active' do
        expect { response }.to change { organization.reload.state }.from('confirmed').to('active')
      end

      it 'returns a successful response', :aggregate_failures do
        expect(response).to be_success
        expect(response.payload[:organization]).to eq(organization)
      end

      it 'calls Organizations::Transfer::GroupsService for each top-level group', :aggregate_failures do
        expect(Organizations::Transfer::GroupsService).to receive(:new).with(
          group: top_level_group,
          new_organization: organization,
          current_user: current_user
        ).and_call_original

        expect(Organizations::Transfer::GroupsService).to receive(:new).with(
          group: other_top_level_group,
          new_organization: organization,
          current_user: current_user
        ).and_call_original

        response
      end

      it 'copies users to the organization via Organizations::Transfer::OrganizationUsersService' do
        expect_next_instance_of(
          Organizations::Transfer::OrganizationUsersService, organization: organization
        ) do |instance|
          expect(instance).to receive(:execute).and_return(ServiceResponse.success)
        end

        response
      end

      context 'when the organization has no top-level groups' do
        let_it_be_with_reload(:organization) { create(:organization, :confirmed, owners: user) }

        it 'still activates the organization' do
          expect(Organizations::Transfer::GroupsService).not_to receive(:new)

          expect { response }.to change { organization.reload.state }.from('confirmed').to('active')
        end
      end
    end

    it 'transfers groups and copies users before activating the organization' do
      allow(Organizations::Organization).to receive(:find_by_id).and_call_original
      allow(Organizations::Organization).to receive(:find_by_id).with(organization.id).and_return(organization)

      transfer_service = instance_double(Organizations::Transfer::GroupsService)
      allow(Organizations::Transfer::GroupsService).to receive(:new).and_return(transfer_service)
      expect(transfer_service).to receive(:execute).and_return(ServiceResponse.success).twice.ordered

      users_service = instance_double(Organizations::Transfer::OrganizationUsersService)
      allow(Organizations::Transfer::OrganizationUsersService).to receive(:new).and_return(users_service)
      expect(users_service).to receive(:execute).and_return(ServiceResponse.success).ordered

      expect(organization).to receive(:activate).ordered.and_call_original

      response
    end

    context 'when descendants have not yet been transferred' do
      # Reproduces the activation flow that follows Organizations::ConfirmService:
      # the top-level group has been moved to the target organization but its
      # descendants and projects still belong to the previous organization.
      let_it_be(:old_organization) { create(:organization, owners: user) }
      let_it_be_with_refind(:subgroup) { create(:group, parent: top_level_group) }
      let_it_be_with_refind(:nested_project) { create(:project, namespace: subgroup) }

      before do
        subgroup.update_column(:organization_id, old_organization.id)
        nested_project.update_column(:organization_id, old_organization.id)
        nested_project.project_namespace.update_column(:organization_id, old_organization.id)
      end

      it 'moves the descendants to the target organization and activates', :aggregate_failures do
        expect(response).to be_success
        expect(organization.reload.state).to eq('active')

        expect(subgroup.reload.organization_id).to eq(organization.id)
        expect(nested_project.reload.organization_id).to eq(organization.id)
        expect(nested_project.project_namespace.reload.organization_id).to eq(organization.id)
      end
    end

    context 'when Organizations::Transfer::GroupsService returns a non-recoverable error' do
      let(:transfer_error_response) do
        ServiceResponse.error(message: 'Transfer failed')
      end

      before do
        allow_next_instance_of(Organizations::Transfer::GroupsService) do |service|
          allow(service).to receive(:execute).and_return(transfer_error_response)
        end
      end

      it 'returns an error response containing the transfer error message' do
        expect(response).to be_error
        expect(response.message).to include('Transfer failed')
      end

      it 'does not change organization state' do
        expect { response }.not_to change { organization.reload.state }.from('confirmed')
      end
    end

    context 'when the state transition to active fails' do
      before do
        allow_next_instance_of(Organizations::Transfer::GroupsService) do |service|
          allow(service).to receive(:execute).and_return(ServiceResponse.success)
        end
        allow(Organizations::Organization).to receive(:find_by_id).and_call_original
        allow(Organizations::Organization).to receive(:find_by_id).with(organization.id).and_return(organization)
        allow(organization).to receive(:activate).and_return(false)
        organization.errors.add(:base, 'Cannot activate')
      end

      it 'returns an error response with the model error message' do
        expect(response).to be_error
        expect(response.message).to include('Cannot activate')
      end

      it 'does not change organization state' do
        expect { response }.not_to change { organization.reload.state }.from('confirmed')
      end
    end

    context 'when the organization cannot be activated' do
      using RSpec::Parameterized::TableSyntax

      let_it_be(:unauthorized_user) { create(:user) }
      let_it_be(:valid_organization_id) { organization.id }

      # rubocop:disable Layout/LineLength -- For readability
      where(:case_name, :request_user, :request_organization_id, :organization_state, :error_message) do
        'organization cannot be found' | ref(:user)              | non_existing_record_id      | :confirmed   | 'Organization not found'
        'user lacks permissions'       | ref(:unauthorized_user) | ref(:valid_organization_id) | :confirmed   | 'Insufficient permissions'
        'organization is unconfirmed'  | ref(:user)              | ref(:valid_organization_id) | :unconfirmed | 'Organization must be confirmed'
        'organization is active'       | ref(:user)              | ref(:valid_organization_id) | :active      | 'Organization must be confirmed'
      end
      # rubocop:enable Layout/LineLength

      with_them do
        let(:current_user) { request_user }
        let(:organization_id) { request_organization_id }

        before do
          next if organization_state == :confirmed

          organization.update_column(:state, Organizations::Organization.states[organization_state])
        end

        it 'returns an error response', :aggregate_failures do
          expect(response).to be_error
          expect(response.message).to eq(_(error_message))
        end
      end
    end
  end
end
