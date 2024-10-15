# frozen_string_literal: true

require "spec_helper"

RSpec.describe ServiceDeskEmailReceiverWorker, :mailer, feature_category: :service_desk do
  describe '#perform' do
    let(:worker) { described_class.new }
    let(:email) { fixture_file('emails/service_desk_custom_address.eml') }

    context 'when service_desk_email config is enabled' do
      before do
        stub_service_desk_email_setting(enabled: true, address: 'support+%{key}@example.com')
      end

      it 'does not ignore the email' do
        expect(Gitlab::Email::ServiceDeskReceiver).to receive(:new).and_call_original
        expect(Sidekiq.logger).to receive(:error).with(hash_including('exception.class' => Gitlab::Email::ProjectNotFound.to_s)).and_call_original

        worker.perform(email)
      end

      context 'when service desk receiver raises an exception' do
        before do
          allow_next_instance_of(Gitlab::Email::ServiceDeskReceiver) do |receiver|
            allow(receiver).to receive(:handler).and_return(nil)
          end
          expect(Sidekiq.logger).to receive(:error).with(hash_including('exception.class' => Gitlab::Email::UnknownIncomingEmail.to_s)).and_call_original
        end

        it 'sends a rejection email' do
          perform_enqueued_jobs do
            worker.perform(email)
          end

          reply = ActionMailer::Base.deliveries.last
          expect(reply).not_to be_nil
          expect(reply.to).to eq(['jake@adventuretime.ooo'])
          expect(reply.subject).to include('Rejected')
        end
      end
    end

    context 'when service_desk_email config is disabled' do
      before do
        stub_service_desk_email_setting(enabled: false, address: 'foo')
      end

      it 'ignores the email' do
        expect(Gitlab::Email::ServiceDeskReceiver).not_to receive(:new)

        worker.perform(email)
      end
    end
  end
end
