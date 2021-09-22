# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Validations::Validators::ProjectPortable do
  include ApiValidatorsHelpers

  let(:portable) { 'labels' }
  let(:not_portable) { 'project_members' }

  subject do
    described_class.new(['test'], {}, false, scope.new)
  end

  context 'valid portable' do
    it 'does not raise a validation error' do
      expect_no_validation_error('test' => portable)
    end
  end

  context 'empty params' do
    it 'raises a validation error' do
      expect_validation_error('test' => nil)
      expect_validation_error('test' => '')
    end
  end

  context 'not portable' do
    it 'raises a validation error' do
      expect_validation_error('test' => not_portable) # Sha length > 40
    end
  end
end
