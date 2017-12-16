require 'spec_helper'

describe CheckGcpProjectBillingWorker do
  describe '.perform' do
    let(:token) { 'bogustoken' }
    subject { described_class.new.perform(token) }

    context 'when there is no lease' do
      before do
        allow_any_instance_of(CheckGcpProjectBillingWorker).to receive(:try_obtain_lease_for).and_return('randomuuid')
      end

      it 'calls the service' do
        expect(CheckGcpProjectBillingService).to receive_message_chain(:new, :execute)

        subject
      end

      it 'stores billing status in redis' do
        redis_double = double

        expect(CheckGcpProjectBillingService).to receive_message_chain(:new, :execute).and_return(true)
        expect(Gitlab::Redis::SharedState).to receive(:with).and_yield(redis_double)
        expect(redis_double).to receive(:set).with(CheckGcpProjectBillingWorker.redis_shared_state_key_for(token), anything)

        subject
      end
    end

    context 'when there is a lease' do
      before do
        allow_any_instance_of(CheckGcpProjectBillingWorker).to receive(:try_obtain_lease_for).and_return(false)
      end

      it 'does not call the service' do
        expect(CheckGcpProjectBillingService).not_to receive(:new)

        subject
      end
    end
  end
end
