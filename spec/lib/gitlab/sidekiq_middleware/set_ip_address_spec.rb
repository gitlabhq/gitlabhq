# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::SetIpAddress, feature_category: :system_access do
  let(:worker) { instance_double(ApplicationWorker) }
  let(:job) { { 'meta.remote_ip' => ip_address } }
  let(:queue) { 'queue1' }
  let(:ip_address) { '1.1.1.1' }

  describe '#call' do
    it 'sets the IP address in the context' do
      described_class.new.call(worker, job, queue) do
        expect(::Gitlab::IpAddressState.current).to eq(ip_address)
      end

      expect(::Gitlab::IpAddressState.current).to eq(nil)
    end

    context 'when the IP address is absent' do
      let(:job) { {} }

      it 'does not set the IP address' do
        described_class.new.call(worker, job, queue) do
          expect(::Gitlab::IpAddressState.current).to eq(nil)
        end

        expect(::Gitlab::IpAddressState.current).to eq(nil)
      end
    end
  end

  describe '#call with sidekiq_ip_address disabled' do
    before do
      stub_feature_flags(sidekiq_ip_address: false)
    end

    context 'when the IP address is present' do
      it 'does not set the IP address' do
        described_class.new.call(worker, job, queue) do
          expect(::Gitlab::IpAddressState.current).to eq(nil)
        end

        expect(::Gitlab::IpAddressState.current).to eq(nil)
      end
    end
  end
end
