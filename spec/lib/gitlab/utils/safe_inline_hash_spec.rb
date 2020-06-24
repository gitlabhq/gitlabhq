# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Utils::SafeInlineHash do
  describe '.merge_keys!' do
    let(:source) { { 'foo' => { 'bar' => 'baz' } } }
    let(:validator) { instance_double(Gitlab::Utils::DeepSize, valid?: valid) }

    subject { described_class.merge_keys!(source, prefix: 'safe', connector: '::') }

    before do
      allow(Gitlab::Utils::DeepSize)
        .to receive(:new)
        .with(source)
        .and_return(validator)
    end

    context 'when hash is too big' do
      let(:valid) { false }

      it 'raises an exception' do
        expect { subject }.to raise_error ArgumentError, 'The Hash is too big'
      end
    end

    context 'when hash has an acceptaable size' do
      let(:valid) { true }

      it 'returns a result of InlineHash' do
        is_expected.to eq('safe::foo::bar' => 'baz')
      end
    end
  end
end
