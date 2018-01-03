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

  describe 'notifications' do
    describe "#after_create" do
      it "sends email to user" do
        membership = build(:group_member)

        allow(membership).to receive(:notification_service)
          .and_return(double('NotificationService').as_null_object)
        expect(membership).to receive(:notification_service)

        membership.save
      end
    end

    describe "#after_update" do
      before do
        @group_member = create :group_member
        allow(@group_member).to receive(:notification_service)
          .and_return(double('NotificationService').as_null_object)
      end

      it "sends email to user" do
        expect(@group_member).to receive(:notification_service)
        @group_member.update_attribute(:access_level, GroupMember::MASTER)
      end

      it "does not send an email when the access level has not changed" do
        expect(@group_member).not_to receive(:notification_service)
        @group_member.update_attribute(:access_level, GroupMember::OWNER)
      end
    end

    describe '#after_accept_request' do
      it 'calls NotificationService.accept_group_access_request' do
        member = create(:group_member, user: build(:user), requested_at: Time.now)

        expect_any_instance_of(NotificationService).to receive(:new_group_member)

        member.__send__(:after_accept_request)
      end
    end

    describe '#real_source_type' do
      subject { create(:group_member).real_source_type }

      it { is_expected.to eq 'Group' }
    end
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
