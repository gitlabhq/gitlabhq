# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Validations::Validators::Absence do
  include ApiValidatorsHelpers

  subject do
    described_class.new(['test'], {}, false, scope.new)
  end

  context 'empty param' do
    it 'does not raise a validation error' do
      expect_no_validation_error({})
    end
  end

  context 'invalid parameters' do
    it 'raises a validation error' do
      expect_validation_error('test' => 'some_value')
    end
  end
end
