# frozen_string_literal: true

require 'fast_spec_helper'
require_dependency 'active_model'

RSpec.describe Gitlab::Ci::Config::Entry::Product::Variables do
  let(:entry) { described_class.new(config) }

  describe 'validations' do
    context 'when entry config value is correct' do
      let(:config) do
        {
          'VARIABLE_1' => 1,
          'VARIABLE_2' => 'value 2',
          'VARIABLE_3' => :value_3,
          :VARIABLE_4 => 'value 4',
          5 => ['value 5'],
          'VARIABLE_6' => ['value 6']
        }
      end

      describe '#value' do
        it 'returns hash with key value strings' do
          expect(entry.value).to match({
            'VARIABLE_1' => ['1'],
            'VARIABLE_2' => ['value 2'],
            'VARIABLE_3' => ['value_3'],
            'VARIABLE_4' => ['value 4'],
            '5' => ['value 5'],
            'VARIABLE_6' => ['value 6']
          })
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

    context 'with only one variable' do
      let(:config) { { VAR: 'test' } }

      describe '#valid?' do
        it 'is valid' do
          expect(entry).to be_valid
        end
      end

      describe '#errors' do
        it 'does not append errors' do
          expect(entry.errors).to be_empty
        end
      end
    end
  end
end
