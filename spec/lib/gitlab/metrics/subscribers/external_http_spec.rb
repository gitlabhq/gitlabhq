# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Subscribers::ExternalHttp, :request_store do
  let(:transaction) { Gitlab::Metrics::Transaction.new }
  let(:subscriber) { described_class.new }

  around do |example|
    freeze_time { example.run }
  end

  let(:event_1) do
    double(
      :event,
      payload: {
        method: 'POST', code: "200", duration: 0.321,
        scheme: 'https', host: 'gitlab.com', port: 80, path: '/api/v4/projects',
        query: 'current=true'
      },
      time: Time.current
    )
  end

  let(:event_2) do
    double(
      :event,
      payload: {
        method: 'GET', code: "301", duration: 0.12,
        scheme: 'http', host: 'gitlab.com', port: 80, path: '/api/v4/projects/2',
        query: 'current=true'
      },
      time: Time.current
    )
  end

  let(:event_3) do
    double(
      :event,
      payload: {
        method: 'POST', duration: 5.3,
        scheme: 'http', host: 'gitlab.com', port: 80, path: '/api/v4/projects/2/issues',
        query: 'current=true',
        exception_object: Net::ReadTimeout.new
      },
      time: Time.current
    )
  end

  describe '.detail_store' do
    context 'when external HTTP detail store is empty' do
      before do
        Gitlab::SafeRequestStore[:peek_enabled] = true
      end

      it 'returns an empty array' do
        expect(described_class.detail_store).to eql([])
      end
    end

    context 'when the performance bar is not enabled' do
      it 'returns an empty array' do
        expect(described_class.detail_store).to eql([])
      end
    end

    context 'when external HTTP detail store has some values' do
      before do
        Gitlab::SafeRequestStore[:peek_enabled] = true
        Gitlab::SafeRequestStore[:external_http_detail_store] = [{
          method: 'POST', code: "200", duration: 0.321
        }]
      end

      it 'returns the external http detailed store' do
        expect(described_class.detail_store).to eql([{ method: 'POST', code: "200", duration: 0.321 }])
      end
    end
  end

  describe '.payload' do
    context 'when SafeRequestStore does not have any item from external HTTP' do
      it 'returns an empty array' do
        expect(described_class.payload).to eql(external_http_count: 0, external_http_duration_s: 0.0)
      end
    end

    context 'when external HTTP recorded some values' do
      before do
        Gitlab::SafeRequestStore[:external_http_count] = 7
        Gitlab::SafeRequestStore[:external_http_duration_s] = 1.2
      end

      it 'returns the external http detailed store' do
        expect(described_class.payload).to eql(external_http_count: 7, external_http_duration_s: 1.2)
      end
    end
  end

  describe '#request' do
    before do
      Gitlab::SafeRequestStore[:peek_enabled] = true
      allow(subscriber).to receive(:current_transaction).and_return(transaction)
    end

    it 'tracks external HTTP request count' do
      expect(transaction).to receive(:increment)
        .with(:gitlab_external_http_total, 1, { code: "200", method: "POST" })
      expect(transaction).to receive(:increment)
        .with(:gitlab_external_http_total, 1, { code: "301", method: "GET" })

      subscriber.request(event_1)
      subscriber.request(event_2)
    end

    it 'tracks external HTTP duration' do
      expect(transaction).to receive(:observe)
        .with(:gitlab_external_http_duration_seconds, 0.321)
      expect(transaction).to receive(:observe)
        .with(:gitlab_external_http_duration_seconds, 0.12)
      expect(transaction).to receive(:observe)
        .with(:gitlab_external_http_duration_seconds, 5.3)

      subscriber.request(event_1)
      subscriber.request(event_2)
      subscriber.request(event_3)
    end

    it 'tracks external HTTP exceptions' do
      expect(transaction).to receive(:increment)
        .with(:gitlab_external_http_total, 1, { code: 'undefined', method: "POST" })
      expect(transaction).to receive(:increment)
        .with(:gitlab_external_http_exception_total, 1)

      subscriber.request(event_3)
    end

    it 'stores per-request counters' do
      subscriber.request(event_1)
      subscriber.request(event_2)
      subscriber.request(event_3)

      expect(Gitlab::SafeRequestStore[:external_http_count]).to eq(3)
      expect(Gitlab::SafeRequestStore[:external_http_duration_s]).to eq(5.741) # 0.321 + 0.12 + 5.3
    end

    it 'stores a portion of events into the detail store' do
      subscriber.request(event_1)
      subscriber.request(event_2)
      subscriber.request(event_3)

      expect(Gitlab::SafeRequestStore[:external_http_detail_store].length).to eq(3)
      expect(Gitlab::SafeRequestStore[:external_http_detail_store][0]).to match a_hash_including(
        start: be_like_time(Time.current),
        method: 'POST', code: "200", duration: 0.321,
        scheme: 'https', host: 'gitlab.com', port: 80, path: '/api/v4/projects',
        query: 'current=true', exception_object: nil,
        backtrace: be_a(Array)
      )
      expect(Gitlab::SafeRequestStore[:external_http_detail_store][1]).to match a_hash_including(
        start: be_like_time(Time.current),
        method: 'GET', code: "301", duration: 0.12,
        scheme: 'http', host: 'gitlab.com', port: 80, path: '/api/v4/projects/2',
        query: 'current=true', exception_object: nil,
        backtrace: be_a(Array)
      )
      expect(Gitlab::SafeRequestStore[:external_http_detail_store][2]).to match a_hash_including(
        start: be_like_time(Time.current),
        method: 'POST', duration: 5.3,
        scheme: 'http', host: 'gitlab.com', port: 80, path: '/api/v4/projects/2/issues',
        query: 'current=true',
        exception_object: be_a(Net::ReadTimeout),
        backtrace: be_a(Array)
      )
    end

    context 'when the performance bar is not enabled' do
      before do
        Gitlab::SafeRequestStore.delete(:peek_enabled)
      end

      it 'does not capture detail store' do
        subscriber.request(event_1)
        subscriber.request(event_2)
        subscriber.request(event_3)

        expect(Gitlab::SafeRequestStore[:external_http_detail_store]).to be(nil)
      end
    end
  end
end
