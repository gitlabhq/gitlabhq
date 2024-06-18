# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Hook::DeliveryMetricsObserver do
  let(:email) do
    ActionMailer::Base.mail(to: 'test@example.com',
      from: 'info@example.com',
      body: 'hello')
  end

  context 'when email has been delivered' do
    it 'increments both email delivery metrics' do
      expect(described_class.delivery_attempts_counter).to receive(:increment)
      expect(described_class.delivered_emails_counter).to receive(:increment)

      email.deliver_now
    end
  end

  context 'when email has not been delivered due to an error' do
    before do
      allow(email.delivery_method).to receive(:deliver!)
        .and_raise(StandardError, 'Some SMTP error')
    end

    it 'increments only delivery attempt metric' do
      expect(described_class.delivery_attempts_counter)
        .to receive(:increment)
      expect(described_class.delivered_emails_counter)
        .not_to receive(:increment)

      expect { email.deliver_now }
        .to raise_error(StandardError, 'Some SMTP error')
    end
  end
end
