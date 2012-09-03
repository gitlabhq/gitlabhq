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
      subject.should_receive(:after_commit)
      UsersProject.observers.enable :users_project_observer do
        Factory.create(:users_project, 
                       project: project, 
                       user: user)
      end
    end
    it "should send email to user" do
      Notify.should_receive(:project_access_granted_email).with(users_project.id).and_return(double(deliver: true))
      subject.after_commit(users_project)
    end
  end

  describe "#after_update" do
    it "should called when UsersProject updated" do
      subject.should_receive(:after_commit)
      UsersProject.observers.enable :users_project_observer do
        users_project.update_attribute(:project_access, 40)
      end
    end
    it "should send email to user" do
      Notify.should_receive(:project_access_granted_email).with(users_project.id).and_return(double(deliver: true))
      subject.after_commit(users_project)
    end
  end
end
