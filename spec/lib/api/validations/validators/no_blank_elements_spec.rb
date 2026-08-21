# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Validations::Validators::NoBlankElements, feature_category: :api do
  include ApiValidatorsHelpers

  subject(:validator) { described_class.new(['test'], true, false, scope.new, {}) }

  context 'with an array holding no blank element' do
    it 'does not raise a validation error', :aggregate_failures do
      expect_no_validation_error('test' => [{ 'type' => 'custom' }])
      expect_no_validation_error('test' => [{ 'type' => 'custom' }, { 'type' => 'calendar' }])
      expect_no_validation_error('test' => ['a'])
    end

    it 'does not raise a validation error for zero, which Rails does not treat as blank' do
      expect_no_validation_error('test' => [0])
    end
  end

  context 'with an empty array' do
    it 'does not raise a validation error, since it holds nothing to reject' do
      expect_no_validation_error('test' => [])
    end
  end

  context 'with a value that is not an array' do
    it 'does not raise a validation error, leaving the type to the type validator', :aggregate_failures do
      expect_no_validation_error('test' => nil)
      expect_no_validation_error('test' => 'a')
      expect_no_validation_error('test' => {})
    end
  end

  context 'with a blank element' do
    it 'raises a validation error for an empty string' do
      expect_validation_error('test' => [''])
    end

    it 'raises a validation error for an empty hash' do
      expect_validation_error('test' => [{}])
    end

    it 'raises a validation error for nil' do
      expect_validation_error('test' => [nil])
    end

    it 'raises a validation error for an empty array' do
      expect_validation_error('test' => [[]])
    end

    it 'raises a validation error for false, which Rails treats as blank' do
      expect_validation_error('test' => [false])
    end

    it 'names the position of the blank element, so a caller can find it', :aggregate_failures do
      expect { validate_test_param!('test' => [{ 'type' => 'custom' }, '']) }
        .to raise_error(Grape::Exceptions::Validation) { |error|
          expect(error.params).to eq(['test[1]'])
          expect(error.message).to eq('is blank')
        }
    end

    it 'names every blank position, rather than only the first' do
      expect { validate_test_param!('test' => ['', { 'type' => 'custom' }, {}]) }
        .to raise_error(Grape::Exceptions::Validation) { |error|
          expect(error.params).to match_array(['test[0]', 'test[2]'])
        }
    end
  end
end
