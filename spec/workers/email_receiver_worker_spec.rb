require "spec_helper"

describe EmailReceiverWorker do
  let(:raw_message) { fixture_file('emails/valid_reply.eml') }

  context "when reply by email is enabled" do
    before do
      allow(Gitlab::IncomingEmail).to receive(:enabled?).and_return(true)
    end

    it "calls the email receiver" do
      expect(Gitlab::Email::Receiver).to receive(:new).with(raw_message).and_call_original
      expect_any_instance_of(Gitlab::Email::Receiver).to receive(:execute)

      described_class.new.perform(raw_message)
    end

    context "when an error occurs" do
      before do
        allow_any_instance_of(Gitlab::Email::Receiver).to receive(:execute).and_raise(Gitlab::Email::Receiver::EmptyEmailError)
      end

      it "sends out a rejection email" do
        described_class.new.perform(raw_message)

        email = ActionMailer::Base.deliveries.last
        expect(email).not_to be_nil
        expect(email.to).to eq(["jake@adventuretime.ooo"])
        expect(email.subject).to include("Rejected")
      end
    end
  end

  context "when reply by email is disabled" do
    before do
      allow(Gitlab::IncomingEmail).to receive(:enabled?).and_return(false)
    end

    it "doesn't call the email receiver" do
      expect(Gitlab::Email::Receiver).not_to receive(:new)

      described_class.new.perform(raw_message)
    end
  end
end
