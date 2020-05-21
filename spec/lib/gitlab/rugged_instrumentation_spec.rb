# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::RuggedInstrumentation, :request_store do
  subject { described_class }

  describe '.query_time' do
    it 'increments query times' do
      subject.add_query_time(0.4510004)
      subject.add_query_time(0.3220004)

      expect(subject.query_time).to eq(0.773001)
      expect(subject.query_time_ms).to eq(773.0)
    end
  end

  describe '.increment_query_count' do
    it 'tracks query counts' do
      expect(subject.query_count).to eq(0)

      2.times { subject.increment_query_count }

      expect(subject.query_count).to eq(2)
    end
  end
end
