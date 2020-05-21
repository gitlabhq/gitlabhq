# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Instrumentation::Redis do
  describe '.add_duration', :request_store do
    it 'does not lose precision while adding' do
      precision = 1.0 / (10**::Gitlab::InstrumentationHelper::DURATION_PRECISION)
      2.times { described_class.add_duration(0.4 * precision) }

      # 2 * 0.4 should be 0.8 and get rounded to 1
      expect(described_class.query_time).to eq(1 * precision)
    end
  end
end
