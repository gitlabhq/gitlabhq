require 'spec_helper'

describe DisableEmailInterceptor do
  before do
    Mail.register_interceptor(described_class)
  end

  it 'does not send emails' do
    allow(Gitlab.config.gitlab).to receive(:email_enabled).and_return(false)
    expect { deliver_mail }.not_to change(ActionMailer::Base.deliveries, :count)
  end

  after do
    # Removing interceptor from the list because unregister_interceptor is
    # implemented in later version of mail gem
    # See: https://github.com/mikel/mail/pull/705
    Mail.unregister_interceptor(described_class)
  end

  def deliver_mail
    key = create :personal_key
    Notify.new_ssh_key_email(key.id)
  end
end
