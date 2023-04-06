# frozen_string_literal: true

require "spec_helper"

RSpec.describe EmailReceiverWorker, :mailer, feature_category: :team_planning do
  let(:raw_message) { fixture_file('emails/valid_reply.eml') }

  context "when reply by email is enabled" do
    before do
      allow(Gitlab::Email::IncomingEmail).to receive(:enabled?).and_return(true)
    end

    it "calls the email receiver" do
      expect(Gitlab::Email::Receiver).to receive(:new).with(raw_message).and_call_original
      expect_any_instance_of(Gitlab::Email::Receiver).to receive(:execute)
      expect(Sidekiq.logger).to receive(:info).with(hash_including(message: "Successfully processed message")).and_call_original

      described_class.new.perform(raw_message)
    end

    context "when an error occurs" do
      before do
        allow_any_instance_of(Gitlab::Email::Receiver).to receive(:execute).and_raise(error)
      end

      context 'when error is a processing error' do
        let(:error) { Gitlab::Email::EmptyEmailError.new }

        it 'triggers email failure handler' do
          expect(Gitlab::Email::FailureHandler).to receive(:handle) do |receiver, received_error|
            expect(receiver).to be_a(Gitlab::Email::Receiver)
            expect(receiver.mail.encoded).to eql(Mail::Message.new(raw_message).encoded)
            expect(received_error).to be(error)
          end

          described_class.new.perform(raw_message)
        end

        it 'logs the error' do
          expect(Sidekiq.logger).to receive(:error).with(hash_including('exception.class' => error.class.name)).and_call_original

          described_class.new.perform(raw_message)
        end
      end

      context 'when error is not a processing error' do
        let(:error) { ActiveRecord::StatementTimeout.new("Statement timeout") }

        it 'triggers email failure handler' do
          expect(Gitlab::Email::FailureHandler).to receive(:handle) do |receiver, received_error|
            expect(receiver).to be_a(Gitlab::Email::Receiver)
            expect(receiver.mail.encoded).to eql(Mail::Message.new(raw_message).encoded)
            expect(received_error).to be(error)
          end

          described_class.new.perform(raw_message)
        end

        it 'reports the error' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(error).and_call_original

          described_class.new.perform(raw_message)
        end
      end
    end
  end

  context "when reply by email is disabled" do
    before do
      allow(Gitlab::Email::IncomingEmail).to receive(:enabled?).and_return(false)
    end

    it "doesn't call the email receiver" do
      expect(Gitlab::Email::Receiver).not_to receive(:new)

      described_class.new.perform(raw_message)
    end
  end
end
