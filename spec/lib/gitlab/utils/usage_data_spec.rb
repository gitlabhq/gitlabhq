# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Utils::UsageData do
  describe '#count' do
    let(:relation) { double(:relation) }

    it 'returns the count when counting succeeds' do
      allow(relation).to receive(:count).and_return(1)

      expect(described_class.count(relation, batch: false)).to eq(1)
    end

    it 'returns the fallback value when counting fails' do
      stub_const("Gitlab::Utils::UsageData::FALLBACK", 15)
      allow(relation).to receive(:count).and_raise(ActiveRecord::StatementInvalid.new(''))

      expect(described_class.count(relation, batch: false)).to eq(15)
    end
  end

  describe '#distinct_count' do
    let(:relation) { double(:relation) }

    it 'returns the count when counting succeeds' do
      allow(relation).to receive(:distinct_count_by).and_return(1)

      expect(described_class.distinct_count(relation, batch: false)).to eq(1)
    end

    it 'returns the fallback value when counting fails' do
      stub_const("Gitlab::Utils::UsageData::FALLBACK", 15)
      allow(relation).to receive(:distinct_count_by).and_raise(ActiveRecord::StatementInvalid.new(''))

      expect(described_class.distinct_count(relation, batch: false)).to eq(15)
    end
  end

  describe '#sum' do
    let(:relation) { double(:relation) }

    it 'returns the count when counting succeeds' do
      allow(Gitlab::Database::BatchCount)
        .to receive(:batch_sum)
        .with(relation, :column, batch_size: 100, start: 2, finish: 3)
        .and_return(1)

      expect(described_class.sum(relation, :column, batch_size: 100, start: 2, finish: 3)).to eq(1)
    end

    it 'returns the fallback value when counting fails' do
      stub_const("Gitlab::Utils::UsageData::FALLBACK", 15)
      allow(Gitlab::Database::BatchCount)
        .to receive(:batch_sum)
        .and_raise(ActiveRecord::StatementInvalid.new(''))

      expect(described_class.sum(relation, :column)).to eq(15)
    end
  end

  describe '#alt_usage_data' do
    it 'returns the fallback when it gets an error' do
      expect(described_class.alt_usage_data { raise StandardError } ).to eq(-1)
    end

    it 'returns the evaluated block when give' do
      expect(described_class.alt_usage_data { Gitlab::CurrentSettings.uuid } ).to eq(Gitlab::CurrentSettings.uuid)
    end

    it 'returns the value when given' do
      expect(described_class.alt_usage_data(1)).to eq 1
    end
  end

  describe '#redis_usage_data' do
    context 'with block given' do
      it 'returns the fallback when it gets an error' do
        expect(described_class.redis_usage_data { raise ::Redis::CommandError } ).to eq(-1)
      end

      it 'returns the evaluated block when given' do
        expect(described_class.redis_usage_data { 1 }).to eq(1)
      end
    end

    context 'with counter given' do
      it 'returns the falback values for all counter keys when it gets an error' do
        allow(::Gitlab::UsageDataCounters::WikiPageCounter).to receive(:totals).and_raise(::Redis::CommandError)
        expect(described_class.redis_usage_data(::Gitlab::UsageDataCounters::WikiPageCounter)).to eql(::Gitlab::UsageDataCounters::WikiPageCounter.fallback_totals)
      end

      it 'returns the totals when couter is given' do
        allow(::Gitlab::UsageDataCounters::WikiPageCounter).to receive(:totals).and_return({ wiki_pages_create: 2 })
        expect(described_class.redis_usage_data(::Gitlab::UsageDataCounters::WikiPageCounter)).to eql({ wiki_pages_create: 2 })
      end
    end
  end

  describe '#with_prometheus_client' do
    shared_examples 'query data from Prometheus' do
      it 'yields a client instance and returns the block result' do
        result = described_class.with_prometheus_client { |client| client }

        expect(result).to be_an_instance_of(Gitlab::PrometheusClient)
      end
    end

    shared_examples 'does not query data from Prometheus' do
      it 'returns nil by default' do
        result = described_class.with_prometheus_client { |client| client }

        expect(result).to be_nil
      end

      it 'returns fallback if provided' do
        result = described_class.with_prometheus_client(fallback: []) { |client| client }

        expect(result).to eq([])
      end
    end

    shared_examples 'try to query Prometheus with given address' do
      context 'Prometheus is ready' do
        before do
          stub_request(:get, /\/-\/ready/)
              .to_return(status: 200, body: 'Prometheus is Ready.\n')
        end

        context 'Prometheus is reachable through HTTPS' do
          it_behaves_like 'query data from Prometheus'
        end

        context 'Prometheus is not reachable through HTTPS' do
          before do
            stub_request(:get, /https:\/\/.*/).to_raise(Errno::ECONNREFUSED)
          end

          context 'Prometheus is reachable through HTTP' do
            it_behaves_like 'query data from Prometheus'
          end

          context 'Prometheus is not reachable through HTTP' do
            before do
              stub_request(:get, /http:\/\/.*/).to_raise(Errno::ECONNREFUSED)
            end

            it_behaves_like 'does not query data from Prometheus'
          end
        end
      end

      context 'Prometheus is not ready' do
        before do
          stub_request(:get, /\/-\/ready/)
              .to_return(status: 503, body: 'Service Unavailable')
        end

        it_behaves_like 'does not query data from Prometheus'
      end
    end

    context 'when Prometheus server address is available from settings' do
      before do
        expect(Gitlab::Prometheus::Internal).to receive(:prometheus_enabled?).and_return(true)
        expect(Gitlab::Prometheus::Internal).to receive(:server_address).and_return('prom:9090')
      end

      it_behaves_like 'try to query Prometheus with given address'
    end

    context 'when Prometheus server address is available from Consul service discovery' do
      before do
        expect(Gitlab::Prometheus::Internal).to receive(:prometheus_enabled?).and_return(false)
        expect(Gitlab::Consul::Internal).to receive(:api_url).and_return('http://localhost:8500')
        expect(Gitlab::Consul::Internal).to receive(:discover_prometheus_server_address).and_return('prom:9090')
      end

      it_behaves_like 'try to query Prometheus with given address'
    end

    context 'when Prometheus server address is not available' do
      before do
        expect(Gitlab::Prometheus::Internal).to receive(:prometheus_enabled?).and_return(false)
        expect(Gitlab::Consul::Internal).to receive(:api_url).and_return(nil)
      end

      it_behaves_like 'does not query data from Prometheus'
    end
  end

  describe '#measure_duration' do
    it 'returns block result and execution duration' do
      allow(Process).to receive(:clock_gettime).and_return(1, 3)

      result, duration = described_class.measure_duration { 42 }

      expect(result).to eq(42)
      expect(duration).to eq(2)
    end
  end

  describe '#with_finished_at' do
    it 'adds a timestamp to the hash yielded by the block' do
      freeze_time do
        result = described_class.with_finished_at(:current_time) { { a: 1 } }

        expect(result).to eq(a: 1, current_time: Time.current)
      end
    end
  end

  describe '#track_usage_event' do
    let(:value) { '9f302fea-f828-4ca9-aef4-e10bd723c0b3' }
    let(:event_name) { 'incident_management_alert_status_changed' }
    let(:unknown_event) { 'unknown' }
    let(:feature) { "usage_data_#{event_name}" }

    before do
      skip_feature_flags_yaml_validation
    end

    context 'with feature enabled' do
      before do
        stub_feature_flags(feature => true)
      end

      it 'tracks redis hll event' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event).with(value, event_name)

        described_class.track_usage_event(event_name, value)
      end

      it 'raise an error for unknown event' do
        expect { described_class.track_usage_event(unknown_event, value) }.to raise_error(Gitlab::UsageDataCounters::HLLRedisCounter::UnknownEvent)
      end
    end

    context 'with feature disabled' do
      before do
        stub_feature_flags(feature => false)
      end

      it 'does not track event' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter).not_to receive(:track_event)

        described_class.track_usage_event(event_name, value)
      end
    end
  end
end
