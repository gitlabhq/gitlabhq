# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::LoopHelpers do
  let(:class_instance) { (Class.new { include ::Gitlab::LoopHelpers }).new }

  describe '#loop_until' do
    subject do
      class_instance.loop_until(**params) { true }
    end

    context 'when limit is not given' do
      let(:params) { { limit: nil } }

      it 'raises an error' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'when timeout is specified' do
      let(:params) { { timeout: 1.second } }

      it "returns false after it's expired" do
        is_expected.to be_falsy
      end

      it 'executes the block at least once' do
        expect { |b| class_instance.loop_until(**params, &b) }
          .to yield_control.at_least(1)
      end
    end

    context 'when iteration limit is specified' do
      let(:params) { { limit: 1 } }

      it "returns false after it's expired" do
        is_expected.to be_falsy
      end

      it 'executes the block once' do
        expect { |b| class_instance.loop_until(**params, &b) }
          .to yield_control.once
      end
    end
  end
end
