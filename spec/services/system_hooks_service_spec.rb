require 'spec_helper'

describe SystemHooksService do
  let (:user)          { create :user }
  let (:project)       { create :project }
  let (:project_member) { create :project_member }
  let (:key)           { create(:key, user: user) }

  context 'event data' do
    it { expect(event_data(user, :create)).to include(:event_name, :name, :created_at, :email, :user_id) }
    it { expect(event_data(user, :destroy)).to include(:event_name, :name, :created_at, :email, :user_id) }
    it { expect(event_data(project, :create)).to include(:event_name, :name, :created_at, :path, :project_id, :owner_name, :owner_email, :project_visibility) }
    it { expect(event_data(project, :destroy)).to include(:event_name, :name, :created_at, :path, :project_id, :owner_name, :owner_email, :project_visibility) }
    it { expect(event_data(project_member, :create)).to include(:event_name, :created_at, :project_name, :project_path, :project_id, :user_name, :user_email, :access_level, :project_visibility) }
    it { expect(event_data(project_member, :destroy)).to include(:event_name, :created_at, :project_name, :project_path, :project_id, :user_name, :user_email, :access_level, :project_visibility) }
    it { expect(event_data(key, :create)).to include(:username, :key, :id) }
    it { expect(event_data(key, :destroy)).to include(:username, :key, :id) }
  end

  context 'event names' do
    it { expect(event_name(user, :create)).to eq "user_create" }
    it { expect(event_name(user, :destroy)).to eq "user_destroy" }
    it { expect(event_name(project, :create)).to eq "project_create" }
    it { expect(event_name(project, :destroy)).to eq "project_destroy" }
    it { expect(event_name(project_member, :create)).to eq "user_add_to_team" }
    it { expect(event_name(project_member, :destroy)).to eq "user_remove_from_team" }
    it { expect(event_name(key, :create)).to eq 'key_create' }
    it { expect(event_name(key, :destroy)).to eq 'key_destroy' }
  end

  def event_data(*args)
    SystemHooksService.new.send :build_event_data, *args
  end

  def event_name(*args)
    SystemHooksService.new.send :build_event_name, *args
  end
end
