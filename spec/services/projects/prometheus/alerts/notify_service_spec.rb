# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Prometheus::Alerts::NotifyService do
  include PrometheusHelpers

  let_it_be(:project, reload: true) { create(:project) }

  let(:service) { described_class.new(project, nil, payload) }
  let(:token_input) { 'token' }

  let!(:setting) do
    create(:project_incident_management_setting, project: project, send_email: true, create_issue: true)
  end

  let(:subject) { service.execute(token_input) }

  context 'with valid payload' do
    let_it_be(:alert_firing) { create(:prometheus_alert, project: project) }
    let_it_be(:alert_resolved) { create(:prometheus_alert, project: project) }
    let_it_be(:cluster) { create(:cluster, :provided_by_user, projects: [project]) }
    let(:payload_raw) { prometheus_alert_payload(firing: [alert_firing], resolved: [alert_resolved]) }
    let(:payload) { ActionController::Parameters.new(payload_raw).permit! }
    let(:payload_alert_firing) { payload_raw['alerts'].first }
    let(:token) { 'token' }

    context 'with environment specific clusters' do
      let(:prd_cluster) do
        cluster
      end

      let(:stg_cluster) do
        create(:cluster, :provided_by_user, projects: [project], enabled: true, environment_scope: 'stg/*')
      end

      let(:stg_environment) do
        create(:environment, project: project, name: 'stg/1')
      end

      let(:alert_firing) do
        create(:prometheus_alert, project: project, environment: stg_environment)
      end

      before do
        create(:clusters_applications_prometheus, :installed,
               cluster: prd_cluster, alert_manager_token: token)
        create(:clusters_applications_prometheus, :installed,
               cluster: stg_cluster, alert_manager_token: nil)
      end

      context 'without token' do
        let(:token_input) { nil }

        it_behaves_like 'Alert Notification Service sends notification email'
      end

      context 'with token' do
        it_behaves_like 'Alert Notification Service sends no notifications', http_status: :unauthorized
      end
    end

    context 'with project specific cluster' do
      using RSpec::Parameterized::TableSyntax

      where(:cluster_enabled, :status, :configured_token, :token_input, :result) do
        true  | :installed | token | token | :success
        true  | :installed | nil   | nil   | :success
        true  | :updated   | token | token | :success
        true  | :updating  | token | token | :failure
        true  | :installed | token | 'x'   | :failure
        true  | :installed | nil   | token | :failure
        true  | :installed | token | nil   | :failure
        true  | nil        | token | token | :failure
        false | :installed | token | token | :failure
      end

      with_them do
        before do
          cluster.update!(enabled: cluster_enabled)

          if status
            create(:clusters_applications_prometheus, status,
                   cluster: cluster,
                   alert_manager_token: configured_token)
          end
        end

        case result = params[:result]
        when :success
          it_behaves_like 'Alert Notification Service sends notification email'
        when :failure
          it_behaves_like 'Alert Notification Service sends no notifications', http_status: :unauthorized
        else
          raise "invalid result: #{result.inspect}"
        end
      end
    end

    context 'without project specific cluster' do
      let!(:cluster) { create(:cluster, enabled: true) }

      it_behaves_like 'Alert Notification Service sends no notifications', http_status: :unauthorized
    end

    context 'with manual prometheus installation' do
      using RSpec::Parameterized::TableSyntax

      where(:alerting_setting, :configured_token, :token_input, :result) do
        true  | token | token | :success
        true  | token | 'x'   | :failure
        true  | token | nil   | :failure
        false | nil   | nil   | :success
        false | nil   | token | :failure
      end

      with_them do
        let(:alert_manager_token) { token_input }

        before do
          create(:prometheus_service, project: project)

          if alerting_setting
            create(:project_alerting_setting,
                   project: project,
                   token: configured_token)
          end
        end

        case result = params[:result]
        when :success
          it_behaves_like 'Alert Notification Service sends notification email'
        when :failure
          it_behaves_like 'Alert Notification Service sends no notifications', http_status: :unauthorized
        else
          raise "invalid result: #{result.inspect}"
        end
      end
    end

    context 'with generic alerts integration' do
      using RSpec::Parameterized::TableSyntax

      where(:alerts_service, :token, :result) do
        :active   | :valid    | :success
        :active   | :invalid  | :failure
        :active   | nil       | :failure
        :inactive | :valid    | :failure
        nil       | nil       | :failure
      end

      with_them do
        let(:valid) { project.alerts_service.token }
        let(:invalid) { 'invalid token' }
        let(:token_input) { public_send(token) if token }

        before do
          if alerts_service
            create(:alerts_service, alerts_service, project: project)
          end
        end

        case result = params[:result]
        when :success
          it_behaves_like 'Alert Notification Service sends notification email'
        when :failure
          it_behaves_like 'Alert Notification Service sends no notifications', http_status: :unauthorized
        else
          raise "invalid result: #{result.inspect}"
        end
      end
    end

    context 'alert emails' do
      before do
        create(:prometheus_service, project: project)
        create(:project_alerting_setting, project: project, token: token)
      end

      context 'when incident_management_setting does not exist' do
        let!(:setting) { nil }

        it 'does not send notification email', :sidekiq_might_not_need_inline do
          expect_any_instance_of(NotificationService)
            .not_to receive(:async)

          expect(subject).to be_success
        end
      end

      context 'when incident_management_setting.send_email is true' do
        it_behaves_like 'Alert Notification Service sends notification email'
      end

      context 'incident_management_setting.send_email is false' do
        let!(:setting) do
          create(:project_incident_management_setting, send_email: false, project: project)
        end

        it 'does not send notification' do
          expect(NotificationService).not_to receive(:new)

          expect(subject).to be_success
        end
      end
    end

    context 'process Alert Management alerts' do
      let(:process_service) { instance_double(AlertManagement::ProcessPrometheusAlertService) }

      before do
        create(:prometheus_service, project: project)
        create(:project_alerting_setting, project: project, token: token)
      end

      context 'with multiple firing alerts and resolving alerts' do
        let(:payload_raw) do
          prometheus_alert_payload(firing: [alert_firing, alert_firing], resolved: [alert_resolved])
        end

        it 'processes Prometheus alerts' do
          expect(AlertManagement::ProcessPrometheusAlertService)
            .to receive(:new)
            .with(project, nil, kind_of(Hash))
            .exactly(3).times
            .and_return(process_service)
          expect(process_service).to receive(:execute).exactly(3).times

          subject
        end
      end
    end
  end

  context 'with invalid payload' do
    context 'when payload is not processable' do
      let(:payload) { {} }

      before do
        allow(described_class).to receive(:processable?).with(payload)
          .and_return(false)
      end

      it_behaves_like 'Alert Notification Service sends no notifications', http_status: :unprocessable_entity
    end

    context 'when the payload is too big' do
      let(:payload) { { 'the-payload-is-too-big' => true } }
      let(:deep_size_object) { instance_double(Gitlab::Utils::DeepSize, valid?: false) }

      before do
        allow(Gitlab::Utils::DeepSize).to receive(:new).and_return(deep_size_object)
      end

      it_behaves_like 'Alert Notification Service sends no notifications', http_status: :bad_request

      it 'does not process Prometheus alerts' do
        expect(AlertManagement::ProcessPrometheusAlertService)
          .not_to receive(:new)

        subject
      end
    end
  end

  describe '.processable?' do
    let(:valid_payload) { prometheus_alert_payload }

    subject { described_class.processable?(payload) }

    context 'with valid payload' do
      let(:payload) { valid_payload }

      it { is_expected.to eq(true) }

      context 'containing unrelated keys' do
        let(:payload) { valid_payload.merge('unrelated' => 'key') }

        it { is_expected.to eq(true) }
      end
    end

    context 'with invalid payload' do
      where(:missing_key) do
        described_class::REQUIRED_PAYLOAD_KEYS.to_a
      end

      with_them do
        let(:payload) { valid_payload.except(missing_key) }

        it { is_expected.to eq(false) }
      end
    end

    context 'with unsupported version' do
      let(:payload) { valid_payload.merge('version' => '5') }

      it { is_expected.to eq(false) }
    end
  end
end
