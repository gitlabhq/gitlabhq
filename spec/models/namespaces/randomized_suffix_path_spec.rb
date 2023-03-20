# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::RandomizedSuffixPath, feature_category: :shared do
  let(:path) { 'backintime' }

  subject(:suffixed_path) { described_class.new(path) }

  describe '#to_s' do
    it 'represents with given path' do
      expect(suffixed_path.to_s).to eq('backintime')
    end
  end

  describe '#call' do
    it 'returns path without count when count is 0' do
      expect(suffixed_path.call(0)).to eq('backintime')
    end

    it "returns path suffixed with count when between 0 and #{described_class::MAX_TRIES}" do
      (1..described_class::MAX_TRIES).each do |count|
        expect(suffixed_path.call(count)).to eq("backintime#{count}")
      end
    end

    it 'adds a "randomized" suffix when MAX_TRIES is exhausted', time_travel_to: '1955-11-12 06:38' do
      count = described_class::MAX_TRIES + 1
      expect(suffixed_path.call(count)).to eq("backintime3845")
    end

    it 'adds an offset to the  "randomized" suffix when MAX_TRIES is exhausted', time_travel_to: '1955-11-12 06:38' do
      count = described_class::MAX_TRIES + 2
      expect(suffixed_path.call(count)).to eq("backintime3846")
    end
  end
end
