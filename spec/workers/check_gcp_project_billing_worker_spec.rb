require 'spec_helper'

describe CheckGcpProjectBillingWorker do
  describe '.perform' do
    let(:token) { 'bogustoken' }

    subject { described_class.new.perform('token_key') }

    before do
      allow_any_instance_of(described_class).to receive(:check_previous_state)
      allow_any_instance_of(described_class).to receive(:update_billing_change_counter)
    end

    context 'when there is a token in redis' do
      before do
        allow(described_class).to receive(:get_session_token).and_return(token)
      end

      context 'when there is no lease' do
        before do
          allow_any_instance_of(described_class).to receive(:try_obtain_lease_for).and_return('randomuuid')
        end

        it 'calls the service' do
          expect(CheckGcpProjectBillingService).to receive_message_chain(:new, :execute).and_return([double])

          subject
        end

        it 'stores billing status in redis' do
          redis_double = double

          expect(CheckGcpProjectBillingService).to receive_message_chain(:new, :execute).and_return([double])
          expect(Gitlab::Redis::SharedState).to receive(:with).and_yield(redis_double)
          expect(redis_double).to receive(:set).with(described_class.redis_shared_state_key_for(token), anything, anything)

          subject
        end
      end

      context 'when there is a lease' do
        before do
          allow_any_instance_of(described_class).to receive(:try_obtain_lease_for).and_return(false)
        end

        it 'does not call the service' do
          expect(CheckGcpProjectBillingService).not_to receive(:new)

          subject
        end
      end
    end

    context 'when there is no token in redis' do
      before do
        allow_any_instance_of(described_class).to receive(:get_session_token).and_return(nil)
      end

      it 'does not call the service' do
        expect(CheckGcpProjectBillingService).not_to receive(:new)

        subject
      end
    end
  end

  describe 'billing change counter' do
    subject { described_class.new.perform('token_key') }

    before do
      allow(described_class).to receive(:get_session_token).and_return('bogustoken')
      allow_any_instance_of(described_class).to receive(:try_obtain_lease_for).and_return('randomuuid')

      Gitlab::Redis::SharedState.with do |redis|
        allow(redis).to receive(:set)
      end
    end

    context 'when previous state was false' do
      before do
        expect_any_instance_of(described_class).to receive(:check_previous_state).and_return('false')
      end

      context 'when the current state is false' do
        before do
          expect(CheckGcpProjectBillingService).to receive_message_chain(:new, :execute).and_return([])
        end

        it 'does not increment the billing change counter' do
          Gitlab::Redis::SharedState.with do |redis|
            expect(redis).not_to receive(:incr)
          end

          subject
        end
      end

      context 'when the current state is true' do
        before do
          expect(CheckGcpProjectBillingService).to receive_message_chain(:new, :execute).and_return([double])
        end

        it 'increments the billing change counter' do
          Gitlab::Redis::SharedState.with do |redis|
            expect(redis).to receive(:incr)
          end

          subject
        end
      end
    end

    context 'when previous state was true' do
      before do
        expect_any_instance_of(described_class).to receive(:check_previous_state).and_return('true')
        expect(CheckGcpProjectBillingService).to receive_message_chain(:new, :execute).and_return([double])
      end

      it 'does not increment the billing change counter' do
        Gitlab::Redis::SharedState.with do |redis|
          expect(redis).not_to receive(:incr)
        end

        subject
      end
    end
  end
end
