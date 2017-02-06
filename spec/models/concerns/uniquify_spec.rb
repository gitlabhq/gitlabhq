require 'spec_helper'

describe Uniquify, models: true do
  describe "#string" do
    it 'returns the given string if it does not exist' do
      uniquify = Uniquify.new

      result = uniquify.string('test_string', -> (s) { false })

      expect(result).to eq('test_string')
    end

    it 'returns the given string with a counter attached if the string exists' do
      uniquify = Uniquify.new

      result = uniquify.string('test_string', -> (s) { true if s == 'test_string' })

      expect(result).to eq('test_string1')
    end

    it 'increments the counter for each candidate string that also exists' do
      uniquify = Uniquify.new

      result = uniquify.string('test_string', -> (s) { true if s == 'test_string' || s == 'test_string1' })

      expect(result).to eq('test_string2')
    end

    it 'allows passing in a base function that defines the location of the counter' do
      uniquify = Uniquify.new

      result = uniquify.string(
        -> (counter) { "test_#{counter}_string" },
        -> (s) { true if s == 'test__string' }
      )

      expect(result).to eq('test_1_string')
    end
  end
end
