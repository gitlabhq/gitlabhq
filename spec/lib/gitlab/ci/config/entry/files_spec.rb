# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Files do
  let(:entry) { described_class.new(config) }

  describe 'validations' do
    context 'when entry config value is valid' do
      let(:config) { ['some/file', 'some/path/'] }

      describe '#value' do
        it 'returns key value' do
          expect(entry.value).to eq config
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    describe '#errors' do
      context 'when entry value is not an array' do
        let(:config) { 'string' }

        it 'saves errors' do
          expect(entry.errors)
            .to include 'files config should be an array of strings'
        end
      end

      context 'when entry value is not an array of strings' do
        let(:config) { [1] }

        it 'saves errors' do
          expect(entry.errors)
            .to include 'files config should be an array of strings'
        end
      end

      context 'when entry value contains more than two values' do
        let(:config) { %w[file1 file2 file3] }

        it 'saves errors' do
          expect(entry.errors)
            .to include 'files config has too many items (maximum is 2)'
        end
      end
    end
  end
end
