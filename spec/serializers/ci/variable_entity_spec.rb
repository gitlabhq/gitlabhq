# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::VariableEntity do
  let(:variable) { build(:ci_variable) }
  let(:entity) { described_class.new(variable) }

  describe '#as_json' do
    subject { entity.as_json }

    it 'contains required fields' do
      expect(subject.keys).to contain_exactly(
        :id, :key, :description, :value, :protected, :environment_scope, :variable_type, :raw, :masked, :hidden
      )
    end

    context 'with a hidden variable' do
      let(:variable) { build(:ci_variable, hidden: true, masked: true, key: 'hidden', value: 'hiddenvalue') }

      it 'returns nil for value' do
        expect(subject[:key]).to eq('hidden')
        expect(subject[:value]).to be_nil
      end
    end

    context 'without a hidden variable' do
      it 'returns the value' do
        expect(subject[:value]).to be('VARIABLE_VALUE')
      end
    end
  end
end
