# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemCheck::IncomingEmailCheck do
  before do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))
  end

  describe '#multi_check' do
    context 'when incoming e-mail is disabled' do
      before do
        stub_incoming_email_setting(enabled: false)
      end

      it 'does not run any checks' do
        expect(SystemCheck).not_to receive(:run)

        subject.multi_check
      end
    end

    context 'when incoming e-mail is enabled for IMAP' do
      before do
        stub_incoming_email_setting(enabled: true)
      end

      it 'runs IMAP and mailroom checks' do
        expect(SystemCheck).to receive(:run).with('Reply by email',
          [
            SystemCheck::IncomingEmail::ImapAuthenticationCheck,
            SystemCheck::IncomingEmail::MailRoomEnabledCheck,
            SystemCheck::IncomingEmail::MailRoomRunningCheck
          ])

        subject.multi_check
      end
    end

    context 'when incoming e-mail is enabled for Microsoft Graph' do
      before do
        stub_incoming_email_setting(enabled: true, inbox_method: 'microsoft_graph')
      end

      it 'runs mailroom checks' do
        expect(SystemCheck).to receive(:run).with('Reply by email',
          [
            SystemCheck::IncomingEmail::MailRoomEnabledCheck,
            SystemCheck::IncomingEmail::MailRoomRunningCheck
          ])

        subject.multi_check
      end
    end
  end
end
