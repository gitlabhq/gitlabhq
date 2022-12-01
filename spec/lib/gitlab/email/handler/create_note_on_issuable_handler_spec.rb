# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Handler::CreateNoteOnIssuableHandler do
  include_context 'email shared context'

  let_it_be(:user)      { create(:user, email: 'jake@adventuretime.ooo', incoming_email_token: 'auth_token') }
  let_it_be(:namespace) { create(:namespace, path: 'gitlabhq') }
  let_it_be(:project)   { create(:project, :public, namespace: namespace, path: 'gitlabhq') }

  let!(:noteable) { create(:issue, project: project) }
  let(:email_raw) { email_fixture('emails/valid_note_on_issuable.eml') }

  before do
    stub_incoming_email_setting(enabled: true, address: "incoming+%{key}@appmail.adventuretime.ooo")
    stub_config_setting(host: 'localhost')
  end

  it_behaves_like 'reply processing shared examples'

  it_behaves_like 'note handler shared examples', true do
    let_it_be(:recipient) { user }

    let(:update_commands_only) { email_reply_fixture('emails/update_commands_only.eml') }
    let(:no_content)           { email_reply_fixture('emails/no_content_reply.eml') }
    let(:commands_in_reply)    { email_reply_fixture('emails/commands_in_reply.eml') }
    let(:with_quick_actions)   { email_reply_fixture('emails/valid_reply_with_quick_actions.eml') }
  end

  context 'when the recipient address does not include a mail key' do
    let(:mail_key)  { 'gitlabhq-gitlabhq-project_id-auth_token-issue-issue_iid' }
    let(:email_raw) { fixture_file('emails/valid_note_on_issuable.eml').gsub(mail_key, '') }

    it 'raises an UnknownIncomingEmail' do
      expect { receiver.execute }.to raise_error(Gitlab::Email::UnknownIncomingEmail)
    end
  end

  context 'when issue is confidential' do
    before do
      noteable.update_attribute(:confidential, true)
    end

    it_behaves_like 'checks permissions on noteable examples'
  end

  def email_fixture(path)
    fixture_file(path)
      .gsub('project_id', project.project_id.to_s)
      .gsub('issue_iid', noteable.iid.to_s)
  end

  def email_reply_fixture(path)
    reply_address = 'reply+59d8df8370b7e95c5a49fbf86aeb2c93'
    note_address  = "incoming+#{project.full_path_slug}-#{project.project_id}-#{user.incoming_email_token}-issue-#{noteable.iid}"

    fixture_file(path)
      .gsub(reply_address, note_address)
  end
end
