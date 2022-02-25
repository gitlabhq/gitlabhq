# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Hook::ValidateAddressesInterceptor do
  describe 'UNSAFE_CHARACTERS' do
    subject { described_class::UNSAFE_CHARACTERS }

    it { is_expected.to match('\\') }
    it { is_expected.to match("\x00") }
    it { is_expected.to match("\x01") }
    it { is_expected.not_to match('') }
    it { is_expected.not_to match('user@example.com') }
    it { is_expected.not_to match('foo-123+bar_456@example.com') }
  end

  describe '.delivering_email' do
    let(:mail) do
      ActionMailer::Base.mail(to: 'test@mail.com', from: 'info@mail.com', subject: 'title', body: 'hello')
    end

    let(:unsafe_email) { "evil+\x01$HOME@example.com" }

    it 'sends emails to normal addresses' do
      expect(Gitlab::AuthLogger).not_to receive(:info)
      expect { mail.deliver_now }.to change(ActionMailer::Base.deliveries, :count)
    end

    [:from, :to, :cc, :bcc].each do |header|
      it "does not send emails if the #{header.inspect} header contains unsafe characters" do
        mail[header] = unsafe_email

        expect(Gitlab::AuthLogger).to receive(:info).with(
          message: 'Skipping email with unsafe characters in address',
          address: unsafe_email,
          subject: mail.subject
        )

        expect { mail.deliver_now }.not_to change(ActionMailer::Base.deliveries, :count)
      end
    end

    [:reply_to].each do |header|
      it "sends emails if the #{header.inspect} header contains unsafe characters" do
        mail[header] = unsafe_email

        expect(Gitlab::AuthLogger).not_to receive(:info)
        expect { mail.deliver_now }.to change(ActionMailer::Base.deliveries, :count)
      end
    end
  end
end
