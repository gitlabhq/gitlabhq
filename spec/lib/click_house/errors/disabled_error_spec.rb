# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Errors::DisabledError, feature_category: :database do
  describe '#initialize' do
    it 'initializes with a default message' do
      error = described_class.new
      expect(error.message).to eq('ClickHouse analytics database is not enabled')
    end

    it 'initializes with a custom message' do
      custom_message = 'Custom error message'
      error = described_class.new(msg: custom_message)
      expect(error.message).to eq(custom_message)
    end
  end

  describe 'inheritance' do
    it 'inherits from StandardError' do
      expect(described_class.superclass).to eq(StandardError)
    end
  end

  describe 'error behavior' do
    it 'can be raised and rescued' do
      expect do
        raise described_class
      rescue described_class => e
        expect(e.message).to eq('ClickHouse analytics database is not enabled')
        raise e
      end.to raise_error(described_class)
    end

    it 'can be raised with a custom message' do
      custom_message = 'ClickHouse is not available'
      expect do
        raise described_class.new(msg: custom_message)
      end.to raise_error(described_class, custom_message)
    end
  end
end
