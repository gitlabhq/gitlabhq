require 'spec_helper'

describe UsersGroupObserver do
  before(:each) { enable_observers }
  after(:each) { disable_observers }

  subject { UsersGroupObserver.instance }
  before { subject.stub(notification: double('NotificationService').as_null_object) }

  describe "#after_create" do
    it "should send email to user" do
      subject.should_receive(:notification)
      create(:users_group)
    end
  end

  describe "#after_update" do
    before do
      @membership = create :users_group
    end

    it "should send email to user" do
      subject.should_receive(:notification)
      @membership.update_attribute(:group_access, UsersGroup::MASTER)
    end

    it "does not send an email when the access level has not changed" do
      subject.should_not_receive(:notification)
      @membership.update_attribute(:group_access, UsersGroup::OWNER)
    end
  end
end
