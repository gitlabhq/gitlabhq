# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Memory::Reports::HeapDump do
  describe '.write_conditionally' do
    subject(:call) { described_class.write_conditionally }

    context 'when no heap dump is enqueued' do
      it 'does nothing and returns false' do
        expect(call).to be(false)
      end
    end

    context 'when a heap dump is enqueued' do
      it 'does nothing and returns true' do
        described_class.enqueue!

        expect(call).to be(true)
      end
    end
  end
end
