# frozen_string_literal: true

require_relative 'rd_fast_spec_helper'

RSpec.describe RemoteDevelopment::MessageSupport, :rd_fast, feature_category: :remote_development do
  let(:extending_class) do
    Class.new do
      extend RemoteDevelopment::MessageSupport

      # @param [RemoteDevelopment::Message] message
      # @return [Hash]
      def self.execute(message)
        generate_error_response_from_message(message: message, reason: :does_not_matter)
      end
    end
  end

  let(:object) { Object.new.extend(described_class) }

  describe '.generate_error_response_from_message' do
    context 'for an unsupported content which is not pattern matched' do
      let(:message) { RemoteDevelopment::Message.new(content: { unsupported: 'unmatched' }) }

      it 'raises an error' do
        expect { extending_class.execute(message) }
          .to raise_error(/Unexpected message content/)
      end
    end
  end
end
