# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::Groups::TransferValidator, :aggregate_failures, feature_category: :organization do
  let_it_be(:user) { create(:user) }
  let_it_be(:admin_user) { create(:admin) }
  let_it_be(:old_organization) { create(:organization) }
  let_it_be_with_refind(:new_organization) { create(:organization) }
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
end
