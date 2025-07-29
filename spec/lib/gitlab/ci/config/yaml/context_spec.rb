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

      it 'defaults to empty hash' do
        expect(context.variables).to eq([])
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
end
