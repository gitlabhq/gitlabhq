# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Validations::Validators::ObjectElements, feature_category: :api do
  include ApiValidatorsHelpers

  subject(:validator) { described_class.new(['test'], true, false, scope.new, {}) }

  context 'with an array holding only objects' do
    it 'does not raise a validation error', :aggregate_failures do
      expect_no_validation_error('test' => [{ 'key' => 'FOO' }])
      expect_no_validation_error('test' => [{ key: 'FOO' }, { 'key' => 'BAR' }])
      expect_no_validation_error('test' => [{}])
    end

    # The shape Grape's default param builder produces for a request.
    it 'does not raise a validation error for objects with indifferent access' do
      expect_no_validation_error('test' => [{ key: 'FOO' }.with_indifferent_access])
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

  context 'with an element that is not an object' do
    it 'raises a validation error for a string' do
      expect_validation_error('test' => ['FOO=bar'])
    end

    it 'raises a validation error for an array' do
      expect_validation_error('test' => [%w[FOO bar]])
    end

    it 'raises a validation error for nil' do
      expect_validation_error('test' => [nil])
    end

    it 'raises a validation error for an integer' do
      expect_validation_error('test' => [42])
    end

    it 'names the position of the element, so a caller can find it', :aggregate_failures do
      expect { validate_test_param!('test' => [{ 'key' => 'FOO' }, 'BAR=1']) }
        .to raise_error(Grape::Exceptions::Validation) { |error|
          expect(error.params).to eq(['test[1]'])
          expect(error.message).to eq('is not an object')
        }
    end

    it 'names every offending position, rather than only the first' do
      expect { validate_test_param!('test' => ['FOO=1', { 'key' => 'BAR' }, nil]) }
        .to raise_error(Grape::Exceptions::Validation) { |error|
          expect(error.params).to match_array(['test[0]', 'test[2]'])
        }
    end
  end
end
