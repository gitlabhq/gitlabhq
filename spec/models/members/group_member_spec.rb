require 'spec_helper'

describe GroupMember, models: true do
  describe 'notifications' do
    describe "#after_create" do
      it "sends email to user" do
        membership = build(:group_member)

        allow(membership).to receive(:notification_service).
          and_return(double('NotificationService').as_null_object)
        expect(membership).to receive(:notification_service)

        membership.save
      end
    end

    describe "#after_update" do
      before do
        @group_member = create :group_member
        allow(@group_member).to receive(:notification_service).
          and_return(double('NotificationService').as_null_object)
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
        member = create(:group_member, user: build_stubbed(:user), requested_at: Time.now)

        expect_any_instance_of(NotificationService).to receive(:new_group_member)

        member.__send__(:after_accept_request)
      end
    end

    describe '#real_source_type' do
      subject { create(:group_member).real_source_type }

      it { is_expected.to eq 'Group' }
    end
  end
end
