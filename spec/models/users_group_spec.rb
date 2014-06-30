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

describe UsersGroup do
  describe "Associations" do
    it { should belong_to(:group) }
    it { should belong_to(:user) }
  end

  describe "Mass assignment" do
  end

  describe "Validation" do
    let!(:users_group) { create(:users_group) }

    it { should validate_presence_of(:user_id) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:group_id).with_message(/already exists/) }

    it { should validate_presence_of(:group_id) }
    it { should ensure_inclusion_of(:group_access).in_array(UsersGroup.group_access_roles.values) }
  end

  describe "Delegate methods" do
    it { should respond_to(:user_name) }
    it { should respond_to(:user_email) }
  end

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
        @membership.update_attribute(:group_access, UsersGroup::MASTER)
      end

      it "does not send an email when the access level has not changed" do
        @membership.should_not_receive(:notification_service)
        @membership.update_attribute(:group_access, UsersGroup::OWNER)
      end
    end
  end
end
