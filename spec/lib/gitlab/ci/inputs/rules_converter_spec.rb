# frozen_string_literal: true

require 'fast_spec_helper'

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

    context 'with chained OR operators' do
      it 'converts chained OR with 4 conditions correctly' do
        expression = '$[[ inputs.main_selector ]] == "Choice 1" || ' \
          '$[[ inputs.main_selector ]] == "Choice 2" || ' \
          '$[[ inputs.main_selector ]] == "Choice 3" || ' \
          '$[[ inputs.main_selector ]] == "Choice 4"'
        statement = Gitlab::Ci::Pipeline::Expression::Statement.new(expression)
        node = statement.parse_tree

        result = converter.convert(node)

        expect(result).to eq(
          'operator' => 'OR',
          'children' => [
            { 'operator' => 'equals', 'field' => 'main_selector', 'value' => 'Choice 1' },
            { 'operator' => 'equals', 'field' => 'main_selector', 'value' => 'Choice 2' },
            { 'operator' => 'equals', 'field' => 'main_selector', 'value' => 'Choice 3' },
            { 'operator' => 'equals', 'field' => 'main_selector', 'value' => 'Choice 4' }
          ]
        )
      end

      it 'converts chained OR with 6 conditions correctly' do
        expression = '$[[ inputs.main_selector ]] == "Choice 1" || ' \
          '$[[ inputs.main_selector ]] == "Choice 2" || ' \
          '$[[ inputs.main_selector ]] == "Choice 3" || ' \
          '$[[ inputs.main_selector ]] == "Choice 4" || ' \
          '$[[ inputs.main_selector ]] == "Choice 5" || ' \
          '$[[ inputs.main_selector ]] == "Choice 6"'
        statement = Gitlab::Ci::Pipeline::Expression::Statement.new(expression)
        node = statement.parse_tree

        result = converter.convert(node)

        expect(result).to eq(
          'operator' => 'OR',
          'children' => [
            { 'operator' => 'equals', 'field' => 'main_selector', 'value' => 'Choice 1' },
            { 'operator' => 'equals', 'field' => 'main_selector', 'value' => 'Choice 2' },
            { 'operator' => 'equals', 'field' => 'main_selector', 'value' => 'Choice 3' },
            { 'operator' => 'equals', 'field' => 'main_selector', 'value' => 'Choice 4' },
            { 'operator' => 'equals', 'field' => 'main_selector', 'value' => 'Choice 5' },
            { 'operator' => 'equals', 'field' => 'main_selector', 'value' => 'Choice 6' }
          ]
        )

        expect(result['children'].size).to eq(6)
        expect(result['children'].none? { |child| child['operator'] == 'OR' }).to be true
      end
    end

    context 'with chained AND operators' do
      it 'converts chained AND with 3 conditions correctly' do
        statement = Gitlab::Ci::Pipeline::Expression::Statement.new(
          '$[[ inputs.env ]] == "prod" && $[[ inputs.region ]] == "us" && $[[ inputs.tier ]] == "premium"'
        )
        node = statement.parse_tree

        result = converter.convert(node)

        expect(result).to eq(
          'operator' => 'AND',
          'children' => [
            { 'operator' => 'equals', 'field' => 'env', 'value' => 'prod' },
            { 'operator' => 'equals', 'field' => 'region', 'value' => 'us' },
            { 'operator' => 'equals', 'field' => 'tier', 'value' => 'premium' }
          ]
        )
      end
    end

    context 'with bug report example' do
      it 'correctly handles the param_1234 condition from issue #584832' do
        expression = '$[[ inputs.main_selector ]] == "Choice 1" || ' \
          '$[[ inputs.main_selector ]] == "Choice 2" || ' \
          '$[[ inputs.main_selector ]] == "Choice 3" || ' \
          '$[[ inputs.main_selector ]] == "Choice 4"'
        statement = Gitlab::Ci::Pipeline::Expression::Statement.new(expression)
        node = statement.parse_tree

        result = converter.convert(node)

        expect(result).to eq(
          'operator' => 'OR',
          'children' => [
            { 'operator' => 'equals', 'field' => 'main_selector', 'value' => 'Choice 1' },
            { 'operator' => 'equals', 'field' => 'main_selector', 'value' => 'Choice 2' },
            { 'operator' => 'equals', 'field' => 'main_selector', 'value' => 'Choice 3' },
            { 'operator' => 'equals', 'field' => 'main_selector', 'value' => 'Choice 4' }
          ]
        )

        expect(result['children'].size).to eq(4)
        expect(result['children'].none? { |child| child['operator'] == 'OR' }).to be true
      end
    end

    context 'with mixed chained operators' do
      it 'flattens chained ORs within an AND' do
        expression = '($[[ inputs.env ]] == "prod" || $[[ inputs.env ]] == "staging") && ' \
          '($[[ inputs.region ]] == "us" || $[[ inputs.region ]] == "eu")'
        statement = Gitlab::Ci::Pipeline::Expression::Statement.new(expression)
        node = statement.parse_tree

        result = converter.convert(node)

        expect(result).to eq(
          'operator' => 'AND',
          'children' => [
            {
              'operator' => 'OR',
              'children' => [
                { 'operator' => 'equals', 'field' => 'env', 'value' => 'prod' },
                { 'operator' => 'equals', 'field' => 'env', 'value' => 'staging' }
              ]
            },
            {
              'operator' => 'OR',
              'children' => [
                { 'operator' => 'equals', 'field' => 'region', 'value' => 'us' },
                { 'operator' => 'equals', 'field' => 'region', 'value' => 'eu' }
              ]
            }
          ]
        )
      end

      it 'flattens chained ANDs within an OR' do
        expression = '($[[ inputs.env ]] == "prod" && $[[ inputs.tier ]] == "premium") || ' \
          '($[[ inputs.env ]] == "staging" && $[[ inputs.tier ]] == "enterprise")'
        statement = Gitlab::Ci::Pipeline::Expression::Statement.new(expression)
        node = statement.parse_tree

        result = converter.convert(node)

        expect(result).to eq(
          'operator' => 'OR',
          'children' => [
            {
              'operator' => 'AND',
              'children' => [
                { 'operator' => 'equals', 'field' => 'env', 'value' => 'prod' },
                { 'operator' => 'equals', 'field' => 'tier', 'value' => 'premium' }
              ]
            },
            {
              'operator' => 'AND',
              'children' => [
                { 'operator' => 'equals', 'field' => 'env', 'value' => 'staging' },
                { 'operator' => 'equals', 'field' => 'tier', 'value' => 'enterprise' }
              ]
            }
          ]
        )
      end
    end
  end
end
