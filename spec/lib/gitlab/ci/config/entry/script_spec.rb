# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Script do
  let(:entry) { described_class.new(config) }

  describe 'validations' do
    context 'when entry config value is correct' do
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

    context 'when entry value is not correct' do
      let(:config) { 'ls' }

      describe '#errors' do
        it 'saves errors' do
          expect(entry.errors)
            .to include 'script config should be an array of strings'
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
