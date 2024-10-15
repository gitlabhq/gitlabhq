# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Utils::ErrorMessage, feature_category: :observability do
  let(:klass) do
    Class.new do
      include Gitlab::Utils::ErrorMessage
    end
  end

  let(:message) { 'Something went wrong' }

  subject(:object) { klass.new }

  describe '#to_user_facing' do
    it 'returns a user-facing error message with the UF prefix' do
      expect(described_class.to_user_facing(message)).to eq("UF #{message}")
    end
  end

  describe '#prefixed_error_message' do
    it 'returns a message with the given prefix' do
      prefix = 'ERROR'
      expect(described_class.prefixed_error_message(message, prefix)).to eq("#{prefix} #{message}")
    end
  end
end
