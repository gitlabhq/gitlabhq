# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::ServicePing::InstrumentedPayload do
  let(:uuid) { "0000-0000-0000" }

  before do
    allow(ApplicationRecord.connection).to receive(:transaction_open?).and_return(false)
    allow(Gitlab::CurrentSettings).to receive(:uuid).and_return(uuid)
  end

  context 'when building service ping with values' do
    let(:metrics_key_paths) { %w(counts.boards uuid redis_hll_counters.search.i_search_total_monthly) }
    let(:expected_payload) do
      {
        counts: { boards: 0 },
        redis_hll_counters: { search: { i_search_total_monthly: 0 } },
        uuid: uuid
      }
    end

    it 'builds the service ping payload for the metrics key_paths' do
      expect(described_class.new(metrics_key_paths, :with_value).build).to eq(expected_payload)
    end
  end

  context 'when building service ping with instrumentations' do
    let(:metrics_key_paths) { %w(counts.boards uuid redis_hll_counters.search.i_search_total_monthly) }
    let(:expected_payload) do
      {
        counts: { boards: "SELECT COUNT(\"boards\".\"id\") FROM \"boards\"" },
        redis_hll_counters: { search: { i_search_total_monthly: 0 } },
        uuid: uuid
      }
    end

    it 'builds the service ping payload for the metrics key_paths' do
      expect(described_class.new(metrics_key_paths, :with_instrumentation).build).to eq(expected_payload)
    end
  end

  context 'when missing instrumentation class' do
    it 'returns empty hash' do
      expect(described_class.new(['counts.ci_builds'], :with_instrumentation).build).to eq({})
      expect(described_class.new(['counts.ci_builds'], :with_value).build).to eq({})
    end
  end
end
