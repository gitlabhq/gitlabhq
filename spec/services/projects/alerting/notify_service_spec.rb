# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Alerting::NotifyService do
  let_it_be_with_reload(:project) { create(:project) }

  let(:payload) { ActionController::Parameters.new(payload_raw).permit! }
  let(:payload_raw) { {} }

  let(:service) { described_class.new(project, payload) }

  before do
    stub_licensed_features(oncall_schedules: false, generic_alert_fingerprinting: false)
  end

  describe '#execute' do
    include_context 'incident management settings enabled'

    subject { service.execute(token, integration) }

    context 'with HTTP integration' do
      let_it_be_with_reload(:integration) { create(:alert_management_http_integration, project: project) }

      context 'with valid token' do
        let(:token) { integration.token }

        context 'with valid payload' do
          let_it_be(:environment) { create(:environment, project: project) }
          let_it_be(:fingerprint) { 'testing' }
          let_it_be(:source) { 'GitLab RSpec' }
          let_it_be(:starts_at) { Time.current.change(usec: 0) }

          let(:ended_at) { nil }
          let(:domain) { 'operations' }
          let(:payload_raw) do
            {
              title: 'alert title',
              start_time: starts_at.rfc3339,
              end_time: ended_at&.rfc3339,
              severity: 'low',
              monitoring_tool: source,
              service: 'GitLab Test Suite',
              description: 'Very detailed description',
              hosts: ['1.1.1.1', '2.2.2.2'],
              fingerprint: fingerprint,
              gitlab_environment_name: environment.name
            }.with_indifferent_access
          end

          let(:last_alert_attributes) do
            AlertManagement::Alert.last.attributes
              .except('id', 'iid', 'created_at', 'updated_at')
              .with_indifferent_access
          end

          it_behaves_like 'processes new firing alert'
          it_behaves_like 'properly assigns the alert properties'

          it 'passes the integration to alert processing' do
            expect(Gitlab::AlertManagement::Payload)
              .to receive(:parse)
              .with(project, payload.to_h, integration: integration)
              .and_call_original

            subject
          end

          context 'with partial payload' do
            let_it_be(:source) { integration.name }
            let_it_be(:payload_raw) do
              {
                title: 'alert title',
                start_time: starts_at.rfc3339
              }
            end

            include_examples 'processes never-before-seen alert'

            it 'assigns the alert properties' do
              subject

              expect(last_alert_attributes).to match(
                project_id: project.id,
                title: payload_raw.fetch(:title),
                started_at: Time.zone.parse(payload_raw.fetch(:start_time)),
                severity: 'critical',
                status: AlertManagement::Alert.status_value(:triggered),
                events: 1,
                hosts: [],
                domain: 'operations',
                payload: payload_raw.with_indifferent_access,
                issue_id: nil,
                description: nil,
                monitoring_tool: nil,
                service: nil,
                fingerprint: nil,
                ended_at: nil,
                prometheus_alert_id: nil,
                environment_id: nil
              )
            end

            context 'with existing alert with matching payload' do
              let_it_be(:fingerprint) { payload_raw.except(:start_time).stringify_keys }
              let_it_be(:gitlab_fingerprint) { Gitlab::AlertManagement::Fingerprint.generate(fingerprint) }
              let_it_be(:alert) { create(:alert_management_alert, project: project, fingerprint: gitlab_fingerprint) }

              include_examples 'processes never-before-seen alert'
            end
          end

          context 'with resolving payload' do
            let(:ended_at) { Time.current.change(usec: 0) }

            it_behaves_like 'processes recovery alert'
          end
        end

        context 'with overlong payload' do
          let(:deep_size_object) { instance_double(Gitlab::Utils::DeepSize, valid?: false) }

          before do
            allow(Gitlab::Utils::DeepSize).to receive(:new).and_return(deep_size_object)
          end

          it_behaves_like 'alerts service responds with an error and takes no actions', :bad_request
        end

        context 'with inactive integration' do
          before do
            integration.update!(active: false)
          end

          it_behaves_like 'alerts service responds with an error and takes no actions', :forbidden
        end
      end

      context 'with invalid token' do
        let(:token) { 'invalid-token' }

        it_behaves_like 'alerts service responds with an error and takes no actions', :unauthorized
      end
    end

    context 'without HTTP integration' do
      let(:integration) { nil }
      let(:token) { nil }

      it_behaves_like 'alerts service responds with an error and takes no actions', :forbidden
    end
  end
end
