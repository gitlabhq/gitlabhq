# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Stages do
  let(:entry) { described_class.new(config) }

  describe 'validations' do
    context 'when entry config value is array of strings' do
      let(:config) { [:stage1, :stage2] }

      describe '#value' do
        it 'returns array of stages' do
          expect(entry.value).to eq config
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when entry config value is nested array of strings' do
      let(:config) { [:stage1, [:stage2, :stage3], :stage4, [:stage5]] }

      describe '#value' do
        it 'returns array of stages' do
          expect(entry.value).to eq [:stage1, :stage2, :stage3, :stage4, :stage5]
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
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
            .to include 'stages config should be an array of strings or a nested array of strings up to 10 levels deep'
        end
      end

      describe '#valid?' do
        it 'is not valid' do
          expect(entry).not_to be_valid
        end
      end
    end

    context 'when entry value is not correct' do
      let(:config) { { test: true } }

      describe '#errors' do
        it 'saves errors' do
          expect(entry.errors)
            .to include 'stages config should be an array of strings or a nested array of strings up to 10 levels deep'
        end
      end

      describe '#valid?' do
        it 'is not valid' do
          expect(entry).not_to be_valid
        end
      end
    end
  end

  describe '.default' do
    it 'returns default stages' do
      expect(described_class.default).to eq %w[.pre build test deploy .post]
    end
  end
end
