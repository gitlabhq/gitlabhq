# == Schema Information
#
# Table name: members
#
#  id                 :integer          not null, primary key
#  access_level       :integer          not null
#  source_id          :integer          not null
#  source_type        :string(255)      not null
#  user_id            :integer
#  notification_level :integer          not null
#  type               :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#  created_by_id      :integer
#  invite_email       :string(255)
#  invite_token       :string(255)
#  invite_accepted_at :datetime
#

require 'spec_helper'

describe GroupMember, models: true do
  context 'notification' do
    describe "#after_create" do
      it "should send email to user" do
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

      it "should send email to user" do
        expect(@group_member).to receive(:notification_service)
        @group_member.update_attribute(:access_level, GroupMember::MASTER)
      end

      it "does not send an email when the access level has not changed" do
        expect(@group_member).not_to receive(:notification_service)
        @group_member.update_attribute(:access_level, GroupMember::OWNER)
      end
    end
  end
end
