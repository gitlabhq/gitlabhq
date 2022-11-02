# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Validations::Validators::Limit do
  include ApiValidatorsHelpers

  subject do
    described_class.new(['test'], 255, false, scope.new)
  end

  context 'valid limit param' do
    it 'does not raise a validation error' do
      expect_no_validation_error('test' => '123-456')
      expect_no_validation_error('test' => '00000000-ffff-0000-ffff-000000000000')
      expect_no_validation_error('test' => 'a' * 255)
    end
  end

  context 'longer than limit param' do
    it 'raises a validation error' do
      expect_validation_error('test' => 'a' * 256)
    end
  end

  context 'value is nil' do
    it 'does not raise a validation error' do
      expect_no_validation_error('test' => nil)
    end
  end
end
