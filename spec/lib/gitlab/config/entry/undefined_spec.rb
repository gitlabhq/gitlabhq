# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Config::Entry::Undefined do
  let(:entry) { described_class.new }

  describe '#leaf?' do
    it 'is leaf node' do
      expect(entry).to be_leaf
    end
  end

  describe '#valid?' do
    it 'is always valid' do
      expect(entry).to be_valid
    end
  end

  describe '#errors' do
    it 'is does not contain errors' do
      expect(entry.errors).to be_empty
    end
  end

  describe '#value' do
    it 'returns nil' do
      expect(entry.value).to eq nil
    end
  end

  describe '#relevant?' do
    it 'is not relevant' do
      expect(entry.relevant?).to eq false
    end
  end

  describe '#specified?' do
    it 'is not defined' do
      expect(entry.specified?).to eq false
    end
  end

  describe '#type' do
    it 'returns nil' do
      expect(entry.type).to eq nil
    end
  end
end
