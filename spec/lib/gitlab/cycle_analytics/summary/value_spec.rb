# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::CycleAnalytics::Summary::Value do
  describe Gitlab::CycleAnalytics::Summary::Value::None do
    it 'returns `-`' do
      expect(described_class.new.to_s).to eq('-')
    end
  end

  describe Gitlab::CycleAnalytics::Summary::Value::Numeric do
    it 'returns the string representation of the number' do
      expect(described_class.new(3.2).to_s).to eq('3.2')
    end
  end

  describe Gitlab::CycleAnalytics::Summary::Value::PrettyNumeric do
    describe '#to_s' do
      it 'returns `-` when the number is 0' do
        expect(described_class.new(0).to_s).to eq('-')
      end

      it 'returns `-` when the number is nil' do
        expect(described_class.new(nil).to_s).to eq('-')
      end

      it 'returns the string representation of the number' do
        expect(described_class.new(100).to_s).to eq('100')
      end
    end
  end
end
