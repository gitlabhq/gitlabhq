require 'spec_helper'
require_relative 'email_shared_blocks'

describe Gitlab::Email::Receiver, lib: true do
  include_context :email_shared_context

  context "when we cannot find a capable handler" do
    let(:email_raw) { fixture_file('emails/valid_reply.eml').gsub(mail_key, "!!!") }

    it "raises a UnknownIncomingEmail" do
      expect { receiver.execute }.to raise_error(Gitlab::Email::UnknownIncomingEmail)
    end
  end

  context "when the email is blank" do
    let(:email_raw) { "" }

    it "raises an EmptyEmailError" do
      expect { receiver.execute }.to raise_error(Gitlab::Email::EmptyEmailError)
    end
  end
end
