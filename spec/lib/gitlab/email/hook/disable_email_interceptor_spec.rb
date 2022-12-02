# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Hook::DisableEmailInterceptor do
  before do
    Mail.register_interceptor(described_class)
  end

  after do
    Mail.unregister_interceptor(described_class)
  end

  it 'does not send emails' do
    allow(Gitlab.config.gitlab).to receive(:email_enabled).and_return(false)
    expect { deliver_mail }.not_to change(ActionMailer::Base.deliveries, :count)
  end

  def deliver_mail
    key = create :personal_key
    Notify.new_ssh_key_email(key.id)
  end
end
