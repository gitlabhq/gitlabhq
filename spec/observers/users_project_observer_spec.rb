require 'spec_helper'

describe UsersProjectObserver do
  let(:users_project) { stub.as_null_object }
  subject { UsersProjectObserver.instance }

  describe "#after_create" do
    it "should called when UsersProject created" do
      subject.should_receive(:after_create)

      UsersProject.observers.enable :users_project_observer do
        create(:users_project)
      end
    end

    it "should send email to user" do
      Event.stub(:create => true)
      Notify.should_receive(:project_access_granted_email).and_return(stub(deliver: true))

      subject.after_create(users_project)
    end

    it "should create new event" do
      Event.should_receive(:create).with(
        project_id: users_project.project.id,
        action: Event::Joined,
        author_id: users_project.user.id
      )

      subject.after_create(users_project)
    end
  end

  describe "#after_update" do
    it "should called when UsersProject updated" do
      subject.should_receive(:after_update)

      UsersProject.observers.enable :users_project_observer do
        create(:users_project).update_attribute(:project_access, 40)
      end
    end

    it "should send email to user" do
      Notify.should_receive(:project_access_granted_email).with(users_project.id).and_return(double(deliver: true))

      subject.after_update(users_project)
    end
  end

  describe "#after_destroy" do
    it "should called when UsersProject destroyed" do
      subject.should_receive(:after_destroy)

      UsersProject.observers.enable :users_project_observer do
        create(:users_project).destroy
      end
    end

    it "should create new event" do
      Event.should_receive(:create).with(
        project_id: users_project.project.id,
        action: Event::Left,
        author_id: users_project.user.id
      )
      subject.after_destroy(users_project)
    end
  end
end
