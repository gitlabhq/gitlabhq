# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Config::Entry::Unspecified do
  let(:unspecified) { described_class.new(entry) }
  let(:entry) { spy('Entry') }

  describe '#valid?' do
    it 'delegates method to entry' do
      expect(unspecified.valid?).to eq entry
    end
  end

  describe '#errors' do
    it 'delegates method to entry' do
      expect(unspecified.errors).to eq entry
    end
  end

  describe '#value' do
    it 'delegates method to entry' do
      expect(unspecified.value).to eq entry
    end
  end

  describe '#specified?' do
    it 'is always false' do
      allow(entry).to receive(:specified?).and_return(true)

      expect(unspecified.specified?).to be false
    end
  end
end
