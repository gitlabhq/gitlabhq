# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Config::Entry::Boolean do
  let(:entry) { described_class.new(config) }

  describe 'validations' do
    context 'when entry config value is valid' do
      let(:config) { false }

      describe '#value' do
        it 'returns key value' do
          expect(entry.value).to eq false
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end
    end

    context 'when entry value is not valid' do
      let(:config) { ['incorrect'] }

      describe '#errors' do
        it 'saves errors' do
          expect(entry.errors)
            .to include 'boolean config should be a boolean value'
        end
      end
    end
  end
end
