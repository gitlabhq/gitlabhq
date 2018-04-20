require 'spec_helper'

describe ListGcpProjectsWorker do
  describe '.perform' do
    let(:token) { 'bogustoken' }

    subject { described_class.new.perform('token_key') }

    before do
      allow(described_class).to receive(:get_billing_state)
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
          expect(ListGcpProjectsService).to receive_message_chain(:new, :execute).and_return([double])

          subject
        end

        it 'stores billing status in redis' do
          expect(ListGcpProjectsService).to receive_message_chain(:new, :execute).and_return([double])
          expect(described_class).to receive(:set_billing_state).with(token, true)

          subject
        end
      end

      context 'when there is a lease' do
        before do
          allow_any_instance_of(described_class).to receive(:try_obtain_lease_for).and_return(false)
        end

        it 'does not call the service' do
          expect(ListGcpProjectsService).not_to receive(:new)

          subject
        end
      end
    end

    context 'when there is no token in redis' do
      before do
        allow(described_class).to receive(:get_session_token).and_return(nil)
      end

      it 'does not call the service' do
        expect(ListGcpProjectsService).not_to receive(:new)

        subject
      end
    end
  end

  describe 'billing change counter' do
    subject { described_class.new.perform('token_key') }

    before do
      allow(described_class).to receive(:get_session_token).and_return('bogustoken')
      allow_any_instance_of(described_class).to receive(:try_obtain_lease_for).and_return('randomuuid')
      allow(described_class).to receive(:set_billing_state)
    end

    context 'when previous state was false' do
      before do
        expect(described_class).to receive(:get_billing_state).and_return(false)
      end

      context 'when the current state is false' do
        before do
          expect(ListGcpProjectsService).to receive_message_chain(:new, :execute).and_return([])
        end

        it 'increments the billing change counter' do
          expect_any_instance_of(described_class).to receive_message_chain(:billing_changed_counter, :increment)

          subject
        end
      end

      context 'when the current state is true' do
        before do
          expect(ListGcpProjectsService).to receive_message_chain(:new, :execute).and_return([double])
        end

        it 'increments the billing change counter' do
          expect_any_instance_of(described_class).to receive_message_chain(:billing_changed_counter, :increment)

          subject
        end
      end
    end

    context 'when previous state was true' do
      before do
        expect(described_class).to receive(:get_billing_state).and_return(true)
        expect(ListGcpProjectsService).to receive_message_chain(:new, :execute).and_return([double])
      end

      it 'increment the billing change counter' do
        expect_any_instance_of(described_class).to receive_message_chain(:billing_changed_counter, :increment)

        subject
      end
    end
  end
end
