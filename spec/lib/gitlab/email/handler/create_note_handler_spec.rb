# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Handler::CreateNoteHandler do
  include_context :email_shared_context

  let_it_be(:user)      { create(:user) }
  let_it_be(:project)   { create(:project, :public, :repository) }

  let(:noteable)  { note.noteable }
  let(:note)      { create(:diff_note_on_merge_request, project: project) }
  let(:email_raw) { fixture_file('emails/valid_reply.eml') }
  let!(:sent_notification) do
    SentNotification.record_note(note, user.id, mail_key)
  end

  it_behaves_like :reply_processing_shared_examples

  it_behaves_like :note_handler_shared_examples do
    let(:recipient) { sent_notification.recipient }

    let(:update_commands_only) { fixture_file('emails/update_commands_only_reply.eml')}
    let(:no_content)           { fixture_file('emails/no_content_reply.eml') }
    let(:commands_in_reply)    { fixture_file('emails/commands_in_reply.eml') }
    let(:with_quick_actions)   { fixture_file('emails/valid_reply_with_quick_actions.eml') }
  end

  before do
    stub_incoming_email_setting(enabled: true, address: "reply+%{key}@appmail.adventuretime.ooo")
    stub_config_setting(host: 'localhost')
  end

  context 'when the recipient address does not include a mail key' do
    let(:email_raw) { fixture_file('emails/valid_reply.eml').gsub(mail_key, '') }

    it 'raises a UnknownIncomingEmail' do
      expect { receiver.execute }.to raise_error(Gitlab::Email::UnknownIncomingEmail)
    end
  end

  context 'when no sent notification for the mail key could be found' do
    let(:email_raw) { fixture_file('emails/wrong_mail_key.eml') }

    it 'raises a SentNotificationNotFoundError' do
      expect { receiver.execute }.to raise_error(Gitlab::Email::SentNotificationNotFoundError)
    end
  end

  context 'when issue is confidential' do
    let(:issue) { create(:issue, project: project) }
    let(:note) { create(:note, noteable: issue, project: project) }

    before do
      issue.update_attribute(:confidential, true)
    end

    it_behaves_like :checks_permissions_on_noteable_examples
  end

  shared_examples 'a reply to existing comment' do
    it 'creates a discussion' do
      expect { receiver.execute }.to change { noteable.notes.count }.by(1)
      new_note = noteable.notes.last

      expect(new_note.author).to eq(sent_notification.recipient)
      expect(new_note.position).to eq(note.position)
      expect(new_note.note).to include('I could not disagree more.')
      expect(new_note.in_reply_to?(note)).to be_truthy

      expect(new_note.discussion_id).to eq(note.discussion_id)
    end
  end

  # additional shared tests in :reply_processing_shared_examples
  context 'when everything is fine' do
    before do
      setup_attachment
    end

    it_behaves_like 'a reply to existing comment'

    context 'when sub-addressing is not supported' do
      before do
        stub_incoming_email_setting(enabled: true, address: nil)
      end

      shared_examples 'an email that contains a mail key' do |header|
        it "fetches the mail key from the #{header} header and creates a comment" do
          expect { receiver.execute }.to change { noteable.notes.count }.by(1)
          new_note = noteable.notes.last

          expect(new_note.author).to eq(sent_notification.recipient)
          expect(new_note.position).to eq(note.position)
          expect(new_note.note).to include('I could not disagree more.')
        end
      end

      context 'mail key is in the References header' do
        let(:email_raw) { fixture_file('emails/reply_without_subaddressing_and_key_inside_references.eml') }

        it_behaves_like 'an email that contains a mail key', 'References'
      end

      context 'mail key is in the References header with a comma' do
        let(:email_raw) { fixture_file('emails/reply_without_subaddressing_and_key_inside_references_with_a_comma.eml') }

        it_behaves_like 'an email that contains a mail key', 'References'
      end
    end
  end

  context 'when note is not a discussion' do
    let(:note) { create(:note_on_merge_request, project: project) }

    it_behaves_like 'a reply to existing comment'
  end
end
