# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::PagerDuty::ProcessWebhookService, feature_category: :incident_management do
  let_it_be(:project, reload: true) { create(:project) }

  describe '#execute' do
    shared_examples 'does not process incidents' do
      it 'does not process incidents' do
        expect(::IncidentManagement::PagerDuty::ProcessIncidentWorker).not_to receive(:perform_async)

        execute
      end
    end

    let(:webhook_payload) { Gitlab::Json.parse(fixture_file('pager_duty/webhook_incident_trigger.json')) }
    let(:token) { nil }

    subject(:execute) { described_class.new(project, webhook_payload).execute(token) }

    context 'when PagerDuty webhook setting is active' do
      let_it_be(:incident_management_setting) { create(:project_incident_management_setting, project: project, pagerduty_active: true) }

      context 'when token is valid' do
        let(:token) { incident_management_setting.pagerduty_token }

        context 'when webhook payload has acceptable size' do
          it 'responds with Accepted' do
            result = execute

            expect(result).to be_success
            expect(result.http_status).to eq(:accepted)
          end

          it 'processes issues' do
            incident_payload = ::PagerDuty::WebhookPayloadParser.call(webhook_payload)['incident']

            expect(::IncidentManagement::PagerDuty::ProcessIncidentWorker)
              .to receive(:perform_async)
              .with(project.id, incident_payload)
              .once

            execute
          end
        end

        context 'when webhook payload is too big' do
          let(:deep_size) { instance_double(Gitlab::Utils::DeepSize, valid?: false) }

          before do
            allow(Gitlab::Utils::DeepSize)
              .to receive(:new)
              .with(webhook_payload, max_size: described_class::PAGER_DUTY_PAYLOAD_SIZE_LIMIT)
              .and_return(deep_size)
          end

          it 'responds with Bad Request' do
            result = execute

            expect(result).to be_error
            expect(result.http_status).to eq(:bad_request)
          end

          it_behaves_like 'does not process incidents'
        end

        context 'when webhook payload is blank' do
          let(:webhook_payload) { nil }

          it 'responds with Accepted' do
            result = execute

            expect(result).to be_success
            expect(result.http_status).to eq(:accepted)
          end

          it_behaves_like 'does not process incidents'
        end
      end

      context 'when token is invalid' do
        let(:token) { 'invalid-token' }

        it 'responds with Unauthorized' do
          result = execute

          expect(result).to be_error
          expect(result.http_status).to eq(:unauthorized)
        end

        it_behaves_like 'does not process incidents'
      end
    end

    context 'when both tokens are nil' do
      let_it_be(:incident_management_setting) { create(:project_incident_management_setting, project: project, pagerduty_active: false) }

      let(:token) { nil }

      before do
        incident_management_setting.update_column(:pagerduty_active, true)
      end

      it 'responds with Unauthorized' do
        result = execute

        expect(result).to be_error
        expect(result.http_status).to eq(:unauthorized)
      end

      it_behaves_like 'does not process incidents'
    end

    context 'when PagerDuty webhook setting is not active' do
      let_it_be(:incident_management_setting) { create(:project_incident_management_setting, project: project, pagerduty_active: false) }

      it 'responds with Forbidden' do
        result = execute

        expect(result).to be_error
        expect(result.http_status).to eq(:forbidden)
      end

      it_behaves_like 'does not process incidents'
    end
  end
end
