# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Variables::Downstream::ExpandableVariableGenerator, feature_category: :ci_variables do
  let(:all_bridge_variables) do
    Gitlab::Ci::Variables::Collection.fabricate(
      [
        { key: 'REF1', value: 'ref 1' },
        { key: 'REF2', value: 'ref 2' },
        { key: 'NESTED_REF1', value: 'nested $REF1' }
      ]
    )
  end

  let(:expand_file_refs) { false }

  let(:context) do
    Gitlab::Ci::Variables::Downstream::Generator::Context.new(
      all_bridge_variables: all_bridge_variables,
      expand_file_refs: expand_file_refs
    )
  end

  subject(:generator) { described_class.new(context) }

  describe '#for' do
    context 'when given a variable without interpolation' do
      it 'returns an array containing the variable' do
        var = Gitlab::Ci::Variables::Collection::Item.fabricate({ key: 'VAR1', value: 'variable 1' })

        expect(generator.for(var)).to match_array([{ key: 'VAR1', value: 'variable 1' }])
      end
    end

    context 'when given a variable with interpolation' do
      it 'returns an array containing the expanded variables' do
        var = Gitlab::Ci::Variables::Collection::Item.fabricate({ key: 'VAR1', value: '$REF1 $REF2 $REF3' })

        expect(generator.for(var)).to match_array([{ key: 'VAR1', value: 'ref 1 ref 2 ' }])
      end
    end

    context 'when given a variable with nested interpolation' do
      it 'returns an array containing the expanded variables' do
        var = Gitlab::Ci::Variables::Collection::Item.fabricate({ key: 'VAR1', value: '$REF1 $REF2 $NESTED_REF1' })

        expect(generator.for(var)).to match_array([{ key: 'VAR1', value: 'ref 1 ref 2 nested $REF1' }])
      end
    end

    context 'when given a variable with expansion on a file variable' do
      let(:all_bridge_variables) do
        Gitlab::Ci::Variables::Collection.fabricate(
          [
            { key: 'REF1', value: 'ref 1' },
            { key: 'FILE_REF2', value: 'ref 2', file: true },
            { key: 'NESTED_REF3', value: 'ref 3 $REF1 and $FILE_REF2', file: true }
          ]
        )
      end

      context 'when expand_file_refs is false' do
        let(:expand_file_refs) { false }

        it 'returns an array containing the unexpanded variable and the file variable dependency' do
          var = { key: 'VAR1', value: '$REF1 $FILE_REF2 $FILE_REF3 $NESTED_REF3' }
          var = Gitlab::Ci::Variables::Collection::Item.fabricate(var)

          expected = [
            { key: 'VAR1', value: 'ref 1 $FILE_REF2  $NESTED_REF3' },
            { key: 'FILE_REF2', value: 'ref 2', variable_type: :file },
            { key: 'NESTED_REF3', value: 'ref 3 $REF1 and $FILE_REF2', variable_type: :file }
          ]

          expect(generator.for(var)).to match_array(expected)
        end
      end

      context 'when expand_file_refs is true' do
        let(:expand_file_refs) { true }

        it 'returns an array containing the expanded variables' do
          var = { key: 'VAR1', value: '$REF1 $FILE_REF2 $FILE_REF3 $NESTED_REF3' }
          var = Gitlab::Ci::Variables::Collection::Item.fabricate(var)

          expected = { key: 'VAR1', value: 'ref 1 ref 2  ref 3 $REF1 and $FILE_REF2' }
          expect(generator.for(var)).to contain_exactly(expected)
        end
      end
    end
  end
end
