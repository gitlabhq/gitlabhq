require 'spec_helper'

describe SystemHooksService do
  let (:user)          { create :user }
  let (:project)       { create :project }
  let (:users_project) { create :users_project }

  context 'event data' do
    it { event_data(user, :create).should include(:event_name, :name, :created_at, :email, :user_id) }
    it { event_data(user, :destroy).should include(:event_name, :name, :created_at, :email, :user_id) }
    it { event_data(project, :create).should include(:event_name, :name, :created_at, :path, :project_id, :owner_name, :owner_email) }
    it { event_data(project, :destroy).should include(:event_name, :name, :created_at, :path, :project_id, :owner_name, :owner_email) }
    it { event_data(users_project, :create).should include(:event_name, :created_at, :project_name, :project_path, :project_id, :user_name, :user_email, :project_access) }
    it { event_data(users_project, :destroy).should include(:event_name, :created_at, :project_name, :project_path, :project_id, :user_name, :user_email, :project_access) }
  end

  context 'event names' do
    it { event_name(user, :create).should eq "user_create" }
    it { event_name(user, :destroy).should eq "user_destroy" }
    it { event_name(project, :create).should eq "project_create" }
    it { event_name(project, :destroy).should eq "project_destroy" }
    it { event_name(users_project, :create).should eq "user_add_to_team" }
    it { event_name(users_project, :destroy).should eq "user_remove_from_team" }
  end

  def event_data(*args)
    SystemHooksService.new.send :build_event_data, *args
  end

  def event_name(*args)
    SystemHooksService.new.send :build_event_name, *args
  end
end
