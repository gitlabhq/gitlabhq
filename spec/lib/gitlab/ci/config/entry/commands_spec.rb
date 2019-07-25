# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Commands do
  let(:entry) { described_class.new(config) }

  context 'when entry config value is an array' do
    let(:config) { %w(ls pwd) }

    describe '#value' do
      it 'returns array of strings' do
        expect(entry.value).to eq config
      end
    end

    describe '#errors' do
      it 'does not append errors' do
        expect(entry.errors).to be_empty
      end
    end
  end

  context 'when entry config value is a string' do
    let(:config) { 'ls' }

    describe '#value' do
      it 'returns array with single element' do
        expect(entry.value).to eq ['ls']
      end
    end

    describe '#valid?' do
      it 'is valid' do
        expect(entry).to be_valid
      end
    end
  end

  context 'when entry value is not valid' do
    let(:config) { 1 }

    describe '#errors' do
      it 'saves errors' do
        expect(entry.errors)
          .to include 'commands config should be an array of strings or a string'
      end
    end
  end
end
