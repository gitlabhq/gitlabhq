# == Schema Information
#
# Table name: members
#
#  id                 :integer          not null, primary key
#  access_level       :integer          not null
#  source_id          :integer          not null
#  source_type        :string(255)      not null
#  user_id            :integer          not null
#  notification_level :integer          not null
#  type               :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#

require 'spec_helper'

describe GroupMember do
  context 'notification' do
    describe "#after_create" do
      it "should send email to user" do
        membership = build(:group_member)
        membership.stub(notification_service: double('NotificationService').as_null_object)
        membership.should_receive(:notification_service)
        membership.save
      end
    end

    describe "#after_update" do
      before do
        @membership = create :group_member
        @membership.stub(notification_service: double('NotificationService').as_null_object)
      end

      it "should send email to user" do
        @membership.should_receive(:notification_service)
        @membership.update_attribute(:access_level, GroupMember::MASTER)
      end

      it "does not send an email when the access level has not changed" do
        @membership.should_not_receive(:notification_service)
        @membership.update_attribute(:access_level, GroupMember::OWNER)
      end
    end
  end
end
