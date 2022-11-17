# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Validations::Validators::EmailOrEmailList do
  include ApiValidatorsHelpers

  subject do
    described_class.new(['email'], {}, false, scope.new)
  end

  context 'with valid email addresses' do
    it 'does not raise a validation error' do
      expect_no_validation_error('test' => 'test@example.org')
      expect_no_validation_error('test' => 'test1@example.com,test2@example.org')
      expect_no_validation_error('test' => 'test1@example.com,test2@example.org,test3@example.co.uk')
      expect_no_validation_error('test' => %w[test1@example.com test2@example.org test3@example.co.uk])
    end
  end

  context 'including any invalid email address' do
    it 'raises a validation error' do
      expect_validation_error('test' => 'not')
      expect_validation_error('test' => '@example.com')
      expect_validation_error('test' => 'test1@example.com,asdf')
      expect_validation_error('test' => 'asdf,testa1@example.com,asdf')
      expect_validation_error('test' => %w[asdf testa1@example.com asdf])
    end
  end
end
