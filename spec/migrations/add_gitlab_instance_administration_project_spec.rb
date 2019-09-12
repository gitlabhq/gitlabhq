# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20190801072937_add_gitlab_instance_administration_project.rb')

describe AddGitlabInstanceAdministrationProject, :migration do
  let(:application_settings) { table(:application_settings) }
  let(:users)                { table(:users) }

  let(:prometheus_settings) do
    {
      enable: true,
      listen_address: 'localhost:9090'
    }
  end

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')

    stub_config(prometheus: prometheus_settings)
  end

  describe 'down' do
    let!(:application_setting) { application_settings.create! }
    let!(:user) { users.create!(admin: true, email: 'admin1@example.com', projects_limit: 10, state: :active) }

    it 'deletes group and project' do
      migrate!

      expect(Project.count).to eq(1)
      expect(Group.count).to eq(1)

      schema_migrate_down!

      expect(Project.count).to eq(0)
      expect(Group.count).to eq(0)
    end
  end
end
