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

    context 'when entry value is not correct' do
      shared_examples 'invalid variables' do |message|
        describe '#errors' do
          it 'saves errors' do
            expect(entry.errors).to include(message)
          end
        end

        describe '#valid?' do
          it 'is not valid' do
            expect(entry).not_to be_valid
          end
        end
      end

      context 'with array' do
        let(:config) { [:VAR, 'test'] }

        it_behaves_like 'invalid variables', /should be a hash of key value pairs/
      end

      context 'with empty array' do
        let(:config) { { VAR: 'test', VAR2: [] } }

        it_behaves_like 'invalid variables', /should be a hash of key value pairs/
      end

      context 'with nested array' do
        let(:config) { { VAR: 'test', VAR2: [1, [2]] } }

        it_behaves_like 'invalid variables', /should be a hash of key value pairs/
      end

      context 'with only one variable' do
        let(:config) { { VAR: 'test' } }

        it_behaves_like 'invalid variables', /variables config requires at least 2 items/
      end
    end
  end
end
