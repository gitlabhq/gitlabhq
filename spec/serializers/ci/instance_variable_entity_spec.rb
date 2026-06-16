# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::InstanceVariableEntity, feature_category: :pipeline_composition do
  let(:variable) { build(:ci_instance_variable) }
  let(:entity) { described_class.new(variable) }

  describe '#as_json' do
    subject(:json) { entity.as_json }

    it 'contains required fields' do
      expect(json.keys).to contain_exactly(
        :id, :key, :description, :value, :protected, :variable_type, :raw, :masked, :hidden
      )
    end

    context 'with a hidden variable' do
      let(:variable) do
        build(:ci_instance_variable, hidden: true, masked: true, key: 'HIDDEN_VAR', value: 'hiddenvalue')
      end

      it 'returns nil for value' do
        expect(json[:key]).to eq('HIDDEN_VAR')
        expect(json[:value]).to be_nil
      end
    end

    context 'without a hidden variable' do
      it 'returns the value' do
        expect(json[:value]).to eq(variable.value)
      end
    end
  end
end
