# frozen_string_literal: true

require 'spec_helper'

describe SelfMonitoring::Project::CreateService do
  describe '#execute' do
    let(:result) { subject.execute }

    let(:prometheus_settings) do
      OpenStruct.new(
        enable: true,
        listen_address: 'localhost:9090'
      )
    end

    before do
      allow(Gitlab.config).to receive(:prometheus).and_return(prometheus_settings)
    end

    context 'without admin users' do
      it 'returns error' do
        expect(subject).to receive(:log_error).and_call_original
        expect(result).to eq(
          status: :error,
          message: 'No active admin user found',
          failed_step: :validate_admins
        )
      end
    end

    context 'with admin users' do
      let(:project) { result[:project] }
      let(:group) { result[:group] }
      let(:application_setting) { Gitlab::CurrentSettings.current_application_settings }

      let!(:user) { create(:user, :admin) }

      before do
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

      it 'creates group' do
        expect(result[:status]).to eq(:success)
        expect(group).to be_persisted
        expect(group.name).to eq(described_class::GROUP_NAME)
        expect(group.path).to start_with(described_class::GROUP_PATH)
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
        expect(result[:status]).to eq(:success)
        expect(project.name).to eq(described_class::PROJECT_NAME)
        expect(project.description).to eq(described_class::PROJECT_DESCRIPTION)
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
        allow(application_setting).to receive(:update) { false }

        expect(result[:status]).to eq(:error)
        expect(result[:failed_step]).to eq(:save_project_id)
        expect(result[:message]).to eq('Could not save project ID')
      end

      it 'does not fail when a project already exists' do
        expect(result[:status]).to eq(:success)

        second_result = subject.execute

        expect(second_result[:status]).to eq(:success)
        expect(second_result[:project]).to eq(project)
        expect(second_result[:group]).to eq(group)
      end

      context 'when local requests from hooks and services are not allowed' do
        before do
          application_setting.allow_local_requests_from_web_hooks_and_services = false
        end

        it_behaves_like 'has prometheus service', 'http://localhost:9090'

        it 'does not overwrite the existing whitelist' do
          application_setting.outbound_local_requests_whitelist = ['example.com']

          expect(result[:status]).to eq(:success)
          expect(application_setting.outbound_local_requests_whitelist).to contain_exactly(
            'example.com', 'localhost'
          )
        end
      end

      context 'with non default prometheus address' do
        before do
          prometheus_settings.listen_address = 'https://localhost:9090'
        end

        it_behaves_like 'has prometheus service', 'https://localhost:9090'
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

      context 'when prometheus setting is disabled in gitlab.yml' do
        before do
          prometheus_settings.enable = false
        end

        it 'does not configure prometheus' do
          expect(result).to include(status: :success)
          expect(project.prometheus_service).to be_nil
        end
      end

      context 'when prometheus listen address is blank in gitlab.yml' do
        before do
          prometheus_settings.listen_address = ''
        end

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
          expect(result).to eq({
            status: :error,
            message: 'Could not create project',
            failed_step: :create_project
          })
        end
      end

      context 'when user cannot be added to project' do
        before do
          subject.instance_variable_set(:@instance_admins, [user, build(:user, :admin)])
        end

        it 'returns error' do
          expect(subject).to receive(:log_error).and_call_original
          expect(result).to eq({
            status: :error,
            message: 'Could not add admins as members',
            failed_step: :add_group_members
          })
        end
      end

      context 'when prometheus manual configuration cannot be saved' do
        before do
          prometheus_settings.listen_address = 'httpinvalid://localhost:9090'
        end

        it 'returns error' do
          expect(subject).to receive(:log_error).and_call_original
          expect(result).to eq(
            status: :error,
            message: 'Could not save prometheus manual configuration',
            failed_step: :add_prometheus_manual_configuration
          )
        end
      end
    end
  end
end
