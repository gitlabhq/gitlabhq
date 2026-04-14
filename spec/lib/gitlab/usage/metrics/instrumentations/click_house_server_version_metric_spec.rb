# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::ClickHouseServerVersionMetric, feature_category: :database do
  let(:connection) { instance_double(ClickHouse::Connection) }

  context 'with stubbed ClickHouse::Connection' do
    before do
      allow(ClickHouse::Connection).to receive(:new).with(:main).and_return(connection)
    end

    context 'when ClickHouse is configured' do
      before do
        allow(ClickHouse::Client).to receive(:database_configured?).with(:main).and_return(true)
        allow(connection).to receive(:version).and_return('23.3.1.1')
      end

      it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' } do
        let(:expected_value) { '23.3.1.1' }
      end
    end

    context 'when ClickHouse is not configured' do
      before do
        allow(ClickHouse::Client).to receive(:database_configured?).with(:main).and_return(false)
      end

      it 'returns nil' do
        metric = described_class.new(time_frame: 'none')
        expect(metric.value).to be_nil
      end
    end
  end

  context 'with a real ClickHouse connection', :click_house do
    it_behaves_like 'a correct instrumented metric value', { time_frame: 'none' } do
      let(:expected_value) { ClickHouse::Client.select('SELECT version() AS ver', :main).first['ver'] }
    end
  end
end
