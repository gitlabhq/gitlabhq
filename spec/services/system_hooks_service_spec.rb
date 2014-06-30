require 'spec_helper'

describe SystemHooksService do
  let (:user)          { create :user }
  let (:project)       { create :project }
  let (:users_project) { create :users_project }

  context 'event data' do
    it { expect(event_data(user, :create)).to include(:event_name, :name, :created_at, :email, :user_id) }
    it { expect(event_data(user, :destroy)).to include(:event_name, :name, :created_at, :email, :user_id) }
    it { expect(event_data(project, :create)).to include(:event_name, :name, :created_at, :path, :project_id, :owner_name, :owner_email, :project_visibility) }
    it { expect(event_data(project, :destroy)).to include(:event_name, :name, :created_at, :path, :project_id, :owner_name, :owner_email, :project_visibility) }
    it { expect(event_data(users_project, :create)).to include(:event_name, :created_at, :project_name, :project_path, :project_id, :user_name, :user_email, :project_access, :project_visibility) }
    it { expect(event_data(users_project, :destroy)).to include(:event_name, :created_at, :project_name, :project_path, :project_id, :user_name, :user_email, :project_access, :project_visibility) }
  end

  context 'event names' do
    it { expect(event_name(user, :create)).to eq "user_create" }
    it { expect(event_name(user, :destroy)).to eq "user_destroy" }
    it { expect(event_name(project, :create)).to eq "project_create" }
    it { expect(event_name(project, :destroy)).to eq "project_destroy" }
    it { expect(event_name(users_project, :create)).to eq "user_add_to_team" }
    it { expect(event_name(users_project, :destroy)).to eq "user_remove_from_team" }
  end

  def event_data(*args)
    SystemHooksService.new.send :build_event_data, *args
  end

  def event_name(*args)
    SystemHooksService.new.send :build_event_name, *args
  end
end
