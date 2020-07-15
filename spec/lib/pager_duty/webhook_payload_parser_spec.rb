# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe PagerDuty::WebhookPayloadParser do
  describe '.call' do
    let(:fixture_file) do
      File.read(File.join(File.dirname(__FILE__), '../../fixtures/pager_duty/webhook_incident_trigger.json'))
    end

    subject(:parse) { described_class.call(payload) }

    context 'when payload is a correct PagerDuty payload' do
      let(:payload) { Gitlab::Json.parse(fixture_file) }

      it 'returns parsed payload' do
        is_expected.to eq(
          [
            {
              'event' => 'incident.trigger',
              'incident' => {
                'url' => 'https://webdemo.pagerduty.com/incidents/PRORDTY',
                'incident_number' => 33,
                'title' => 'My new incident',
                'status' => 'triggered',
                'created_at' => '2017-09-26T15:14:36Z',
                'urgency' => 'high',
                'incident_key' => nil,
                'assignees' => [{
                  'summary' => 'Laura Haley',
                  'url' => 'https://webdemo.pagerduty.com/users/P553OPV'
                }],
                'impacted_services' => [{
                  'summary' => 'Production XDB Cluster',
                  'url' => 'https://webdemo.pagerduty.com/services/PN49J75'
                }]
              }
            }
          ]
        )
      end

      context 'when assignments summary and html_url are blank' do
        before do
          payload['messages'].each do |m|
            m['incident']['assignments'] = [{ 'assignee' => { 'summary' => '', 'html_url' => '' } }]
          end
        end

        it 'returns parsed payload with blank assignees' do
          assignees = parse.map { |events| events['incident'].slice('assignees') }

          expect(assignees).to eq([{ 'assignees' => [] }])
        end
      end

      context 'when impacted_services summary and html_url are blank' do
        before do
          payload['messages'].each do |m|
            m['incident']['impacted_services'] = [{ 'summary' => '', 'html_url' => '' }]
          end
        end

        it 'returns parsed payload with blank assignees' do
          assignees = parse.map { |events| events['incident'].slice('impacted_services') }

          expect(assignees).to eq([{ 'impacted_services' => [] }])
        end
      end
    end

    context 'when payload has no incidents' do
      let(:payload) { { 'messages' => [{ 'event' => 'incident.trigger' }] } }

      it 'returns payload with blank incidents' do
        is_expected.to eq([{ 'event' => 'incident.trigger', 'incident' => {} }])
      end
    end
  end
end
