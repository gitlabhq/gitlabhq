require 'spec_helper'

describe GroupMember do
  describe '.access_level_roles' do
    it 'returns Gitlab::Access.options_with_owner' do
      expect(described_class.access_level_roles).to eq(Gitlab::Access.options_with_owner)
    end
  end

  describe '.access_levels' do
    it 'returns Gitlab::Access.options_with_owner' do
      expect(described_class.access_levels).to eq(Gitlab::Access.sym_options_with_owner)
    end
  end

  describe '.add_users' do
    it 'adds the given users to the given group' do
      group = create(:group)
      users = create_list(:user, 2)

      described_class.add_users(
        group,
        [users.first.id, users.second],
        described_class::MASTER
      )

      expect(group.users).to include(users.first, users.second)
    end
  end

  it_behaves_like 'members notifications', :group

  describe '#real_source_type' do
    subject { create(:group_member).real_source_type }

    it { is_expected.to eq 'Group' }
  end

  describe '#update_two_factor_requirement' do
    let(:user) { build :user }
    let(:group_member) { build :group_member, user: user }

    it 'is called after creation and deletion' do
      expect(user).to receive(:update_two_factor_requirement)

      group_member.save

      expect(user).to receive(:update_two_factor_requirement)

      group_member.destroy
    end
  end
end
