# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackInteractions::IncidentManagement::IncidentModalClosedService,
  feature_category: :integrations do
  describe '#execute' do
    let_it_be(:request_body) do
      {
        replace_original: 'true',
        text: 'Incident creation cancelled.'
      }
    end

    let(:params) do
      {
        view: {
          private_metadata: 'https://api.slack.com/id/1234'
        }
      }
    end

    let(:service) { described_class.new(params) }

    before do
      allow(Gitlab::HTTP).to receive(:post).and_return({ ok: true })
    end

    context 'when executed' do
      it 'makes the POST call and closes the modal' do
        expect(Gitlab::HTTP).to receive(:post).with(
          'https://api.slack.com/id/1234',
          body: Gitlab::Json.dump(request_body),
          headers: { 'Content-Type' => 'application/json' }
        )

        service.execute
      end
    end

    context 'when the POST call raises an HTTP exception' do
      before do
        allow(Gitlab::HTTP).to receive(:post).and_raise(Errno::ECONNREFUSED, 'error message')
      end

      it 'tracks the exception and returns an error response' do
        expect(::Gitlab::ErrorTracking).to receive(:track_exception)
          .with(
            Errno::ECONNREFUSED.new('HTTP exception when calling Slack API'),
            {
              params: params
            }
          )

        service.execute
      end
    end

    context 'when response is not ok' do
      before do
        allow(Gitlab::HTTP).to receive(:post).and_return({ ok: false })
      end

      it 'returns error response and tracks the exception' do
        expect(::Gitlab::ErrorTracking).to receive(:track_exception)
          .with(
            StandardError.new('Something went wrong while closing the incident form.'),
            {
              response: { ok: false },
              params: params
            }
          )

        service.execute
      end
    end
  end
end
