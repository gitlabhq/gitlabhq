# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SignatureType do
  describe '#type' do
    context 'when class does not define a type method' do
      subject(:implementation) { Class.new.include(described_class).new }

      it 'raises a NoMethodError with custom message' do
        expect { implementation.type }.to raise_error(NoMethodError, 'must implement `type` method')
      end
    end
  end
end
