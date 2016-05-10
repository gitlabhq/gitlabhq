require 'spec_helper'

describe Gitlab::Lazy, lib: true do
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
end
