# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Fp::MessageSupport, feature_category: :shared do
  let(:extending_class) do
    Class.new do
      extend Gitlab::Fp::MessageSupport

      # @param [Gitlab::Fp::Message] message
      # @return [Hash]
      def self.execute(message)
        generate_error_response_from_message(message: message, reason: :does_not_matter)
      end
    end
  end

  let(:object) { Object.new.extend(described_class) }

  describe '.generate_error_response_from_message' do
    context 'for an unsupported content which is not pattern matched' do
      let(:message) { Gitlab::Fp::Message.new(content: { unsupported: 'unmatched' }) }

      it 'raises an error' do
        expect { extending_class.execute(message) }
          .to raise_error(/Unexpected message content/)
      end
    end
  end
end
