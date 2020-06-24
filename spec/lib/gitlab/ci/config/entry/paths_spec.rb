# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Paths do
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

    context 'when entry value is not valid' do
      let(:config) { [1] }

      describe '#errors' do
        it 'saves errors' do
          expect(entry.errors)
            .to include 'paths config should be an array of strings'
        end
      end
    end
  end
end
