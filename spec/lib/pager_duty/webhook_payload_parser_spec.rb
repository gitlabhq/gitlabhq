# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PagerDuty::WebhookPayloadParser do
  describe '.call' do
    let(:fixture_file) do
      File.read(File.join(File.dirname(__FILE__), '../../fixtures/pager_duty/webhook_incident_trigger.json'))
    end

    let(:triggered_event) do
      {
        'event' => 'incident.triggered',
        'incident' => {
          'url' => 'https://gitlab-1.pagerduty.com/incidents/Q1XZUF87W1HB5A',
          'incident_number' => 2,
          'title' => '[FILTERED]',
          'status' => 'triggered',
          'created_at' => '2022-11-30T08:46:19Z',
          'urgency' => 'high',
          'incident_key' => '[FILTERED]',
          'assignees' =>
          [
            {
              'summary' => 'Rajendra Kadam',
              'url' => 'https://gitlab-1.pagerduty.com/users/PIN0B5C'
            }
          ],
          'impacted_service' =>
          {
            'summary' => 'Test service',
            'url' => 'https://gitlab-1.pagerduty.com/services/PK6IKMT'
          }
        }
      }
    end

    subject(:parse) { described_class.call(payload) }

    context 'when payload is a correct PagerDuty payload' do
      let(:payload) { Gitlab::Json.parse(fixture_file) }

      it 'returns parsed payload' do
        is_expected.to eq(triggered_event)
      end

      context 'when assignments summary and html_url are blank' do
        before do
          payload['event']['data']['assignees'] = [{ 'summary' => '', 'html_url' => '' }]
        end

        it 'returns parsed payload with blank assignees' do
          assignees = parse['incident'].slice('assignees')

          expect(assignees).to eq({ 'assignees' => [] })
        end
      end

      context 'when impacted_services summary and html_url are blank' do
        before do
          payload['event']['data']['service'] = { 'summary' => '', 'html_url' => '' }
        end

        it 'returns parsed payload with blank impacted service' do
          assignees = parse['incident'].slice('impacted_service')

          expect(assignees).to eq({ 'impacted_service' => {} })
        end
      end
    end

    context 'when payload schema is invalid' do
      let(:payload) { { 'event' => 'incident.triggered' } }

      it 'returns payload with blank incident' do
        is_expected.to eq({})
      end
    end

    context 'when event is unknown' do
      let(:payload) do
        valid_payload = Gitlab::Json.parse(fixture_file)
        valid_payload['event'] = 'incident.unknown'
      end

      it 'returns empty payload' do
        is_expected.to be_empty
      end
    end
  end
end
