# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Inputs::RulesConverter, feature_category: :pipeline_composition do
  let(:converter) { described_class.new }

  describe '#convert' do
    context 'with nil node' do
      it 'returns nil' do
        expect(converter.convert(nil)).to be_nil
      end
    end

    context 'with equals operator' do
      it 'converts to equals structure' do
        statement = Gitlab::Ci::Pipeline::Expression::Statement.new('$[[ inputs.env ]] == "prod"')
        node = statement.parse_tree

        result = converter.convert(node)

        expect(result).to eq(
          'operator' => 'equals',
          'field' => 'env',
          'value' => 'prod'
        )
      end
    end

    context 'with not_equals operator' do
      it 'converts to not_equals structure' do
        statement = Gitlab::Ci::Pipeline::Expression::Statement.new('$[[ inputs.env ]] != "dev"')
        node = statement.parse_tree

        result = converter.convert(node)

        expect(result).to eq(
          'operator' => 'not_equals',
          'field' => 'env',
          'value' => 'dev'
        )
      end
    end

    context 'with AND operator' do
      it 'converts to AND structure with children' do
        statement = Gitlab::Ci::Pipeline::Expression::Statement.new(
          '$[[ inputs.env ]] == "prod" && $[[ inputs.region ]] == "us"'
        )
        node = statement.parse_tree

        result = converter.convert(node)

        expect(result).to eq(
          'operator' => 'AND',
          'children' => [
            { 'operator' => 'equals', 'field' => 'env', 'value' => 'prod' },
            { 'operator' => 'equals', 'field' => 'region', 'value' => 'us' }
          ]
        )
      end
    end

    context 'with OR operator' do
      it 'converts to OR structure with children' do
        statement = Gitlab::Ci::Pipeline::Expression::Statement.new(
          '$[[ inputs.env ]] == "prod" || $[[ inputs.env ]] == "staging"'
        )
        node = statement.parse_tree

        result = converter.convert(node)

        expect(result).to eq(
          'operator' => 'OR',
          'children' => [
            { 'operator' => 'equals', 'field' => 'env', 'value' => 'prod' },
            { 'operator' => 'equals', 'field' => 'env', 'value' => 'staging' }
          ]
        )
      end
    end

    context 'with nested operators' do
      it 'converts nested AND/OR correctly' do
        statement = Gitlab::Ci::Pipeline::Expression::Statement.new(
          '($[[ inputs.env ]] == "prod" && $[[ inputs.region ]] == "us") || $[[ inputs.env ]] == "dev"'
        )
        node = statement.parse_tree

        result = converter.convert(node)

        expect(result).to eq(
          'operator' => 'OR',
          'children' => [
            {
              'operator' => 'AND',
              'children' => [
                { 'operator' => 'equals', 'field' => 'env', 'value' => 'prod' },
                { 'operator' => 'equals', 'field' => 'region', 'value' => 'us' }
              ]
            },
            { 'operator' => 'equals', 'field' => 'env', 'value' => 'dev' }
          ]
        )
      end
    end
  end
end
