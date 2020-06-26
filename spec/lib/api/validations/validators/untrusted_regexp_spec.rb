# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Validations::Validators::UntrustedRegexp do
  include ApiValidatorsHelpers

  subject do
    described_class.new(['test'], {}, false, scope.new)
  end

  context 'valid regex' do
    it 'does not raise a validation error' do
      expect_no_validation_error('test' => 'test')
      expect_no_validation_error('test' => '.*')
      expect_no_validation_error('test' => Gitlab::Regex.environment_name_regex_chars)
    end
  end

  context 'invalid regex' do
    it 'raises a validation error' do
      expect_validation_error('test' => '[')
      expect_validation_error('test' => '*foobar')
      expect_validation_error('test' => '?foobar')
      expect_validation_error('test' => '\A[^/%\s]+(..\z')
    end
  end
end
