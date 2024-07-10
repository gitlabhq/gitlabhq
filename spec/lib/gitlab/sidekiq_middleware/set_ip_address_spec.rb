# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::SetIpAddress, feature_category: :system_access do
  let(:worker) { instance_double(ApplicationWorker) }
  let(:job) { { 'ip_address_state' => ip_address } }
  let(:queue) { 'queue1' }
  let(:ip_address) { '1.1.1.1' }

  describe '#call' do
    it 'sets the IP address based on ip_address_state' do
      expect(::Gitlab::IpAddressState).to receive(:with).once.and_call_original

      described_class.new.call(worker, job, queue) do
        expect(::Gitlab::IpAddressState.current).to eq(ip_address)
      end

      expect(::Gitlab::IpAddressState.current).to eq(nil)
    end

    context 'when the ip_address_state key is absent' do
      let(:job) { {} }

      it 'does not set the IP address' do
        expect(::Gitlab::IpAddressState).not_to receive(:with).with(ip_address)

        described_class.new.call(worker, job, queue) do
          expect(::Gitlab::IpAddressState.current).to eq(nil)
        end

        expect(::Gitlab::IpAddressState.current).to eq(nil)
      end
    end

    context 'when ip_address_state value is nil' do
      let(:job) { { 'ip_address_state' => nil } }

      it 'sets IP address to be nil' do
        expect(::Gitlab::IpAddressState).to receive(:with).once.and_call_original

        described_class.new.call(worker, job, queue) do
          expect(::Gitlab::IpAddressState.current).to eq(nil)
        end

        expect(::Gitlab::IpAddressState.current).to eq(nil)
      end
    end
  end
end
