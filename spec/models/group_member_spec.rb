# == Schema Information
#
# Table name: users_groups
#
#  id                 :integer          not null, primary key
#  group_access       :integer          not null
#  group_id           :integer          not null
#  user_id            :integer          not null
#  created_at         :datetime
#  updated_at         :datetime
#  notification_level :integer          default(3), not null
#

require 'spec_helper'

describe GroupMember do
  context 'notification' do
    describe "#after_create" do
      it "should send email to user" do
        membership = build(:users_group)
        membership.stub(notification_service: double('NotificationService').as_null_object)
        membership.should_receive(:notification_service)
        membership.save
      end
    end

    describe "#after_update" do
      before do
        @membership = create :users_group
        @membership.stub(notification_service: double('NotificationService').as_null_object)
      end

      it "should send email to user" do
        @membership.should_receive(:notification_service)
        @membership.update_attribute(:group_access, GroupMember::MASTER)
      end

      it "does not send an email when the access level has not changed" do
        @membership.should_not_receive(:notification_service)
        @membership.update_attribute(:group_access, GroupMember::OWNER)
      end
    end
  end
end
