# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Prometheus::Alerts::NotifyService, feature_category: :incident_management do
  include PrometheusHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:project) { create(:project) }
  let_it_be_with_refind(:setting) do
    create(:project_incident_management_setting, project: project, send_email: true, create_issue: true)
  end

  let(:service) { described_class.new(project, payload) }
  let(:token_input) { 'token' }

  subject { service.execute(token_input) }

  context 'with valid payload' do
    let(:payload_raw) { prometheus_alert_payload(firing: ['Alert A'], resolved: ['Alert B']) }
    let(:payload) { ActionController::Parameters.new(payload_raw).permit! }
    let(:payload_alert_firing) { payload_raw['alerts'].first }
    let(:token) { 'token' }
    let(:source) { 'Prometheus' }

    context 'with manual prometheus installation' do
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
          create(:prometheus_integration, project: project)

          if alerting_setting
            create(
              :project_alerting_setting,
              project: project,
              token: configured_token
            )
          end
        end

        case result = params[:result]
        when :success
          it_behaves_like 'processes one firing and one resolved prometheus alerts'
        when :failure
          it_behaves_like 'alerts service responds with an error and takes no actions', :unauthorized
        else
          raise "invalid result: #{result.inspect}"
        end
      end
    end

    context 'with HTTP integration' do
      where(:active, :token, :result) do
        :active   | :valid    | :success
        :active   | :invalid  | :failure
        :active   | nil       | :failure
        :inactive | :valid    | :failure
        nil       | nil       | :failure
      end

      with_them do
        let(:valid) { integration.token }
        let(:invalid) { 'invalid token' }
        let(:token_input) { public_send(token) if token }
        let(:integration) { create(:alert_management_http_integration, active, project: project) if active }

        subject { service.execute(token_input, integration) }

        case result = params[:result]
        when :success
          it_behaves_like 'processes one firing and one resolved prometheus alerts'
        when :failure
          it_behaves_like 'alerts service responds with an error and takes no actions', :unauthorized
        else
          raise "invalid result: #{result.inspect}"
        end
      end

      context 'with simultaneous manual configuration' do
        let_it_be(:alerting_setting) { create(:project_alerting_setting, :with_http_integration, project: project) }
        let_it_be(:old_prometheus_integration) { create(:prometheus_integration, project: project) }
        let_it_be(:integration) { project.alert_management_http_integrations.last! }

        subject { service.execute(integration.token, integration) }

        it_behaves_like 'processes one firing and one resolved prometheus alerts'

        context 'when HTTP integration is inactive' do
          before do
            integration.update!(active: false)
          end

          it_behaves_like 'alerts service responds with an error and takes no actions', :unauthorized
        end
      end
    end

    context 'incident settings' do
      before do
        create(:prometheus_integration, project: project)
        create(:project_alerting_setting, project: project, token: token)
      end

      it_behaves_like 'processes one firing and one resolved prometheus alerts'

      context 'when incident_management_setting does not exist' do
        before do
          setting.destroy!
        end

        it { is_expected.to be_success }

        include_examples 'does not send alert notification emails'
        include_examples 'does not process incident issues'
      end

      context 'incident_management_setting.send_email is false' do
        before do
          setting.update!(send_email: false)
        end

        it { is_expected.to be_success }

        include_examples 'does not send alert notification emails'
      end

      context 'incident_management_setting.create_issue is false' do
        before do
          setting.update!(create_issue: false)
        end

        it { is_expected.to be_success }

        include_examples 'does not process incident issues'
      end
    end

    context 'process Alert Management alerts' do
      let(:integration) { build_stubbed(:alert_management_http_integration, project: project, token: token) }

      subject { service.execute(token_input, integration) }

      context 'with multiple firing alerts and resolving alerts' do
        let(:payload_raw) do
          prometheus_alert_payload(firing: ['Alert A', 'Alert A'], resolved: ['Alert B'])
        end

        it 'processes Prometheus alerts' do
          expect(AlertManagement::ProcessPrometheusAlertService)
            .to receive(:new)
            .with(project, kind_of(Hash), integration: integration)
            .exactly(3).times
            .and_call_original

          subject
        end
      end
    end

    context 'when payload exceeds max amount of processable alerts' do
      # We are defining 2 alerts in payload_raw above
      let(:max_alerts) { 1 }
      let(:fingerprint) { prometheus_alert_payload_fingerprint('Alert A') }

      before do
        stub_const("#{described_class}::PROCESS_MAX_ALERTS", max_alerts)

        create(:prometheus_integration, project: project)
        create(:project_alerting_setting, project: project, token: token)
        create(:alert_management_alert, project: project, fingerprint: fingerprint)

        allow(Gitlab::AppLogger).to receive(:warn)
      end

      shared_examples 'process truncated alerts' do
        it 'returns 201 but skips processing and logs a warning', :aggregate_failures do
          expect(subject).to be_success
          expect(subject.payload).to eq({})
          expect(subject.http_status).to eq(:created)
          expect(Gitlab::AppLogger)
            .to have_received(:warn)
            .with(
              message: 'Prometheus payload exceeded maximum amount of alerts. Truncating alerts.',
              project_id: project.id,
              alerts: {
                total: 2,
                max: max_alerts
              })
        end
      end

      shared_examples 'process all alerts' do
        it 'returns 201 and process alerts without warnings', :aggregate_failures do
          expect(subject).to be_success
          expect(subject.payload).to eq({})
          expect(subject.http_status).to eq(:created)
          expect(Gitlab::AppLogger).not_to have_received(:warn)
        end
      end

      context 'with feature flag globally enabled' do
        before do
          stub_feature_flags(prometheus_notify_max_alerts: true)
        end

        include_examples 'process truncated alerts'
      end

      context 'with feature flag enabled on project' do
        before do
          stub_feature_flags(prometheus_notify_max_alerts: project)
        end

        include_examples 'process truncated alerts'
      end

      context 'with feature flag enabled on unrelated project' do
        let(:another_project) { create(:project) }

        before do
          stub_feature_flags(prometheus_notify_max_alerts: another_project)
        end

        include_examples 'process all alerts'
      end

      context 'with feature flag disabled' do
        before do
          stub_feature_flags(prometheus_notify_max_alerts: false)
        end

        include_examples 'process all alerts'
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

      it_behaves_like 'alerts service responds with an error and takes no actions', :unprocessable_entity
    end

    context 'when the payload is too big' do
      let(:payload_raw) { { 'the-payload-is-too-big' => true } }
      let(:payload) { ActionController::Parameters.new(payload_raw).permit! }

      before do
        stub_const('::Gitlab::Utils::DeepSize::DEFAULT_MAX_DEPTH', 0)
      end

      it_behaves_like 'alerts service responds with an error and takes no actions', :bad_request
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
