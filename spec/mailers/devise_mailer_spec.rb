# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe DeviseMailer do
  describe "#confirmation_instructions" do
    subject { described_class.confirmation_instructions(user, 'faketoken', {}) }

    context "when confirming a new account" do
      let(:user) { build(:user, created_at: 1.minute.ago, unconfirmed_email: nil) }

      it "shows the expected text" do
        expect(subject.body.encoded).to have_text "Welcome"
        expect(subject.body.encoded).not_to have_text user.email
      end
    end

    context "when confirming the unconfirmed_email" do
      let(:user) { build(:user, unconfirmed_email: 'jdoe@example.com') }

      it "shows the expected text" do
        expect(subject.body.encoded).not_to have_text "Welcome"
        expect(subject.body.encoded).to have_text user.unconfirmed_email
        expect(subject.body.encoded).not_to have_text user.email
      end
    end

    context "when re-confirming the primary email after a security issue" do
      let(:user) { build(:user, created_at: 10.days.ago, unconfirmed_email: nil) }

      it "shows the expected text" do
        expect(subject.body.encoded).not_to have_text "Welcome"
        expect(subject.body.encoded).to have_text user.email
      end
    end
  end
end
