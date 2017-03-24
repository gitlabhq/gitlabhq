require 'spec_helper'
require_relative '../email_shared_blocks'

describe Gitlab::Email::Handler::EE::ServiceDeskHandler do
  include_context :email_shared_context
  before do
    stub_incoming_email_setting(enabled: true, address: "incoming+%{key}@appmail.adventuretime.ooo")
    stub_config_setting(host: 'localhost')
  end

  let(:email_raw) { fixture_file('emails/service_desk.eml') }
  let(:project) { create(:project, :public) }

  context 'when service desk is enabled' do
    before do
      project.update_attributes(
        service_desk_enabled: true,
        service_desk_mail_key: 'somemailkey',
      )
    end

    it 'receives the email', jneen: true do
      setup_attachment

      expect(Notify).to receive(:thank_you_email).with(instance_of(Fixnum))

      expect { receiver.execute }.to change { Issue.count }.by(1)

      new_issue = Issue.last

      expect(new_issue.author).to eql(User.support_bot)
      expect(new_issue.confidential?).to be true
      expect(new_issue.all_references.all).to be_empty
    end
  end
end
