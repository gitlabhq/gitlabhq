# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupMember do
  context 'scopes' do
    let_it_be(:user_1) { create(:user) }
    let_it_be(:user_2) { create(:user) }

    it 'counts users by group ID' do
      group_1 = create(:group)
      group_2 = create(:group)

      group_1.add_owner(user_1)
      group_1.add_owner(user_2)
      group_2.add_owner(user_1)

      expect(described_class.count_users_by_group_id).to eq(group_1.id => 2,
                                                            group_2.id => 1)
    end

    describe '.of_ldap_type' do
      it 'returns ldap type users' do
        group_member = create(:group_member, :ldap)

        expect(described_class.of_ldap_type).to eq([group_member])
      end
    end

    describe '.with_user' do
      it 'returns requested user' do
        group_member = create(:group_member, user: user_2)
        create(:group_member, user: user_1)

        expect(described_class.with_user(user_2)).to eq([group_member])
      end
    end
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:update_two_factor_requirement).to(:user).allow_nil }
  end

  describe '.access_level_roles' do
    it 'returns Gitlab::Access.options_with_owner' do
      expect(described_class.access_level_roles).to eq(Gitlab::Access.options_with_owner)
    end
  end

  it_behaves_like 'members notifications', :group

  describe '#namespace_id' do
    subject { build(:group_member, source_id: 1).namespace_id }

    it { is_expected.to eq 1 }
  end

  describe '#real_source_type' do
    subject { create(:group_member).real_source_type }

    it { is_expected.to eq 'Group' }
  end

  describe '#update_two_factor_requirement' do
    it 'is called after creation and deletion' do
      user = build :user
      group_member = build :group_member, user: user

      expect(user).to receive(:update_two_factor_requirement)

      group_member.save!

      expect(user).to receive(:update_two_factor_requirement)

      group_member.destroy!
    end
  end

  describe '#destroy' do
    context 'for an orphaned member' do
      let!(:orphaned_group_member) do
        create(:group_member).tap { |member| member.update_column(:user_id, nil) }
      end

      it 'does not raise an error' do
        expect { orphaned_group_member.destroy! }.not_to raise_error
      end
    end
  end

  describe '#after_accept_invite' do
    it 'calls #update_two_factor_requirement' do
      email = 'foo@email.com'
      user = build(:user, email: email)
      group = create(:group, require_two_factor_authentication: true)
      group_member = create(:group_member, group: group, invite_token: '1234', invite_email: email)

      expect(user).to receive(:require_two_factor_authentication_from_group).and_call_original

      group_member.accept_invite!(user)

      expect(user.require_two_factor_authentication_from_group).to be_truthy
    end
  end

  context 'access levels' do
    context 'with parent group' do
      it_behaves_like 'inherited access level as a member of entity' do
        let(:entity) { create(:group, parent: parent_entity) }
      end
    end

    context 'with parent group and a sub subgroup' do
      it_behaves_like 'inherited access level as a member of entity' do
        let(:subgroup) { create(:group, parent: parent_entity) }
        let(:entity) { create(:group, parent: subgroup) }
      end

      context 'when only the subgroup has the member' do
        it_behaves_like 'inherited access level as a member of entity' do
          let(:parent_entity) { create(:group, parent: create(:group)) }
          let(:entity) { create(:group, parent: parent_entity) }
        end
      end
    end
  end

  context 'when group member expiration date is updated' do
    let_it_be(:group_member) { create(:group_member) }

    it 'emails the user that their group membership expiry has changed' do
      expect_next_instance_of(NotificationService) do |notification|
        allow(notification).to receive(:updated_group_member_expiration).with(group_member)
      end

      group_member.update!(expires_at: 5.days.from_now)
    end
  end
end
