# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::Groups::TransferValidator, :aggregate_failures, feature_category: :organization do
  let_it_be(:old_organization) { create(:organization) }
  let_it_be_with_refind(:new_organization) { create(:organization) }
  let_it_be(:user) { create(:user, organization: old_organization) }
  let_it_be(:admin_user) { create(:admin) }
  let_it_be_with_refind(:group) { create(:group, organization: old_organization) }
  let_it_be(:parent_group) { create(:group, organization: old_organization) }
  let_it_be(:subgroup) { create(:group, parent: parent_group, organization: old_organization) }
  let_it_be(:group_in_new_org) { create(:group, organization: new_organization) }

  subject(:validator) { described_class.new(group: group, new_organization: new_organization, current_user: user) }

  context 'when transfer is valid' do
    before_all do
      group.add_owner(user)
      new_organization.add_owner(user)
    end

    it 'allows transfer' do
      expect(validator.can_transfer?).to be true
      expect(validator.error_message).to be_nil
    end
  end

  context 'when user is admin with admin mode enabled', :enable_admin_mode do
    subject(:validator) do
      described_class.new(group: group, new_organization: new_organization, current_user: admin_user)
    end

    before_all do
      group.add_owner(user)
    end

    it 'allows transfer' do
      expect(validator.can_transfer?).to be true
      expect(validator.error_message).to be_nil
    end
  end

  context 'when group is not root' do
    subject(:validator) do
      described_class.new(group: subgroup, new_organization: new_organization, current_user: user)
    end

    it 'prevents transfer with group_not_root error' do
      expect(validator.can_transfer?).to be false
      expect(validator.error_message)
        .to eq(s_('TransferOrganization|Only root groups can be transferred to a different organization.'))
    end
  end

  context 'when group is already in the target organization' do
    subject(:validator) do
      described_class.new(group: group_in_new_org, new_organization: new_organization, current_user: user)
    end

    it 'prevents transfer with same_organization error' do
      expect(validator.can_transfer?).to be false
      expect(validator.error_message).to eq(s_('TransferOrganization|Group is already in the target organization.'))
    end
  end

  context 'when user lacks permissions' do
    context 'when user is not group owner' do
      before_all do
        new_organization.add_owner(user)
      end

      it 'prevents transfer with permission error' do
        expect(validator.can_transfer?).to be false
        expect(validator.error_message)
          .to eq(s_("TransferOrganization|You must be an owner of both the group and new organization."))
      end
    end

    context 'when user is not organization owner' do
      before_all do
        group.add_owner(user)
        new_organization.reload
      end

      it 'prevents transfer with permission error' do
        expect(validator.can_transfer?).to be false
        expect(validator.error_message)
          .to eq(s_("TransferOrganization|You must be an owner of both the group and new organization."))
      end
    end

    context 'when user is neither group nor organization owner' do
      it 'prevents transfer with permission error' do
        expect(validator.can_transfer?).to be false
        expect(validator.error_message)
          .to eq(s_("TransferOrganization|You must be an owner of both the group and new organization."))
      end
    end
  end

  context 'when user is an admin without admin mode' do
    subject(:validator) do
      described_class.new(group: group, new_organization: new_organization, current_user: admin_user)
    end

    it 'prevents transfer with permission error' do
      expect(validator.can_transfer?).to be false
      expect(validator.error_message).to eq('You must be an owner of both the group and new organization.')
    end
  end

  context 'with nil new_organization' do
    subject(:validator) { described_class.new(group: group, new_organization: nil, current_user: user) }

    before_all do
      group.add_owner(user)
    end

    it 'prevents transfer with permission error' do
      expect(validator.can_transfer?).to be false
      expect(validator.error_message).to eq('You must be an owner of both the group and new organization.')
    end
  end

  describe '#can_transfer_users?' do
    before_all do
      group.add_owner(user)
      new_organization.add_owner(user)
    end

    context 'when all users belong to the same organization as the group' do
      let_it_be(:user1) { create(:user, organization: old_organization) }
      let_it_be(:user2) { create(:user, organization: old_organization) }

      before_all do
        group.add_maintainer(user1)
        group.add_developer(user2)
      end

      it 'returns true' do
        expect(validator.can_transfer_users?).to be true
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
        expect(validator.can_transfer_users?).to be false
      end
    end

    context 'when group has no users besides owners' do
      let_it_be_with_refind(:empty_group) { create(:group, organization: old_organization) }
      let(:empty_validator) do
        described_class.new(group: empty_group, new_organization: new_organization, current_user: user)
      end

      it 'returns false' do
        expect(empty_validator.can_transfer_users?).to be false
      end
    end
  end

  describe '#cannot_transfer_users_error' do
    it 'returns error message' do
      expected_message = s_("TransferOrganization|Cannot transfer users to a different organization " \
        "if all users do not belong to the same organization as the top-level group.")
      expect(validator.cannot_transfer_users_error).to eq(expected_message)
    end
  end
end
