# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Utils::Uniquify, feature_category: :shared do
  subject(:uniquify) { described_class.new }

  describe "#string" do
    it 'returns the given string if it does not exist' do
      result = uniquify.string('test_string') { |_s| false }

      expect(result).to eq('test_string')
    end

    it 'returns the given string with a counter attached if the string exists' do
      result = uniquify.string('test_string') { |s| s == 'test_string' }

      expect(result).to eq('test_string1')
    end

    it 'increments the counter for each candidate string that also exists' do
      result = uniquify.string('test_string') { |s| s == 'test_string' || s == 'test_string1' }

      expect(result).to eq('test_string2')
    end

    it 'allows to pass an initial value for the counter' do
      start_counting_from = 2
      uniquify = described_class.new(start_counting_from)

      result = uniquify.string('test_string') { |s| s == 'test_string' }

      expect(result).to eq('test_string2')
    end

    it 'allows passing in a base function that defines the location of the counter' do
      result = uniquify.string(->(counter) { "test_#{counter}_string" }) do |s|
        s == 'test__string'
      end

      expect(result).to eq('test_1_string')
    end
  end
end
