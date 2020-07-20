# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Validations::Validators::IntegerNoneAny do
  include ApiValidatorsHelpers

  subject do
    described_class.new(['test'], {}, false, scope.new)
  end

  context 'valid parameters' do
    it 'does not raise a validation error' do
      expect_no_validation_error('test' => 2)
      expect_no_validation_error('test' => 100)
      expect_no_validation_error('test' => 'None')
      expect_no_validation_error('test' => 'Any')
      expect_no_validation_error('test' => 'none')
      expect_no_validation_error('test' => 'any')
    end
  end

  context 'invalid parameters' do
    it 'raises a validation error' do
      expect_validation_error({ 'test' => 'some_other_string' })
    end
  end
end
