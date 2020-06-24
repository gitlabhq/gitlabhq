# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::Stage do
  let(:stage) { described_class.new(config) }

  describe 'validations' do
    context 'when stage config value is correct' do
      let(:config) { 'build' }

      describe '#value' do
        it 'returns a stage key' do
          expect(stage.value).to eq config
        end
      end

      describe '#valid?' do
        it 'is valid' do
          expect(stage).to be_valid
        end
      end
    end

    context 'when value has a wrong type' do
      let(:config) { { test: true } }

      it 'reports errors about wrong type' do
        expect(stage.errors)
          .to include 'stage config should be a string'
      end
    end
  end

  describe '.default' do
    it 'returns default stage' do
      expect(described_class.default).to eq 'test'
    end
  end
end
