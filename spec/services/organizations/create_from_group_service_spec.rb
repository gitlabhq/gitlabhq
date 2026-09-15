# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::CreateFromGroupService, feature_category: :organization do
  # rubocop:disable Gitlab/RSpec/AvoidCreateDefaultOrganization -- Needed to test creation from the default org
  let_it_be(:default_organization) { create(:organization, :default) }
  # rubocop:enable Gitlab/RSpec/AvoidCreateDefaultOrganization

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:group) { create(:group, organization: default_organization) }

  let(:current_user) { nil }
  let(:skip_authorization) { true }

  subject(:result) do
    described_class.new(group: group, current_user: current_user, skip_authorization: skip_authorization).execute
  end

  describe '#execute' do
    it 'creates an unconfirmed organization mirroring the group' do
      expect { result }.to change { Organizations::Organization.count }.by(1)

      organization = result.payload[:organization]

      expect(result).to be_success
      expect(organization).to be_unconfirmed
      expect(organization.name).to eq(group.name)
      expect(organization.path).to eq(group.path)
      expect(organization.visibility_level).to eq(group.visibility_level)
    end

    it 'transfers the group to the new organization' do
      organization = result.payload[:organization]

      expect(group.reload.organization).to eq(organization)
    end

    it 'publishes a GroupTransferredEvent for the transferred group' do
      published = []
      expect(Gitlab::EventStore).to receive(:publish_group) { |events| published = events }

      organization = result.payload[:organization]

      expect(published.map(&:data)).to contain_exactly(
        { group_id: group.id,
          old_organization_id: default_organization.id,
          new_organization_id: organization.id }
      )
    end

    context 'when the group path is reserved for organizations' do
      let_it_be_with_reload(:group) { create(:group, path: 'badges', organization: default_organization) }

      it 'falls back to a path derived from the group id' do
        expect(result).to be_success
        expect(result.payload[:organization].path).to eq("organization-#{group.id}")
      end
    end

    context 'when authorization is not skipped' do
      let(:skip_authorization) { false }
      let(:current_user) { user }

      context 'when the user can administer the group', :saas do
        let_it_be_with_reload(:group) { create(:group, organization: default_organization) }

        before_all do
          group.add_owner(user)
        end

        it 'creates the organization with the user as an owner and transfers the group' do
          expect { result }.to change { Organizations::Organization.count }.by(1)

          organization = result.payload[:organization]

          expect(result).to be_success
          expect(organization).to be_unconfirmed
          expect(organization.owner?(user)).to be(true)
          expect(group.reload.organization).to eq(organization)
        end
      end

      context 'when the user cannot administer the group' do
        it 'returns an error without creating an organization' do
          expect { result }.not_to change { Organizations::Organization.count }

          expect(result).to be_error
          expect(result.reason).to eq(:insufficient_permissions)
          expect(result.message).to contain_exactly(
            'You have insufficient permissions to create an organization from this group.'
          )
          expect(group.reload.organization).to eq(default_organization)
        end
      end

      context 'when there is no current user' do
        let(:current_user) { nil }

        it 'returns an error without creating an organization' do
          expect { result }.not_to change { Organizations::Organization.count }

          expect(result).to be_error
          expect(result.reason).to eq(:insufficient_permissions)
          expect(result.message).to contain_exactly(
            'You have insufficient permissions to create an organization from this group.'
          )
          expect(group.reload.organization).to eq(default_organization)
        end
      end
    end

    context 'when the group is not a top-level group' do
      let_it_be(:parent) { create(:group, organization: default_organization) }
      let_it_be_with_reload(:group) { create(:group, parent: parent, organization: default_organization) }

      it 'returns an error without creating an organization' do
        expect { result }.not_to change { Organizations::Organization.count }

        expect(result).to be_error
        expect(result.reason).to eq(:not_root_group)
        expect(group.reload.organization).to eq(default_organization)
      end
    end

    context 'when the group is not in the default organization' do
      let_it_be(:other_organization) { create(:organization) }
      let_it_be_with_reload(:group) { create(:group, organization: other_organization) }

      it 'returns an error without creating an organization' do
        expect { result }.not_to change { Organizations::Organization.count }

        expect(result).to be_error
        expect(result.reason).to eq(:not_in_default_organization)
        expect(group.reload.organization).to eq(other_organization)
      end
    end

    context 'when the organization cannot be created' do
      before do
        allow_next_instance_of(Organizations::Organization) do |organization|
          allow(organization).to receive(:save).and_return(false)
          allow(organization).to receive_message_chain(:errors, :full_messages).and_return(['Name is invalid'])
        end
      end

      it 'returns an error' do
        expect(result).to be_error
        expect(result.reason).to eq(:organization_not_created)
        expect(result.message).to include('Name is invalid')
        expect(group.reload.organization).to eq(default_organization)
      end
    end

    context 'when the group cannot be transferred' do
      before do
        allow_next_instance_of(Organizations::Transfer::TopLevelGroupService) do |service|
          allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'transfer failed'))
        end
      end

      it 'returns an error with the organization that was left behind' do
        expect(result).to be_error
        expect(result.reason).to eq(:group_not_transferred)
        expect(result.payload[:organization]).to be_present
        expect(group.reload.organization).to eq(default_organization)
      end
    end
  end
end
