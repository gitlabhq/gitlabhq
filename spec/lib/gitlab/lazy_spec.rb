# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Lazy do
  let(:dummy) { double(:dummy) }

  context 'when not calling any methods' do
    it 'does not call the supplied block' do
      expect(dummy).not_to receive(:foo)

      described_class.new { dummy.foo }
    end
  end

  context 'when calling a method on the object' do
    it 'lazy loads the value returned by the block' do
      expect(dummy).to receive(:foo).and_return('foo')

      lazy = described_class.new { dummy.foo }

      expect(lazy.to_s).to eq('foo')
    end
  end

  describe '#respond_to?' do
    it 'returns true for a method defined on the wrapped object' do
      lazy = described_class.new { 'foo' }

      expect(lazy).to respond_to(:downcase)
    end

    it 'returns false for a method not defined on the wrapped object' do
      lazy = described_class.new { 'foo' }

      expect(lazy).not_to respond_to(:quack)
    end
  end
end
