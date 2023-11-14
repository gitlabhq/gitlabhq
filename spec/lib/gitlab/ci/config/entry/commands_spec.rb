# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Commands do
  let(:entry) { described_class.new(config) }

  context 'when entry config value is an array of strings' do
    let(:config) { %w[ls pwd] }

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

  context 'when entry config value is array of arrays of strings' do
    let(:config) { [['ls'], ['pwd', 'echo 1']] }

    describe '#value' do
      it 'returns array of strings' do
        expect(entry.value).to eq ['ls', 'pwd', 'echo 1']
      end
    end

    describe '#errors' do
      it 'does not append errors' do
        expect(entry.errors).to be_empty
      end
    end

    describe '#valid?' do
      it 'is valid' do
        expect(entry).to be_valid
      end
    end
  end

  context 'when entry config value is array of strings and arrays of strings' do
    let(:config) { ['ls', ['pwd', 'echo 1']] }

    describe '#value' do
      it 'returns array of strings' do
        expect(entry.value).to eq ['ls', 'pwd', 'echo 1']
      end
    end

    describe '#errors' do
      it 'does not append errors' do
        expect(entry.errors).to be_empty
      end
    end

    describe '#valid?' do
      it 'is valid' do
        expect(entry).to be_valid
      end
    end
  end

  context 'when entry value is integer' do
    let(:config) { 1 }

    describe '#errors' do
      it 'saves errors' do
        expect(entry.errors)
          .to include 'commands config should be a string or a nested array of strings up to 10 levels deep'
      end
    end
  end

  context 'when entry value is multi-level nested array' do
    let(:config) do
      ['ls 0', ['ls 1', ['ls 2', ['ls 3', ['ls 4', ['ls 5', ['ls 6', ['ls 7', ['ls 8', ['ls 9', ['ls 10']]]]]]]]]]]
    end

    describe '#errors' do
      it 'saves errors' do
        expect(entry.errors)
          .to include 'commands config should be a string or a nested array of strings up to 10 levels deep'
      end
    end

    describe '#valid?' do
      it 'is not valid' do
        expect(entry).not_to be_valid
      end
    end
  end
end
