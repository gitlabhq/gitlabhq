# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20190801072937_add_gitlab_instance_administration_project.rb')

describe AddGitlabInstanceAdministrationProject, :migration do
  let(:application_settings) { table(:application_settings) }
  let(:users)                { table(:users) }
  let(:projects)             { table(:projects) }
  let(:namespaces)           { table(:namespaces) }
  let(:members)              { table(:members) }

  let(:service_class) do
    Gitlab::DatabaseImporters::SelfMonitoring::Project::CreateService
  end

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

  describe 'up' do
    context 'without application_settings' do
      it 'does not fail' do
        migrate!

        expect(Project.count).to eq(0)
      end
    end

    context 'without admin users' do
      let!(:application_setting) { application_settings.create! }

      it 'does not fail' do
        migrate!

        expect(Project.count).to eq(0)
      end
    end

    context 'with admin users' do
      let(:project) { Project.last }
      let(:group) { Group.last }
      let!(:application_setting) { application_settings.create! }
      let!(:user) { users.create!(admin: true, email: 'admin1@example.com', projects_limit: 10, state: :active) }

      before do
        stub_application_setting(allow_local_requests_from_web_hooks_and_services: true)
      end

      shared_examples 'has prometheus service' do |listen_address|
        it do
          migrate!

          prometheus = project.prometheus_service
          expect(prometheus).to be_persisted
          expect(prometheus).not_to eq(nil)
          expect(prometheus.api_url).to eq(listen_address)
          expect(prometheus.active).to eq(true)
          expect(prometheus.manual_configuration).to eq(true)
        end
      end

      it_behaves_like 'has prometheus service', 'http://localhost:9090'

      it 'creates GitLab Instance Administrator group' do
        migrate!

        expect(group).to be_persisted
        expect(group.name).to eq('GitLab Instance Administrators')
        expect(group.path).to start_with('gitlab-instance-administrators')
        expect(group.path.split('-').last.length).to eq(8)
        expect(group.visibility_level).to eq(service_class::VISIBILITY_LEVEL)
      end

      it 'creates project with internal visibility' do
        migrate!

        expect(project.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
        expect(project).to be_persisted
      end

      it 'creates project with correct name and description' do
        migrate!

        path = 'administration/monitoring/gitlab_instance_administration_project/index'
        docs_path = Rails.application.routes.url_helpers.help_page_path(path)

        expect(project.name).to eq(service_class::PROJECT_NAME)
        expect(project.description).to eq(
          'This project is automatically generated and will be used to help monitor this GitLab instance. ' \
          "[More information](#{docs_path})"
        )
        expect(File).to exist("doc/#{path}.md")
      end

      it 'adds all admins as maintainers' do
        admin1 = users.create!(admin: true, email: 'admin2@example.com', projects_limit: 10, state: :active)
        admin2 = users.create!(admin: true, email: 'admin3@example.com', projects_limit: 10, state: :active)
        users.create!(email: 'nonadmin1@example.com', projects_limit: 10, state: :active)

        migrate!

        expect(project.owner).to eq(group)
        expect(group.members.collect(&:user).collect(&:id)).to contain_exactly(user.id, admin1.id, admin2.id)
        expect(group.members.collect(&:access_level)).to contain_exactly(
          Gitlab::Access::OWNER,
          Gitlab::Access::MAINTAINER,
          Gitlab::Access::MAINTAINER
        )
      end

      it 'saves the project id' do
        migrate!

        application_setting.reload
        expect(application_setting.instance_administration_project_id).to eq(project.id)
      end

      it 'does not fail when a project already exists' do
        group = namespaces.create!(
          path: 'gitlab-instance-administrators',
          name: 'GitLab Instance Administrators',
          type: 'Group'
        )
        project = projects.create!(
          namespace_id: group.id,
          name: 'GitLab Instance Administration'
        )

        admin1 = users.create!(admin: true, email: 'admin4@example.com', projects_limit: 10, state: :active)
        admin2 = users.create!(admin: true, email: 'admin5@example.com', projects_limit: 10, state: :active)

        members.create!(
          user_id: admin1.id,
          source_id: group.id,
          source_type: 'Namespace',
          type: 'GroupMember',
          access_level: GroupMember::MAINTAINER,
          notification_level: NotificationSetting.levels[:global]
        )
        members.create!(
          user_id: admin2.id,
          source_id: group.id,
          source_type: 'Namespace',
          type: 'GroupMember',
          access_level: GroupMember::MAINTAINER,
          notification_level: NotificationSetting.levels[:global]
        )

        stub_application_setting(instance_administration_project: project)

        migrate!

        expect(Project.last.id).to eq(project.id)
        expect(Group.last.id).to eq(group.id)
      end

      context 'when local requests from hooks and services are not allowed' do
        before do
          stub_application_setting(allow_local_requests_from_web_hooks_and_services: false)
        end

        it_behaves_like 'has prometheus service', 'http://localhost:9090'

        it 'does not overwrite the existing whitelist' do
          application_setting.update!(outbound_local_requests_whitelist: ['example.com'])

          migrate!

          application_setting.reload
          expect(application_setting.outbound_local_requests_whitelist).to contain_exactly(
            'example.com', 'localhost'
          )
        end
      end

      context 'with non default prometheus address' do
        let(:prometheus_settings) do
          {
            enable: true,
            listen_address: 'https://localhost:9090'
          }
        end

        it_behaves_like 'has prometheus service', 'https://localhost:9090'
      end

      context 'when prometheus setting is not present in gitlab.yml' do
        before do
          allow(Gitlab.config).to receive(:prometheus).and_raise(Settingslogic::MissingSetting)
        end

        it 'does not fail' do
          migrate!

          expect(project.prometheus_service).to be_nil
        end
      end

      context 'when prometheus setting is disabled in gitlab.yml' do
        let(:prometheus_settings) do
          {
            enable: false,
            listen_address: 'localhost:9090'
          }
        end

        it 'does not configure prometheus' do
          migrate!

          expect(project.prometheus_service).to be_nil
        end
      end

      context 'when prometheus listen address is blank in gitlab.yml' do
        let(:prometheus_settings) { { enable: true, listen_address: '' } }

        it 'does not configure prometheus' do
          migrate!

          expect(project.prometheus_service).to be_nil
        end
      end
    end
  end
end
