# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::RuggedInstrumentation, :request_store do
  subject { described_class }

  describe '.query_time' do
    it 'increments query times' do
      subject.query_time += 0.451
      subject.query_time += 0.322

      expect(subject.query_time).to be_within(0.001).of(0.773)
      expect(subject.query_time_ms).to eq(773.0)
    end
  end

  context '.increment_query_count' do
    it 'tracks query counts' do
      expect(subject.query_count).to eq(0)

      2.times { subject.increment_query_count }

      expect(subject.query_count).to eq(2)
    end
  end
end
