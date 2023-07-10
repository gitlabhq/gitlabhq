# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Variables::Downstream::ExpandableVariableGenerator, feature_category: :secrets_management do
  let(:all_bridge_variables) do
    Gitlab::Ci::Variables::Collection.fabricate(
      [
        { key: 'REF1', value: 'ref 1' },
        { key: 'REF2', value: 'ref 2' }
      ]
    )
  end

  let(:context) do
    Gitlab::Ci::Variables::Downstream::Generator::Context.new(all_bridge_variables: all_bridge_variables)
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
  end
end
