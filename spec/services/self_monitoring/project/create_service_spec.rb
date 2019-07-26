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

      let!(:user) { create(:user, :admin) }

      before do
        allow(ApplicationSetting)
          .to receive(:current)
          .and_return(
            ApplicationSetting.build_from_defaults(allow_local_requests_from_web_hooks_and_services: true)
          )
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

      it 'creates project with internal visibility' do
        expect(result[:status]).to eq(:success)
        expect(project.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
        expect(project).to be_persisted
      end

      it 'creates project with internal visibility even when internal visibility is restricted' do
        stub_application_setting(restricted_visibility_levels: [Gitlab::VisibilityLevel::INTERNAL])

        expect(result[:status]).to eq(:success)
        expect(project.visibility_level).to eq(Gitlab::VisibilityLevel::INTERNAL)
        expect(project).to be_persisted
      end

      it 'creates project with correct name and description' do
        expect(result[:status]).to eq(:success)
        expect(project.name).to eq(described_class::DEFAULT_NAME)
        expect(project.description).to eq(described_class::DEFAULT_DESCRIPTION)
      end

      it 'adds all admins as maintainers' do
        admin1 = create(:user, :admin)
        admin2 = create(:user, :admin)
        create(:user)

        expect(result[:status]).to eq(:success)
        expect(project.owner).to eq(user)
        expect(project.members.collect(&:user)).to contain_exactly(user, admin1, admin2)
        expect(project.members.collect(&:access_level)).to contain_exactly(
          Gitlab::Access::MAINTAINER,
          Gitlab::Access::MAINTAINER,
          Gitlab::Access::MAINTAINER
        )
      end

      context 'when local requests from hooks and services are not allowed' do
        before do
          allow(ApplicationSetting)
            .to receive(:current)
            .and_return(
              ApplicationSetting.build_from_defaults(allow_local_requests_from_hooks_and_services: false)
            )
        end

        it_behaves_like 'has prometheus service', 'http://localhost:9090'
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
            failed_step: :add_project_members
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
