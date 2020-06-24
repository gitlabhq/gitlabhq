# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Script do
  let(:entry) { described_class.new(config) }

  describe 'validations' do
    context 'when entry config value is array of strings' do
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

    context 'when entry config value is array containing strings and arrays of strings' do
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

    context 'when entry value is string' do
      let(:config) { 'ls' }

      describe '#errors' do
        it 'saves errors' do
          expect(entry.errors)
            .to include 'script config should be an array containing strings and arrays of strings'
        end
      end

      describe '#valid?' do
        it 'is not valid' do
          expect(entry).not_to be_valid
        end
      end
    end

    context 'when entry value is multi-level nested array' do
      let(:config) { [['ls', ['echo 1']], 'pwd'] }

      describe '#errors' do
        it 'saves errors' do
          expect(entry.errors)
            .to include 'script config should be an array containing strings and arrays of strings'
        end
      end

      describe '#valid?' do
        it 'is not valid' do
          expect(entry).not_to be_valid
        end
      end
    end
  end
end
