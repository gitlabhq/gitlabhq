# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Hook::SilentModeInterceptor, :mailer, feature_category: :geo_replication do
  let_it_be(:user) { create(:user) }

  before do
    Mail.register_interceptor(described_class)
  end

  after do
    Mail.unregister_interceptor(described_class)
  end

  context 'when silent mode is enabled' do
    it 'prevents mail delivery' do
      stub_application_setting(silent_mode_enabled: true)

      deliver_mails(user)

      should_not_email_anyone
    end

    it 'logs the suppression' do
      stub_application_setting(silent_mode_enabled: true)

      expect(Gitlab::AppJsonLogger).to receive(:info).with(
        message: 'SilentModeInterceptor prevented sending mail',
        mail_subject: 'Two-factor authentication disabled',
        silent_mode_enabled: true
      )
      expect(Gitlab::AppJsonLogger).to receive(:info).with(
        message: 'SilentModeInterceptor prevented sending mail',
        mail_subject: 'Welcome to GitLab!',
        silent_mode_enabled: true
      )

      deliver_mails(user)
    end
  end

  context 'when silent mode is disabled' do
    it 'does not prevent mail delivery' do
      stub_application_setting(silent_mode_enabled: false)

      deliver_mails(user)

      should_email(user, times: 2)
    end

    it 'debug logs the no-op' do
      stub_application_setting(silent_mode_enabled: false)

      expect(Gitlab::AppJsonLogger).to receive(:debug).with(
        message: 'SilentModeInterceptor did nothing',
        mail_subject: 'Two-factor authentication disabled',
        silent_mode_enabled: false
      )
      expect(Gitlab::AppJsonLogger).to receive(:debug).with(
        message: 'SilentModeInterceptor did nothing',
        mail_subject: 'Welcome to GitLab!',
        silent_mode_enabled: false
      )

      deliver_mails(user)
    end
  end

  def deliver_mails(user)
    Notify.disabled_two_factor_email(user).deliver_now
    DeviseMailer.user_admin_approval(user).deliver_now
  end
end
