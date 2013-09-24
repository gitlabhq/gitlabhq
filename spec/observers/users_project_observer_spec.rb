require 'spec_helper'

describe UsersProjectObserver do
  before(:each) { enable_observers }
  after(:each) { disable_observers }

  let(:user) { create(:user) }
  let(:project) { create(:project) }
  subject { UsersProjectObserver.instance }
  before { subject.stub(notification: mock('NotificationService').as_null_object) }

  describe "#after_commit" do
    it "should called when UsersProject created" do
      subject.should_receive(:after_commit)
      create(:users_project)
    end

    it "should send email to user" do
      subject.should_receive(:notification)
      Event.stub(create: true)

      create(:users_project)
    end

    it "should create new event" do
      Event.should_receive(:create)

      create(:users_project)
    end
  end

  describe "#after_update" do
    before do
      @users_project = create :users_project
    end

    it "should called when UsersProject updated" do
      subject.should_receive(:after_commit)
      @users_project.update_attribute(:project_access, UsersProject::MASTER)
    end

    it "should send email to user" do
      subject.should_receive(:notification)
      @users_project.update_attribute(:project_access, UsersProject::MASTER)
    end

    it "should not called after UsersProject destroyed" do
      subject.should_not_receive(:after_commit)
      @users_project.destroy
    end
  end

  describe "#after_destroy" do
    before do
      @users_project = create :users_project
    end

    it "should called when UsersProject destroyed" do
      subject.should_receive(:after_destroy)
      @users_project.destroy
    end

    it "should create new event" do
      Event.should_receive(:create)
      @users_project.destroy
    end
  end
end
