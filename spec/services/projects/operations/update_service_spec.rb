# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Operations::UpdateService do
  let_it_be_with_refind(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:result) { subject.execute }

  subject { described_class.new(project, user, params) }

  describe '#execute' do
    context 'alerting setting' do
      before_all do
        project.add_maintainer(user)
      end

      shared_examples 'no operation' do
        it 'does nothing' do
          expect(result[:status]).to eq(:success)
          expect(project.reload.alerting_setting).to be_nil
        end
      end

      context 'with valid params' do
        let(:params) { { alerting_setting_attributes: alerting_params } }

        shared_examples 'setting creation' do
          it 'creates a setting' do
            expect(project.alerting_setting).to be_nil

            expect(result[:status]).to eq(:success)
            expect(project.reload.alerting_setting).not_to be_nil
          end
        end

        context 'when regenerate_token is not set' do
          let(:alerting_params) { { token: 'some token' } }

          context 'with an existing setting' do
            let!(:alerting_setting) do
              create(:project_alerting_setting, project: project)
            end

            it 'ignores provided token' do
              expect(result[:status]).to eq(:success)
              expect(project.reload.alerting_setting.token)
                .to eq(alerting_setting.token)
            end
          end

          context 'without an existing setting' do
            it_behaves_like 'setting creation'
          end
        end

        context 'when regenerate_token is set' do
          let(:alerting_params) { { regenerate_token: true } }

          context 'with an existing setting' do
            let(:token) { 'some token' }

            let!(:alerting_setting) do
              create(:project_alerting_setting, project: project, token: token)
            end

            it 'regenerates token' do
              expect(result[:status]).to eq(:success)
              expect(project.reload.alerting_setting.token).not_to eq(token)
            end
          end

          context 'without an existing setting' do
            it_behaves_like 'setting creation'

            context 'with insufficient permissions' do
              before do
                project.add_reporter(user)
              end

              it_behaves_like 'no operation'
            end
          end
        end
      end

      context 'with empty params' do
        let(:params) { {} }

        it_behaves_like 'no operation'
      end
    end

    context 'metrics dashboard setting' do
      let(:params) do
        {
          metrics_setting_attributes: {
            external_dashboard_url: 'http://gitlab.com',
            dashboard_timezone: 'utc'
          }
        }
      end

      context 'without existing metrics dashboard setting' do
        it 'creates a setting' do
          expect(result[:status]).to eq(:success)

          expect(project.reload.metrics_setting.external_dashboard_url).to eq(
            'http://gitlab.com'
          )
          expect(project.metrics_setting.dashboard_timezone).to eq('utc')
        end
      end

      context 'with existing metrics dashboard setting' do
        before do
          create(:project_metrics_setting, project: project)
        end

        it 'updates the settings' do
          expect(result[:status]).to eq(:success)

          expect(project.reload.metrics_setting.external_dashboard_url).to eq(
            'http://gitlab.com'
          )
          expect(project.metrics_setting.dashboard_timezone).to eq('utc')
        end
      end

      context 'with blank external_dashboard_url' do
        let(:params) do
          {
            metrics_setting_attributes: {
              external_dashboard_url: '',
              dashboard_timezone: 'utc'
            }
          }
        end

        it 'updates dashboard_timezone' do
          expect(result[:status]).to eq(:success)

          expect(project.reload.metrics_setting.external_dashboard_url).to be(nil)
          expect(project.metrics_setting.dashboard_timezone).to eq('utc')
        end
      end
    end

    context 'error tracking' do
      context 'with existing error tracking setting' do
        let(:params) do
          {
            error_tracking_setting_attributes: {
              enabled: false,
              api_host: 'http://gitlab.com/',
              token: 'token',
              project: {
                slug: 'project',
                name: 'Project',
                organization_slug: 'org',
                organization_name: 'Org'
              }
            }
          }
        end

        before do
          create(:project_error_tracking_setting, project: project)
        end

        it 'updates the settings' do
          expect(result[:status]).to eq(:success)

          project.reload
          expect(project.error_tracking_setting).not_to be_enabled
          expect(project.error_tracking_setting.api_url).to eq(
            'http://gitlab.com/api/0/projects/org/project/'
          )
          expect(project.error_tracking_setting.token).to eq('token')
          expect(project.error_tracking_setting[:project_name]).to eq('Project')
          expect(project.error_tracking_setting[:organization_name]).to eq('Org')
        end

        context 'disable error tracking' do
          before do
            params[:error_tracking_setting_attributes][:api_host] = ''
            params[:error_tracking_setting_attributes][:enabled] = false
          end

          it 'can set api_url to nil' do
            expect(result[:status]).to eq(:success)

            project.reload
            expect(project.error_tracking_setting).not_to be_enabled
            expect(project.error_tracking_setting.api_url).to be_nil
            expect(project.error_tracking_setting.token).to eq('token')
            expect(project.error_tracking_setting[:project_name]).to eq('Project')
            expect(project.error_tracking_setting[:organization_name]).to eq('Org')
          end
        end
      end

      context 'without an existing error tracking setting' do
        let(:params) do
          {
            error_tracking_setting_attributes: {
              enabled: true,
              api_host: 'http://gitlab.com/',
              token: 'token',
              project: {
                slug: 'project',
                name: 'Project',
                organization_slug: 'org',
                organization_name: 'Org'
              }
            }
          }
        end

        it 'creates a setting' do
          expect(result[:status]).to eq(:success)

          expect(project.error_tracking_setting).to be_enabled
          expect(project.error_tracking_setting.api_url).to eq(
            'http://gitlab.com/api/0/projects/org/project/'
          )
          expect(project.error_tracking_setting.token).to eq('token')
          expect(project.error_tracking_setting[:project_name]).to eq('Project')
          expect(project.error_tracking_setting[:organization_name]).to eq('Org')
        end
      end

      context 'partial_update' do
        let(:params) do
          {
            error_tracking_setting_attributes: {
              enabled: true
            }
          }
        end

        context 'with setting' do
          before do
            create(:project_error_tracking_setting, :disabled, project: project)
          end

          it 'service succeeds' do
            expect(result[:status]).to eq(:success)
          end

          it 'updates attributes' do
            expect { result }
              .to change { project.reload.error_tracking_setting.enabled }
              .from(false)
              .to(true)
          end

          it 'only updates enabled attribute' do
            result

            expect(project.error_tracking_setting.previous_changes.keys)
              .to contain_exactly('enabled')
          end
        end

        context 'without setting' do
          it 'does not create a setting' do
            expect(result[:status]).to eq(:error)

            expect(project.reload.error_tracking_setting).to be_nil
          end
        end
      end

      context 'with masked param token' do
        let(:params) do
          {
            error_tracking_setting_attributes: {
              enabled: false,
              token: '*' * 8
            }
          }
        end

        before do
          create(:project_error_tracking_setting, project: project, token: 'token')
        end

        it 'does not update token' do
          expect(result[:status]).to eq(:success)

          expect(project.error_tracking_setting.token).to eq('token')
        end
      end

      context 'with invalid parameters' do
        let(:params) { {} }

        let!(:error_tracking_setting) do
          create(:project_error_tracking_setting, project: project)
        end

        it 'does nothing' do
          expect(result[:status]).to eq(:success)
          expect(project.reload.error_tracking_setting)
            .to eq(error_tracking_setting)
        end
      end
    end

    context 'with inappropriate params' do
      let(:params) { { name: '' } }

      let!(:original_name) { project.name }

      it 'ignores params' do
        expect(result[:status]).to eq(:success)
        expect(project.reload.name).to eq(original_name)
      end
    end

    context 'grafana integration' do
      let(:params) do
        {
          grafana_integration_attributes: {
            grafana_url: 'http://new.grafana.com',
            token: 'VerySecureToken='
          }
        }
      end

      context 'without existing grafana integration' do
        it 'creates an integration' do
          expect(result[:status]).to eq(:success)

          expected_attrs = params[:grafana_integration_attributes]
          integration = project.reload.grafana_integration

          expect(integration.grafana_url).to eq(expected_attrs[:grafana_url])
          expect(integration.send(:token)).to eq(expected_attrs[:token])
        end
      end

      context 'with an existing grafana integration' do
        before do
          create(:grafana_integration, project: project)
        end

        it 'updates the settings' do
          expect(result[:status]).to eq(:success)

          expected_attrs = params[:grafana_integration_attributes]
          integration = project.reload.grafana_integration

          expect(integration.grafana_url).to eq(expected_attrs[:grafana_url])
          expect(integration.send(:token)).to eq(expected_attrs[:token])
        end

        context 'with all grafana attributes blank in params' do
          let(:params) do
            {
              grafana_integration_attributes: {
                grafana_url: '',
                token: ''
              }
            }
          end

          it 'destroys the metrics_setting entry in DB' do
            expect(result[:status]).to eq(:success)

            expect(project.reload.grafana_integration).to be_nil
          end
        end
      end
    end

    context 'prometheus integration' do
      context 'prometheus params were passed into service' do
        let(:prometheus_integration) do
          build_stubbed(:prometheus_integration, project: project, properties: {
            api_url: "http://example.prometheus.com",
            manual_configuration: "0"
          })
        end

        let(:params) do
          {
            prometheus_integration_attributes: {
              'api_url' => 'http://new.prometheus.com',
              'manual_configuration' => '1'
            }
          }
        end

        it 'uses Project#find_or_initialize_integration to include instance defined defaults and pass them to Projects::UpdateService', :aggregate_failures do
          project_update_service = double(Projects::UpdateService)

          expect(project)
            .to receive(:find_or_initialize_integration)
            .with('prometheus')
            .and_return(prometheus_integration)
          expect(Projects::UpdateService).to receive(:new) do |project_arg, user_arg, update_params_hash|
            expect(project_arg).to eq project
            expect(user_arg).to eq user
            expect(update_params_hash[:prometheus_integration_attributes]).to include('properties' => { 'api_url' => 'http://new.prometheus.com', 'manual_configuration' => '1' })
            expect(update_params_hash[:prometheus_integration_attributes]).not_to include(*%w(id project_id created_at updated_at))
          end.and_return(project_update_service)
          expect(project_update_service).to receive(:execute)

          subject.execute
        end
      end

      context 'when prometheus params are not passed into service' do
        let(:params) { { something: :else } }

        it 'does not pass any prometheus params into Projects::UpdateService', :aggregate_failures do
          project_update_service = double(Projects::UpdateService)

          expect(project).not_to receive(:find_or_initialize_integration)
          expect(Projects::UpdateService)
            .to receive(:new)
            .with(project, user, {})
            .and_return(project_update_service)
          expect(project_update_service).to receive(:execute)

          subject.execute
        end
      end
    end

    context 'tracing setting' do
      context 'with valid params' do
        let(:params) do
          {
            tracing_setting_attributes: {
              external_url: 'http://some-url.com'
            }
          }
        end

        context 'with an existing setting' do
          before do
            create(:project_tracing_setting, project: project)
          end

          shared_examples 'setting deletion' do
            let!(:original_params) { params.deep_dup }

            it 'deletes the setting' do
              expect(result[:status]).to eq(:success)
              expect(project.reload.tracing_setting).to be_nil
            end

            it 'does not modify original params' do
              subject.execute

              expect(params).to eq(original_params)
            end
          end

          it 'updates the setting' do
            expect(project.tracing_setting).not_to be_nil

            expect(result[:status]).to eq(:success)
            expect(project.reload.tracing_setting.external_url)
              .to eq('http://some-url.com')
          end

          context 'with missing external_url' do
            before do
              params[:tracing_setting_attributes].delete(:external_url)
            end

            it_behaves_like 'setting deletion'
          end

          context 'with empty external_url' do
            before do
              params[:tracing_setting_attributes][:external_url] = ''
            end

            it_behaves_like 'setting deletion'
          end

          context 'with blank external_url' do
            before do
              params[:tracing_setting_attributes][:external_url] = ' '
            end

            it_behaves_like 'setting deletion'
          end
        end

        context 'without an existing setting' do
          it 'creates a setting' do
            expect(project.tracing_setting).to be_nil

            expect(result[:status]).to eq(:success)
            expect(project.reload.tracing_setting.external_url)
              .to eq('http://some-url.com')
          end
        end
      end

      context 'with empty params' do
        let(:params) { {} }

        let!(:tracing_setting) do
          create(:project_tracing_setting, project: project)
        end

        it 'does nothing' do
          expect(result[:status]).to eq(:success)
          expect(project.reload.tracing_setting).to eq(tracing_setting)
        end
      end
    end
  end
end
