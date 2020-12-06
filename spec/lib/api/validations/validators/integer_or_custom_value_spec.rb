# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Validations::Validators::IntegerOrCustomValue do
  include ApiValidatorsHelpers

  let(:custom_values) { %w[None Any Started Current] }

  subject { described_class.new(['test'], { values: custom_values }, false, scope.new) }

  context 'valid parameters' do
    it 'does not raise a validation error' do
      expect_no_validation_error('test' => 2)
      expect_no_validation_error('test' => 100)
      expect_no_validation_error('test' => 'None')
      expect_no_validation_error('test' => 'Any')
      expect_no_validation_error('test' => 'none')
      expect_no_validation_error('test' => 'any')
      expect_no_validation_error('test' => 'started')
      expect_no_validation_error('test' => 'CURRENT')
    end

    context 'when custom values is empty and value is an integer' do
      let(:custom_values) { [] }

      it 'does not raise a validation error' do
        expect_no_validation_error({ 'test' => 5 })
      end
    end
  end

  context 'invalid parameters' do
    it 'raises a validation error' do
      expect_validation_error({ 'test' => 'Upcomming' })
    end

    context 'when custom values is empty and value is not an integer' do
      let(:custom_values) { [] }

      it 'raises a validation error' do
        expect_validation_error({ 'test' => '5' })
      end
    end
  end
end
