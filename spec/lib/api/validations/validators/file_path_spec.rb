# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Validations::Validators::FilePath do
  include ApiValidatorsHelpers

  subject do
    described_class.new(['test'], {}, false, scope.new)
  end

  context 'valid file path' do
    it 'does not raise a validation error' do
      expect_no_validation_error('test' => './foo')
      expect_no_validation_error('test' => './bar.rb')
      expect_no_validation_error('test' => 'foo%2Fbar%2Fnew%2Ffile.rb')
      expect_no_validation_error('test' => 'foo%2Fbar%2Fnew')
      expect_no_validation_error('test' => 'foo%252Fbar%252Fnew%252Ffile.rb')
    end
  end

  context 'invalid file path' do
    it 'raise a validation error' do
      expect_validation_error('test' => '../foo')
      expect_validation_error('test' => '../')
      expect_validation_error('test' => 'foo/../../bar')
      expect_validation_error('test' => 'foo/../')
      expect_validation_error('test' => 'foo/..')
      expect_validation_error('test' => '../')
      expect_validation_error('test' => '..\\')
      expect_validation_error('test' => '..\/')
      expect_validation_error('test' => '%2e%2e%2f')
      expect_validation_error('test' => '/etc/passwd')
    end
  end
end
