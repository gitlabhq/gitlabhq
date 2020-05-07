# frozen_string_literal: true

require 'spec_helper'

describe Projects::Prometheus::Alerts::NotifyService do
  let_it_be(:project, reload: true) { create(:project) }

  let(:service) { described_class.new(project, nil, payload) }
  let(:token_input) { 'token' }

  let!(:setting) do
    create(:project_incident_management_setting, project: project, send_email: true, create_issue: true)
  end

  let(:subject) { service.execute(token_input) }

  before do
    # We use `let_it_be(:project)` so we make sure to clear caches
    project.clear_memoization(:licensed_feature_available)
  end

  shared_examples 'sends notification email' do
    let(:notification_service) { spy }

    it 'sends a notification for firing alerts only' do
      expect(NotificationService)
        .to receive(:new)
        .and_return(notification_service)

      expect(notification_service)
        .to receive_message_chain(:async, :prometheus_alerts_fired)

      expect(subject).to be_success
    end
  end

  shared_examples 'processes incident issues' do |amount|
    let(:create_incident_service) { spy }

    it 'processes issues' do
      expect(IncidentManagement::ProcessPrometheusAlertWorker)
        .to receive(:perform_async)
        .with(project.id, kind_of(Hash))
        .exactly(amount).times

      Sidekiq::Testing.inline! do
        expect(subject).to be_success
      end
    end
  end

  shared_examples 'does not process incident issues' do
    it 'does not process issues' do
      expect(IncidentManagement::ProcessPrometheusAlertWorker)
        .not_to receive(:perform_async)

      expect(subject).to be_success
    end
  end

  shared_examples 'persists events' do
    let(:create_events_service) { spy }

    it 'persists events' do
      expect(Projects::Prometheus::Alerts::CreateEventsService)
        .to receive(:new)
        .and_return(create_events_service)

      expect(create_events_service)
        .to receive(:execute)

      expect(subject).to be_success
    end
  end

  shared_examples 'notifies alerts' do
    it_behaves_like 'sends notification email'
    it_behaves_like 'persists events'
  end

  shared_examples 'no notifications' do |http_status:|
    let(:notification_service) { spy }
    let(:create_events_service) { spy }

    it 'does not notify' do
      expect(notification_service).not_to receive(:async)
      expect(create_events_service).not_to receive(:execute)

      expect(subject).to be_error
      expect(subject.http_status).to eq(http_status)
    end
  end

  context 'with valid payload' do
    let(:alert_firing) { create(:prometheus_alert, project: project) }
    let(:alert_resolved) { create(:prometheus_alert, project: project) }
    let(:payload_raw) { payload_for(firing: [alert_firing], resolved: [alert_resolved]) }
    let(:payload) { ActionController::Parameters.new(payload_raw).permit! }
    let(:payload_alert_firing) { payload_raw['alerts'].first }
    let(:token) { 'token' }

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
          cluster = create(:cluster, :provided_by_user,
                           projects: [project],
                           enabled: cluster_enabled)

          if status
            create(:clusters_applications_prometheus, status,
                   cluster: cluster,
                   alert_manager_token: configured_token)
          end
        end

        case result = params[:result]
        when :success
          it_behaves_like 'notifies alerts'
        when :failure
          it_behaves_like 'no notifications', http_status: :unauthorized
        else
          raise "invalid result: #{result.inspect}"
        end
      end
    end

    context 'without project specific cluster' do
      let!(:cluster) { create(:cluster, enabled: true) }

      it_behaves_like 'no notifications', http_status: :unauthorized
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
          it_behaves_like 'notifies alerts'
        when :failure
          it_behaves_like 'no notifications', http_status: :unauthorized
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

        it_behaves_like 'persists events'

        it 'does not send notification email', :sidekiq_might_not_need_inline do
          expect_any_instance_of(NotificationService)
            .not_to receive(:async)

          expect(subject).to be_success
        end
      end

      context 'when incident_management_setting.send_email is true' do
        it_behaves_like 'notifies alerts'
      end

      context 'incident_management_setting.send_email is false' do
        let!(:setting) do
          create(:project_incident_management_setting, send_email: false, project: project)
        end

        it_behaves_like 'persists events'

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

      context 'when alert_management_minimal feature enabled' do
        before do
          stub_feature_flags(alert_management_minimal: true)
        end

        context 'with multiple firing alerts and resolving alerts' do
          let(:payload_raw) do
            payload_for(firing: [alert_firing, alert_firing], resolved: [alert_resolved])
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

      context 'when alert_management_minimal feature disabled' do
        before do
          stub_feature_flags(alert_management_minimal: false)
        end

        it 'does not process Prometheus alerts' do
          expect(AlertManagement::ProcessPrometheusAlertService)
            .not_to receive(:new)

          subject
        end
      end
    end

    context 'process incident issues' do
      before do
        create(:prometheus_service, project: project)
        create(:project_alerting_setting, project: project, token: token)
      end

      context 'with create_issue setting enabled' do
        before do
          setting.update!(create_issue: true)
        end

        it_behaves_like 'processes incident issues', 2

        context 'multiple firing alerts' do
          let(:payload_raw) do
            payload_for(firing: [alert_firing, alert_firing], resolved: [])
          end

          it_behaves_like 'processes incident issues', 2
        end

        context 'without firing alerts' do
          let(:payload_raw) do
            payload_for(firing: [], resolved: [alert_resolved])
          end

          it_behaves_like 'processes incident issues', 1
        end
      end

      context 'with create_issue setting disabled' do
        before do
          setting.update!(create_issue: false)
        end

        it_behaves_like 'does not process incident issues'
      end
    end
  end

  context 'with invalid payload' do
    context 'without version' do
      let(:payload) { {} }

      it_behaves_like 'no notifications', http_status: :unprocessable_entity
    end

    context 'when version is not "4"' do
      let(:payload) { { 'version' => '5' } }

      it_behaves_like 'no notifications', http_status: :unprocessable_entity
    end

    context 'with missing alerts' do
      let(:payload) { { 'version' => '4' } }

      it_behaves_like 'no notifications', http_status: :unauthorized
    end

    context 'when the payload is too big' do
      let(:payload) { { 'the-payload-is-too-big' => true } }
      let(:deep_size_object) { instance_double(Gitlab::Utils::DeepSize, valid?: false) }

      before do
        allow(Gitlab::Utils::DeepSize).to receive(:new).and_return(deep_size_object)
      end

      it_behaves_like 'no notifications', http_status: :bad_request

      it 'does not process Prometheus alerts' do
        expect(AlertManagement::ProcessPrometheusAlertService)
          .not_to receive(:new)

        subject
      end

      it 'does not process issues' do
        expect(IncidentManagement::ProcessPrometheusAlertWorker)
          .not_to receive(:perform_async)

        subject
      end
    end
  end

  private

  def payload_for(firing: [], resolved: [])
    status = firing.any? ? 'firing' : 'resolved'
    alerts = firing + resolved
    alert_name = alerts.first.title
    prometheus_metric_id = alerts.first.prometheus_metric_id.to_s

    alerts_map = \
      firing.map { |alert| map_alert_payload('firing', alert) } +
      resolved.map { |alert| map_alert_payload('resolved', alert) }

    # See https://prometheus.io/docs/alerting/configuration/#%3Cwebhook_config%3E
    {
      'version' => '4',
      'receiver' => 'gitlab',
      'status' => status,
      'alerts' => alerts_map,
      'groupLabels' => {
        'alertname' => alert_name
      },
      'commonLabels' => {
        'alertname' => alert_name,
        'gitlab' => 'hook',
        'gitlab_alert_id' => prometheus_metric_id
      },
      'commonAnnotations' => {},
      'externalURL' => '',
      'groupKey' => "{}:{alertname=\'#{alert_name}\'}"
    }
  end

  def map_alert_payload(status, alert)
    {
      'status' => status,
      'labels' => {
        'alertname' => alert.title,
        'gitlab' => 'hook',
        'gitlab_alert_id' => alert.prometheus_metric_id.to_s
      },
      'annotations' => {},
      'startsAt' => '2018-09-24T08:57:31.095725221Z',
      'endsAt' => '0001-01-01T00:00:00Z',
      'generatorURL' => 'http://prometheus-prometheus-server-URL'
    }
  end
end
