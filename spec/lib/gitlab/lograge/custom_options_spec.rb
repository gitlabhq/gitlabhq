# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Lograge::CustomOptions do
  describe '.call' do
    let(:params) do
      {
        'controller' => 'ApplicationController',
        'action' => 'show',
        'format' => 'html',
        'a' => 'b'
      }
    end

    let(:event_payload) do
      {
        params: params,
        user_id: 'test',
        cf_ray: SecureRandom.hex,
        cf_request_id: SecureRandom.hex,
        metadata: { 'meta.user' => 'jane.doe' }
      }
    end
    let(:event) { ActiveSupport::Notifications::Event.new('test', 1, 2, 'transaction_id', event_payload) }

    subject { described_class.call(event) }

    it 'ignores some parameters' do
      param_keys = subject[:params].map { |param| param[:key] }

      expect(param_keys).not_to include(*described_class::IGNORE_PARAMS)
    end

    it 'formats the parameters' do
      expect(subject[:params]).to eq([{ key: 'a', value: 'b' }])
    end

    it 'adds the current time' do
      travel_to(5.days.ago) do
        expected_time = Time.now.utc.iso8601(3)

        expect(subject[:time]).to eq(expected_time)
      end
    end

    context 'with transaction' do
      let(:transaction) { Gitlab::Metrics::WebTransaction.new({}) }

      before do
        allow(Gitlab::Metrics::Transaction).to receive(:current).and_return(transaction)
      end

      it 'adds db counters' do
        expect(subject).to include(:db_count, :db_write_count, :db_cached_count)
      end
    end

    it 'adds the user id' do
      expect(subject[:user_id]).to eq('test')
    end

    it 'adds Cloudflare headers' do
      expect(subject[:cf_ray]).to eq(event.payload[:cf_ray])
      expect(subject[:cf_request_id]).to eq(event.payload[:cf_request_id])
    end

    it 'adds the metadata' do
      expect(subject['meta.user']).to eq('jane.doe')
    end

    context 'when metadata is missing' do
      let(:event_payload) { { params: {} } }

      it 'does not break' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when correlation_id is overriden' do
      let(:correlation_id_key) { Labkit::Correlation::CorrelationId::LOG_KEY }

      before do
        event_payload[correlation_id_key] = '123456'
      end

      it 'sets the overriden value' do
        expect(subject[correlation_id_key]).to eq('123456')
      end
    end
  end
end
