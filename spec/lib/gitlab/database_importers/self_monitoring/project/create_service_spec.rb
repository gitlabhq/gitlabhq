# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::DatabaseImporters::SelfMonitoring::Project::CreateService do
  describe '#execute' do
    let(:result) { subject.execute }

    let(:prometheus_settings) do
      {
        enable: true,
        listen_address: 'localhost:9090'
      }
    end

    before do
      stub_config(prometheus: prometheus_settings)
    end

    context 'without application_settings' do
      it 'returns error' do
        expect(subject).to receive(:log_error).and_call_original
        expect(result).to eq(
          status: :error,
          message: 'No application_settings found',
          last_step: :validate_application_settings
        )

        expect(Project.count).to eq(0)
        expect(Group.count).to eq(0)
      end
    end

    context 'without admin users' do
      let(:application_setting) { Gitlab::CurrentSettings.current_application_settings }

      before do
        allow(ApplicationSetting).to receive(:current_without_cache) { application_setting }
      end

      it 'returns error' do
        expect(subject).to receive(:log_error).and_call_original
        expect(result).to eq(
          status: :error,
          message: 'No active admin user found',
          last_step: :validate_admins
        )

        expect(Project.count).to eq(0)
        expect(Group.count).to eq(0)
      end
    end

    context 'with application settings and admin users' do
      let(:project) { result[:project] }
      let(:group) { result[:group] }
      let(:application_setting) { Gitlab::CurrentSettings.current_application_settings }

      let!(:user) { create(:user, :admin) }

      before do
        allow(ApplicationSetting).to receive(:current_without_cache) { application_setting }
        application_setting.allow_local_requests_from_web_hooks_and_services = true
      end

      shared_examples 'has prometheus service' do |listen_address|
        it do
          expect(result[:status]).to eq(:success)

          prometheus = project.prometheus_service
          expect(prometheus).not_to eq(nil)
          expect(prometheus.api_url).to eq(listen_address)
          expect(prometheus.active).to eq(true)
          expect(prometheus.manual_configuration).to eq(true)
        end
      end

      it_behaves_like 'has prometheus service', 'http://localhost:9090'

      it "tracks successful install" do
        expect(::Gitlab::Tracking).to receive(:event)
        expect(::Gitlab::Tracking).to receive(:event).with("self_monitoring", "project_created")

        result
      end

      it 'creates group' do
        expect(result[:status]).to eq(:success)
        expect(group).to be_persisted
        expect(group.name).to eq('GitLab Instance Administrators')
        expect(group.path).to start_with('gitlab-instance-administrators')
        expect(group.path.split('-').last.length).to eq(8)
        expect(group.visibility_level).to eq(described_class::VISIBILITY_LEVEL)
      end

      it 'creates project with internal visibility' do
        expect(result[:status]).to eq(:success)
        expect(project.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
        expect(project).to be_persisted
      end

      it 'creates project with internal visibility even when internal visibility is restricted' do
        application_setting.restricted_visibility_levels = [Gitlab::VisibilityLevel::INTERNAL]

        expect(result[:status]).to eq(:success)
        expect(project.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
        expect(project).to be_persisted
      end

      it 'creates project with correct name and description' do
        path = 'administration/monitoring/gitlab_instance_administration_project/index'
        docs_path = Rails.application.routes.url_helpers.help_page_path(path)

        expect(result[:status]).to eq(:success)
        expect(project.name).to eq(described_class::PROJECT_NAME)
        expect(project.description).to eq(
          'This project is automatically generated and will be used to help monitor this GitLab instance. ' \
          "[More information](#{docs_path})"
        )
        expect(File).to exist("doc/#{path}.md")
      end

      it 'adds all admins as maintainers' do
        admin1 = create(:user, :admin)
        admin2 = create(:user, :admin)
        create(:user)

        expect(result[:status]).to eq(:success)
        expect(project.owner).to eq(group)
        expect(group.members.collect(&:user)).to contain_exactly(user, admin1, admin2)
        expect(group.members.collect(&:access_level)).to contain_exactly(
          Gitlab::Access::OWNER,
          Gitlab::Access::MAINTAINER,
          Gitlab::Access::MAINTAINER
        )
      end

      it 'saves the project id' do
        expect(result[:status]).to eq(:success)
        expect(application_setting.instance_administration_project_id).to eq(project.id)
      end

      it 'returns error when saving project ID fails' do
        allow(application_setting).to receive(:save) { false }

        expect(result).to eq(
          status: :error,
          message: 'Could not save project ID',
          last_step: :save_project_id
        )
      end

      context 'when project already exists' do
        let(:existing_group) { create(:group) }
        let(:existing_project) { create(:project, namespace: existing_group) }

        before do
          admin1 = create(:user, :admin)
          admin2 = create(:user, :admin)

          existing_group.add_owner(user)
          existing_group.add_users([admin1, admin2], Gitlab::Access::MAINTAINER)

          application_setting.instance_administration_project_id = existing_project.id
        end

        it 'returns success' do
          expect(result).to include(status: :success)

          expect(Project.count).to eq(1)
          expect(Group.count).to eq(1)
        end
      end

      context 'when local requests from hooks and services are not allowed' do
        before do
          application_setting.allow_local_requests_from_web_hooks_and_services = false
        end

        it_behaves_like 'has prometheus service', 'http://localhost:9090'
      end

      context 'with non default prometheus address' do
        let(:listen_address) { 'https://localhost:9090' }

        let(:prometheus_settings) do
          {
            enable: true,
            listen_address: listen_address
          }
        end

        it_behaves_like 'has prometheus service', 'https://localhost:9090'

        context 'with :9090 symbol' do
          let(:listen_address) { :':9090' }

          it_behaves_like 'has prometheus service', 'http://localhost:9090'
        end

        context 'with 0.0.0.0:9090' do
          let(:listen_address) { '0.0.0.0:9090' }

          it_behaves_like 'has prometheus service', 'http://localhost:9090'
        end
      end

      context 'when prometheus setting is not present in gitlab.yml' do
        before do
          allow(Gitlab.config).to receive(:prometheus).and_raise(Settingslogic::MissingSetting)
        end

        it 'does not fail' do
          expect(result).to include(status: :success)
          expect(project.prometheus_service).to be_nil
        end
      end

      context 'when prometheus setting is nil' do
        before do
          stub_config(prometheus: nil)
        end

        it 'does not fail' do
          expect(result).to include(status: :success)
          expect(project.prometheus_service).to be_nil
        end
      end

      context 'when prometheus setting is disabled in gitlab.yml' do
        let(:prometheus_settings) do
          {
            enable: false,
            listen_address: 'http://localhost:9090'
          }
        end

        it 'does not configure prometheus' do
          expect(result).to include(status: :success)
          expect(project.prometheus_service).to be_nil
        end
      end

      context 'when prometheus listen address is blank in gitlab.yml' do
        let(:prometheus_settings) { { enable: true, listen_address: '' } }

        it 'does not configure prometheus' do
          expect(result).to include(status: :success)
          expect(project.prometheus_service).to be_nil
        end
      end

      context 'when project cannot be created' do
        let(:project) { build(:project) }

        before do
          project.errors.add(:base, "Test error")

          expect_next_instance_of(::Projects::CreateService) do |project_create_service|
            expect(project_create_service).to receive(:execute)
              .and_return(project)
          end
        end

        it 'returns error' do
          expect(subject).to receive(:log_error).and_call_original
          expect(result).to eq(
            status: :error,
            message: 'Could not create project',
            last_step: :create_project
          )
        end
      end

      context 'when user cannot be added to project' do
        before do
          subject.instance_variable_set(:@instance_admins, [user, build(:user, :admin)])
        end

        it 'returns error' do
          expect(subject).to receive(:log_error).and_call_original
          expect(result).to eq(
            status: :error,
            message: 'Could not add admins as members',
            last_step: :add_group_members
          )
        end
      end

      context 'when prometheus manual configuration cannot be saved' do
        let(:prometheus_settings) do
          {
            enable: true,
            listen_address: 'httpinvalid://localhost:9090'
          }
        end

        it 'returns error' do
          expect(subject).to receive(:log_error).and_call_original
          expect(result).to eq(
            status: :error,
            message: 'Could not save prometheus manual configuration',
            last_step: :add_prometheus_manual_configuration
          )
        end
      end
    end
  end
end
