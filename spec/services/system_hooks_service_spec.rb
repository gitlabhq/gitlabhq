require 'spec_helper'

describe SystemHooksService do
  let (:user)          { create :user }
  let (:project)       { create :project }
  let (:users_project) { create :users_project }

  context 'it should build event data' do
    it 'should build event data for user' do
      SystemHooksService.build_event_data(user, :create).should include(:event_name, :name, :created_at, :email)
    end

    it 'should build event data for project' do
      SystemHooksService.build_event_data(project, :create).should include(:event_name, :name, :created_at, :path, :project_id, :owner_name, :owner_email)
    end

    it 'should build event data for users project' do
      SystemHooksService.build_event_data(users_project, :create).should include(:event_name, :created_at, :project_name, :project_path, :project_id, :user_name, :user_email, :project_access)
    end
  end

  context 'it should build event names' do
    it 'should build event names for user' do
      SystemHooksService.build_event_name(user, :create).should eq "user_create"

      SystemHooksService.build_event_name(user, :destroy).should eq "user_destroy"
    end

    it 'should build event names for project' do
      SystemHooksService.build_event_name(project, :create).should eq "project_create"

      SystemHooksService.build_event_name(project, :destroy).should eq "project_destroy"
    end

    it 'should build event names for users project' do
      SystemHooksService.build_event_name(users_project, :create).should eq "user_add_to_team"

      SystemHooksService.build_event_name(users_project, :destroy).should eq "user_remove_from_team"
    end
  end
end
