require 'spec_helper'

describe UsersProjectObserver do
  let(:user) { Factory.create :user }
  let(:project) { Factory.create(:project, 
                                 code: "Fuu", 
                                 path: "Fuu" ) }
  let(:users_project) { Factory.create(:users_project,
                                        project: project,
                                        user: user )}
  subject { UsersProjectObserver.instance }

  describe "#after_create" do
    it "should called when UsersProject created" do
      subject.should_receive(:after_create)
      UsersProject.observers.enable :users_project_observer do
        Factory.create(:users_project, 
                       project: project, 
                       user: user)
      end
    end
    it "should send email to user" do
      Notify.should_receive(:project_access_granted_email).with(users_project.id).and_return(double(deliver: true))
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
        users_project.update_attribute(:project_access, 40)
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
        UsersProject.bulk_delete(
          users_project.project,
          [users_project.user.id]
        )
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
