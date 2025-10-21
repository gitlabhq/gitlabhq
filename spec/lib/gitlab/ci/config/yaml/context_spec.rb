# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Ci::Config::Yaml::Context, feature_category: :pipeline_composition do
  describe '#initialize' do
    context 'with variables provided' do
      let(:variables) do
        Gitlab::Ci::Variables::Collection.new([
          { key: 'TEST_VAR', value: 'test_value', masked: false },
          { key: 'MASKED_VAR', value: 'secret', masked: true }
        ])
      end

      subject(:context) { described_class.new(variables: variables) }

      it 'stores the variables' do
        expect(context.variables).to eq(variables)
      end
    end

    context 'without variables provided' do
      subject(:context) { described_class.new }

      it 'defaults to empty array' do
        expect(context.variables).to eq([])
      end
    end

    context 'with component data provided' do
      let(:component_data) do
        { name: 'my-component', sha: 'abc123', version: '1.0.0' }
      end

      subject(:context) { described_class.new(component: component_data) }

      it 'stores the component data' do
        expect(context.component).to eq(component_data)
      end
    end
  end

  describe '#variables' do
    let(:variables) do
      Gitlab::Ci::Variables::Collection.new([
        { key: 'CI_COMMIT_SHA', value: 'abc123', masked: false }
      ])
    end

    subject(:context) { described_class.new(variables: variables) }

    it 'returns the variables' do
      expect(context.variables).to eq(variables)
    end
  end

  describe '#component' do
    let(:component_data) do
      { name: 'test-component', sha: 'def456', version: '2.0.0' }
    end

    subject(:context) { described_class.new(component: component_data) }

    it 'returns the component data' do
      expect(context.component).to eq(component_data)
    end
  end
end
