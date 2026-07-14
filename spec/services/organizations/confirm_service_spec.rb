# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::ConfirmService, feature_category: :organization do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:organization) { create(:organization, :unconfirmed, owners: user) }
  let_it_be(:top_level_group) { create(:group, organization: organization, owners: user) }
  let_it_be(:other_top_level_group) { create(:group, organization: organization, owners: user) }

  let(:current_user) { user }
  let(:organization_id) { organization.id }
  let(:group_ids) { [top_level_group.id, other_top_level_group.id] }
  let(:params) { { organization_id: organization_id, group_ids: group_ids } }

  subject(:response) { described_class.new(current_user, params).execute }

  describe '#execute' do
    context 'when all validations pass' do
      it 'transitions the organization state to confirmed' do
        expect { response }.to change { organization.reload.state }.from('unconfirmed').to('confirmed')
      end

      it 'records the confirming user in the state metadata', :aggregate_failures do
        response

        expect(organization.reload.state_metadata).to include(
          'confirmed_by_user_id' => current_user.id
        )
        expect(organization.state_metadata['confirmed_at']).to be_present
      end

      it 'returns a successful response', :aggregate_failures do
        expect(response).to be_success
        expect(response.payload[:organization]).to eq(organization)
      end

      it 'publishes an Organizations::ConfirmedEvent' do
        expect { response }
          .to publish_event(Organizations::ConfirmedEvent)
          .with(organization_id: organization.id)
      end

      context 'when group_ids is not provided' do
        let(:params) { { organization_id: organization_id } }

        it 'does not call Organizations::Transfer::TopLevelGroupService' do
          expect(Organizations::Transfer::TopLevelGroupService).not_to receive(:new)

          response
        end

        it 'updates organization state' do
          expect { response }.to change { organization.reload.state }.from('unconfirmed').to('confirmed')
        end
      end

      context 'when organization object is passed instead of organization_id' do
        let(:params) { { organization: organization, group_ids: group_ids } }

        it 'does not perform a database lookup' do
          expect(Organizations::Organization).not_to receive(:find_by_id)

          response
        end

        it 'transitions the organization state to confirmed' do
          expect { response }.to change { organization.reload.state }.from('unconfirmed').to('confirmed')
        end
      end

      context 'when organization param is not an Organization object' do
        let(:params) { { organization: organization.id, group_ids: group_ids } }

        it 'returns an error' do
          expect(response).to be_error
          expect(response.message).to eq('Organization not found')
        end
      end

      it 'calls Organizations::Transfer::TopLevelGroupService with the groups and organization' do
        allow(Organizations::Transfer::TopLevelGroupService).to receive(:new).and_call_original
        expect(Organizations::Transfer::TopLevelGroupService).to receive(:new).with(
          groups: a_collection_containing_exactly(top_level_group, other_top_level_group),
          new_organization: organization,
          current_user: current_user
        ).and_call_original

        response
      end
    end

    it "calls Organizations::Transfer::TopLevelGroupService before confirming the organization" do
      allow(Organizations::Organization).to receive(:find_by_id).and_call_original
      allow(Organizations::Organization).to receive(:find_by_id).with(organization.id).and_return(organization)

      transfer_service = instance_double(Organizations::Transfer::TopLevelGroupService)
      allow(Organizations::Transfer::TopLevelGroupService).to receive(:new).and_return(transfer_service)
      expect(transfer_service).to receive(:execute).and_return(ServiceResponse.success).ordered

      expect(organization).to receive(:confirm).with(confirmed_by_user: current_user).ordered

      response
    end

    context 'when Organizations::Transfer::TopLevelGroupService returns an error' do
      let(:transfer_error_response) do
        ServiceResponse.error(message: 'Transfer failed', payload: { failed: { top_level_group.id => 'reason' } })
      end

      before do
        allow_next_instance_of(Organizations::Transfer::TopLevelGroupService) do |service|
          allow(service).to receive(:execute).and_return(transfer_error_response)
        end
      end

      it 'returns the transfer error response' do
        expect(response).to eq(transfer_error_response)
      end

      it "does'nt change organization confirmatino state" do
        expect { response }.not_to change { organization.reload.state }.from('unconfirmed')
      end

      it 'does not publish an Organizations::ConfirmedEvent' do
        expect { response }.to not_publish_event(Organizations::ConfirmedEvent)
      end
    end

    context 'when the organization cannot be confirmed' do
      using RSpec::Parameterized::TableSyntax

      let_it_be(:unauthorized_user) { create(:user) }
      let_it_be(:valid_organization_id) { organization.id }
      let_it_be(:valid_group_ids) { [top_level_group.id, other_top_level_group.id] }
      let_it_be(:invalid_group_ids) { [top_level_group.id, non_existing_record_id] }

      # rubocop:disable Layout/LineLength -- For readability
      where(:case_name, :request_user, :request_organization_id, :request_group_ids, :organization_state, :error_message) do
        'organization cannot be found'    | ref(:user)              | non_existing_record_id      | ref(:valid_group_ids)   | :unconfirmed | 'Organization not found'
        'user lacks permissions'          | ref(:unauthorized_user) | ref(:valid_organization_id) | ref(:valid_group_ids)   | :unconfirmed | 'Insufficient permissions'
        'a group id does not exist'       | ref(:user)              | ref(:valid_organization_id) | ref(:invalid_group_ids) | :unconfirmed | 'One or more groups could not be found'
        'organization is not unconfirmed' | ref(:user)              | ref(:valid_organization_id) | ref(:valid_group_ids)   | :active      | 'State cannot transition via "confirm"'
      end
      # rubocop:enable Layout/LineLength

      with_them do
        let(:current_user) { request_user }
        let(:organization_id) { request_organization_id }
        let(:group_ids) { request_group_ids }

        before do
          next if organization_state == :unconfirmed

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
