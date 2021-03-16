# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PagerDuty::WebhookPayloadParser do
  describe '.call' do
    let(:fixture_file) do
      File.read(File.join(File.dirname(__FILE__), '../../fixtures/pager_duty/webhook_incident_trigger.json'))
    end

    let(:triggered_event) do
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
    end

    subject(:parse) { described_class.call(payload) }

    context 'when payload is a correct PagerDuty payload' do
      let(:payload) { Gitlab::Json.parse(fixture_file) }

      it 'returns parsed payload' do
        is_expected.to eq([triggered_event])
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

    context 'when payload schema is invalid' do
      let(:payload) { { 'messages' => [{ 'event' => 'incident.trigger' }] } }

      it 'returns payload with blank incidents' do
        is_expected.to eq([])
      end
    end

    context 'when payload consists of two messages' do
      context 'when one of the messages has no incident data' do
        let(:payload) do
          valid_payload = Gitlab::Json.parse(fixture_file)
          event = { 'event' => 'incident.trigger' }
          valid_payload['messages'] = valid_payload['messages'].append(event)
          valid_payload
        end

        it 'returns parsed payload with valid events only' do
          is_expected.to eq([triggered_event])
        end
      end

      context 'when one of the messages has unknown event' do
        let(:payload) do
          valid_payload = Gitlab::Json.parse(fixture_file)
          event = { 'event' => 'incident.unknown', 'incident' => valid_payload['messages'].first['incident'] }
          valid_payload['messages'] = valid_payload['messages'].append(event)
          valid_payload
        end

        it 'returns parsed payload' do
          unknown_event = triggered_event.dup
          unknown_event['event'] = 'incident.unknown'

          is_expected.to contain_exactly(triggered_event, unknown_event)
        end
      end
    end
  end
end
