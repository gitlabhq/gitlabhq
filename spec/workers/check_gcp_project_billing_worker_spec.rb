require 'spec_helper'

describe CheckGcpProjectBillingWorker do
  describe '.perform' do
    let(:token) { 'bogustoken' }
    subject { described_class.new.perform(token) }

    it 'calls the service' do
      expect(CheckGcpProjectBillingService).to receive_message_chain(:new, :execute)

      subject
    end

    it 'stores billing status in redis' do
      expect(CheckGcpProjectBillingService).to receive_message_chain(:new, :execute).and_return(true)
      subject

      Gitlab::Redis::SharedState.with do |redis|
        expect(redis.get("gitlab:gcp:#{token}:billing_enabled")).to eq('true')
      end
    end
  end
end
