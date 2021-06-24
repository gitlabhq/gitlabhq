# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DatabaseImporters::SelfMonitoring::Project::CreateService do
  describe '#execute' do
    let(:result) { subject.execute }

    let(:prometheus_settings) do
      {
        enabled: true,
        server_address: 'localhost:9090'
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
        expect(result).to eq(
          status: :error,
          message: 'No active admin user found',
          last_step: :create_group
        )

        expect(Project.count).to eq(0)
        expect(Group.count).to eq(0)
      end
    end

    context 'with application settings and admin users', :request_store do
      let(:project) { result[:project] }
      let(:group) { result[:group] }
      let(:application_setting) { Gitlab::CurrentSettings.current_application_settings }

      let!(:user) { create(:user, :admin) }

      before do
        stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')

        application_setting.update(allow_local_requests_from_web_hooks_and_services: true)
      end

      shared_examples 'has prometheus integration' do |server_address|
        it do
          expect(result[:status]).to eq(:success)

          prometheus = project.prometheus_integration
          expect(prometheus).not_to eq(nil)
          expect(prometheus.api_url).to eq(server_address)
          expect(prometheus.active).to eq(true)
          expect(prometheus.manual_configuration).to eq(true)
        end
      end

      it_behaves_like 'has prometheus integration', 'http://localhost:9090'

      it 'is idempotent' do
        result1 = subject.execute
        expect(result1[:status]).to eq(:success)

        result2 = subject.execute
        expect(result2[:status]).to eq(:success)
      end

      it "tracks successful install" do
        expect(::Gitlab::Tracking).to receive(:event).with("instance_administrators_group", "group_created", namespace: project.namespace)
        expect(::Gitlab::Tracking).to receive(:event).with('self_monitoring', 'project_created', project: project, namespace: project.namespace)

        subject.execute
      end

      it 'creates group' do
        expect(result[:status]).to eq(:success)
        expect(group).to be_persisted
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
        path = 'administration/monitoring/gitlab_self_monitoring_project/index'
        docs_path = Rails.application.routes.url_helpers.help_page_path(path)

        expect(result[:status]).to eq(:success)
        expect(project.name).to eq(described_class::PROJECT_NAME)
        expect(project.description).to eq(
          'This project is automatically generated and helps monitor this GitLab instance. ' \
          "[Learn more](#{docs_path})."
        )
        expect(File).to exist("doc/#{path}.md")
      end

      it 'creates project with group as owner' do
        expect(result[:status]).to eq(:success)
        expect(project.owner).to eq(group)
      end

      it 'saves the project id' do
        expect(result[:status]).to eq(:success)
        expect(application_setting.reload.self_monitoring_project_id).to eq(project.id)
      end

      it 'creates a Prometheus integration' do
        expect(result[:status]).to eq(:success)

        integrations = result[:project].reload.integrations

        expect(integrations.count).to eq(1)
        # Ensures Integrations::Prometheus#self_monitoring_project? is true
        expect(integrations.first.allow_local_api_url?).to be_truthy
      end

      it 'creates an environment for the project' do
        expect(project.default_environment.name).to eq('production')
      end

      context 'when the environment creation fails' do
        let(:environment) { build(:environment, name: 'production') }

        it 'returns error' do
          allow(Environment).to receive(:new).and_return(environment)
          allow(environment).to receive(:save).and_return(false)

          expect(result).to eq(
            status: :error,
            message: 'Could not create environment',
            last_step: :create_environment
          )
        end
      end

      it 'returns error when saving project ID fails' do
        allow(subject.application_settings).to receive(:update).and_call_original
        allow(subject.application_settings).to receive(:update)
          .with(self_monitoring_project_id: anything)
          .and_return(false)

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
          application_setting.update(instance_administrators_group_id: existing_group.id,
                                     self_monitoring_project_id: existing_project.id)
        end

        it 'returns success' do
          expect(result).to include(status: :success)

          expect(Project.count).to eq(1)
          expect(Group.count).to eq(1)
        end
      end

      context 'when local requests from hooks and integrations are not allowed' do
        before do
          application_setting.update(allow_local_requests_from_web_hooks_and_services: false)
        end

        it_behaves_like 'has prometheus integration', 'http://localhost:9090'
      end

      context 'with non default prometheus address' do
        let(:server_address) { 'https://localhost:9090' }

        let(:prometheus_settings) do
          {
            enabled: true,
            server_address: server_address
          }
        end

        it_behaves_like 'has prometheus integration', 'https://localhost:9090'

        context 'with :9090 symbol' do
          let(:server_address) { :':9090' }

          it_behaves_like 'has prometheus integration', 'http://localhost:9090'
        end

        context 'with 0.0.0.0:9090' do
          let(:server_address) { '0.0.0.0:9090' }

          it_behaves_like 'has prometheus integration', 'http://localhost:9090'
        end
      end

      context 'when prometheus setting is not present in gitlab.yml' do
        before do
          allow(Gitlab.config).to receive(:prometheus).and_raise(Settingslogic::MissingSetting)
        end

        it 'does not fail' do
          expect(result).to include(status: :success)
          expect(project.prometheus_integration).to be_nil
        end
      end

      context 'when prometheus setting is nil' do
        before do
          stub_config(prometheus: nil)
        end

        it 'does not fail' do
          expect(result).to include(status: :success)
          expect(project.prometheus_integration).to be_nil
        end
      end

      context 'when prometheus setting is disabled in gitlab.yml' do
        let(:prometheus_settings) do
          {
            enabled: false,
            server_address: 'http://localhost:9090'
          }
        end

        it 'does not configure prometheus' do
          expect(result).to include(status: :success)
          expect(project.prometheus_integration).to be_nil
        end
      end

      context 'when prometheus server address is blank in gitlab.yml' do
        let(:prometheus_settings) { { enabled: true, server_address: '' } }

        it 'does not configure prometheus' do
          expect(result).to include(status: :success)
          expect(project.prometheus_integration).to be_nil
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

      context 'when prometheus manual configuration cannot be saved' do
        let(:prometheus_settings) do
          {
            enabled: true,
            server_address: 'httpinvalid://localhost:9090'
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
