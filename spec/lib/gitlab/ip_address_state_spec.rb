# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::IpAddressState, feature_category: :system_access do
  let(:address) { '1.1.1.1' }

  describe '.with' do
    it 'saves IP address' do
      described_class.with(address) do
        expect(Thread.current[described_class::THREAD_KEY]).to eq(address)
      end
    end

    it 'clears IP address after execution' do
      described_class.with(address) {} # rubocop: disable Lint/EmptyBlock -- wrapper which requires a block

      expect(Thread.current[described_class::THREAD_KEY]).to eq(nil)
    end

    it 'clears IP address after execution even when exception occurred' do
      expect do
        described_class.with(address) { raise 'boom!' }
      end.to raise_error(StandardError)

      expect(Thread.current[described_class::THREAD_KEY]).to eq(nil)
    end
  end

  describe '.set_address' do
    it 'saves IP address' do
      described_class.set_address(address) do
        expect(Thread.current[described_class::THREAD_KEY]).to eq(address)
      end
    end
  end

  describe '.nullify_address' do
    it 'clears IP address' do
      described_class.nullify_address do
        expect(Thread.current[described_class::THREAD_KEY]).to eq(nil)
      end
    end
  end
end
