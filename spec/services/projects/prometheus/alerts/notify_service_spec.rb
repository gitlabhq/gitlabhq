# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Prometheus::Alerts::NotifyService do
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
    let_it_be(:alert_firing) { create(:prometheus_alert, project: project) }
    let_it_be(:alert_resolved) { create(:prometheus_alert, project: project) }
    let_it_be(:cluster, reload: true) { create(:cluster, :provided_by_user, projects: [project]) }

    let(:payload_raw) { prometheus_alert_payload(firing: [alert_firing], resolved: [alert_resolved]) }
    let(:payload) { ActionController::Parameters.new(payload_raw).permit! }
    let(:payload_alert_firing) { payload_raw['alerts'].first }
    let(:token) { 'token' }
    let(:source) { 'Prometheus' }

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
        create(:clusters_integrations_prometheus,
               cluster: prd_cluster, alert_manager_token: token)
        create(:clusters_integrations_prometheus,
               cluster: stg_cluster, alert_manager_token: nil)
      end

      context 'without token' do
        let(:token_input) { nil }

        include_examples 'processes one firing and one resolved prometheus alerts'
      end

      context 'with token' do
        it_behaves_like 'alerts service responds with an error and takes no actions', :unauthorized
      end
    end

    context 'with project specific cluster using prometheus integration' do
      where(:cluster_enabled, :integration_enabled, :configured_token, :token_input, :result) do
        true  | true  | token | token | :success
        true  | true  | nil   | nil   | :success
        true  | true  | token | 'x'   | :failure
        true  | true  | token | nil   | :failure
        true  | false | token | token | :failure
        false | true  | token | token | :failure
        false | nil   | nil   | token | :failure
      end

      with_them do
        before do
          cluster.update!(enabled: cluster_enabled)

          unless integration_enabled.nil?
            create(:clusters_integrations_prometheus,
                   cluster: cluster,
                   enabled: integration_enabled,
                   alert_manager_token: configured_token)
          end
        end

        case result = params[:result]
        when :success
          include_examples 'processes one firing and one resolved prometheus alerts'
        when :failure
          it_behaves_like 'alerts service responds with an error and takes no actions', :unauthorized
        else
          raise "invalid result: #{result.inspect}"
        end
      end
    end

    context 'without project specific cluster' do
      let_it_be(:cluster) { create(:cluster, enabled: true) }

      it_behaves_like 'alerts service responds with an error and takes no actions', :unauthorized
    end

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
            create(:project_alerting_setting,
                   project: project,
                   token: configured_token)
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
      let(:process_service) { instance_double(AlertManagement::ProcessPrometheusAlertService) }

      before do
        create(:prometheus_integration, project: project)
        create(:project_alerting_setting, project: project, token: token)
      end

      context 'with multiple firing alerts and resolving alerts' do
        let(:payload_raw) do
          prometheus_alert_payload(firing: [alert_firing, alert_firing], resolved: [alert_resolved])
        end

        it 'processes Prometheus alerts' do
          expect(AlertManagement::ProcessPrometheusAlertService)
            .to receive(:new)
            .with(project, kind_of(Hash))
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

      it_behaves_like 'alerts service responds with an error and takes no actions', :unprocessable_entity
    end

    context 'when the payload is too big' do
      let(:payload) { { 'the-payload-is-too-big' => true } }
      let(:deep_size_object) { instance_double(Gitlab::Utils::DeepSize, valid?: false) }

      before do
        allow(Gitlab::Utils::DeepSize).to receive(:new).and_return(deep_size_object)
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
