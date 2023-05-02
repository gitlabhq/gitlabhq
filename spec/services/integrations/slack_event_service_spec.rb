# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackEventService, feature_category: :integrations do
  describe '#execute' do
    subject(:execute) { described_class.new(params).execute }

    let(:params) do
      {
        type: 'event_callback',
        event: {
          type: 'app_home_opened',
          foo: 'bar'
        }
      }
    end

    it 'queues a worker and returns success response' do
      expect(Integrations::SlackEventWorker).to receive(:perform_async)
        .with(
          {
            slack_event: 'app_home_opened',
            params: {
              event: {
                foo: 'bar'
              }
            }
          }
        )
      expect(execute.payload).to eq({})
      is_expected.to be_success
    end

    context 'when event a url verification request' do
      let(:params) { { type: 'url_verification', foo: 'bar' } }

      it 'executes the service instead of queueing a worker and returns success response' do
        expect(Integrations::SlackEventWorker).not_to receive(:perform_async)
        expect_next_instance_of(Integrations::SlackEvents::UrlVerificationService, { foo: 'bar' }) do |service|
          expect(service).to receive(:execute).and_return({ baz: 'qux' })
        end
        expect(execute.payload).to eq({ baz: 'qux' })
        is_expected.to be_success
      end
    end

    context 'when event is unknown' do
      let(:params) { super().merge(event: { type: 'foo' }) }

      it 'raises an error' do
        expect { execute }.to raise_error(described_class::UnknownEventError)
      end
    end
  end
end
