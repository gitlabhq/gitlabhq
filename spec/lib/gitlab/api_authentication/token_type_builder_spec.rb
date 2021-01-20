# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::APIAuthentication::TokenTypeBuilder do
  describe '#token_types' do
    it 'passes strategies and resolvers to SentThroughBuilder' do
      strategies = double
      resolvers = Array.new(3) { double }
      retval = double
      expect(Gitlab::APIAuthentication::SentThroughBuilder).to receive(:new).with(strategies, resolvers).and_return(retval)

      expect(described_class.new(strategies).token_types(*resolvers)).to be(retval)
    end
  end
end
