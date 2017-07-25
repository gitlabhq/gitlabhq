require 'spec_helper'

describe Gitlab::Sherlock::Location do
  let(:location) { described_class.new(__FILE__, 1) }

  describe 'from_ruby_location' do
    it 'creates a Location from a Thread::Backtrace::Location' do
      input  = caller_locations[0]
      output = described_class.from_ruby_location(input)

      expect(output).to be_an_instance_of(described_class)
      expect(output.path).to eq(input.path)
      expect(output.line).to eq(input.lineno)
    end
  end

  describe '#path' do
    it 'returns the file path' do
      expect(location.path).to eq(__FILE__)
    end
  end

  describe '#line' do
    it 'returns the line number' do
      expect(location.line).to eq(1)
    end
  end

  describe '#application?' do
    it 'returns true for an application frame' do
      expect(location.application?).to eq(true)
    end

    it 'returns false for a non application frame' do
      loc = described_class.new('/tmp/cats.rb', 1)

      expect(loc.application?).to eq(false)
    end
  end
end
