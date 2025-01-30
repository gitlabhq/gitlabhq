# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Handler::CreateNoteHandler, feature_category: :shared do
  include_context 'email shared context'

  let_it_be_with_reload(:user) { create(:user, email: 'jake@adventuretime.ooo') }
  let_it_be(:project) { create(:project, :public, :repository) }

  let(:noteable)  { note.noteable }
  let(:note)      { create(:diff_note_on_merge_request, project: project) }
  let(:email_raw) { fixture_file('emails/valid_reply.eml') }
  let!(:sent_notification) do
    SentNotification.record_note(note, user.id, mail_key)
  end

  before do
    stub_incoming_email_setting(enabled: true, address: "reply+%{key}@appmail.adventuretime.ooo")
    stub_config_setting(host: 'localhost')
  end

  it_behaves_like 'reply processing shared examples'

  it_behaves_like 'note handler shared examples' do
    let(:recipient) { sent_notification.recipient }

    let(:update_commands_only) { fixture_file('emails/update_commands_only_reply.eml') }
    let(:no_content)           { fixture_file('emails/no_content_reply.eml') }
    let(:commands_in_reply)    { fixture_file('emails/commands_in_reply.eml') }
    let(:with_quick_actions)   { fixture_file('emails/valid_reply_with_quick_actions.eml') }
  end

  context 'when the recipient address does not include a mail key' do
    let(:email_raw) { fixture_file('emails/valid_reply.eml').gsub(mail_key, '') }

    it 'raises a UnknownIncomingEmail' do
      expect { receiver.execute }.to raise_error(Gitlab::Email::UnknownIncomingEmail)
    end
  end

  context 'when the incoming email is from a different email address' do
    before do
      SentNotification.find_by(reply_key: mail_key).update!(recipient: original_recipient)
    end

    context 'when the issue is not a Service Desk issue' do
      let(:original_recipient) { create(:user, email: 'john@somethingelse.com') }

      context 'with only one email address' do
        it 'raises a UserNotFoundError' do
          expect { receiver.execute }.to raise_error(Gitlab::Email::UserNotFoundError)
        end
      end

      context 'with a secondary verified email address' do
        let(:verified_email) { 'alan@adventuretime.ooo' }
        let(:email_raw) { fixture_file('emails/valid_reply.eml').gsub('jake@adventuretime.ooo', verified_email) }

        before do
          create(:email, :confirmed, user: original_recipient, email: verified_email)
        end

        it 'does not raise a UserNotFoundError' do
          expect { receiver.execute }.not_to raise_error
        end
      end
    end

    context 'when the issue is a Service Desk issue' do
      let(:original_recipient) { Users::Internal.support_bot }

      it 'does not raise a UserNotFoundError' do
        expect { receiver.execute }.not_to raise_error
      end
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

    it_behaves_like 'checks permissions on noteable examples'
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

      context 'when mail key is in the References header' do
        let(:email_raw) { fixture_file('emails/reply_without_subaddressing_and_key_inside_references.eml') }

        it_behaves_like 'an email that contains a mail key', 'References'
      end

      context 'when mail key is in the References header with a comma' do
        let(:email_raw) do
          fixture_file('emails/reply_without_subaddressing_and_key_inside_references_with_a_comma.eml')
        end

        it_behaves_like 'an email that contains a mail key', 'References'
      end
    end
  end

  context 'when email contains reply' do
    shared_examples 'no content message' do
      context 'when email contains quoted text only' do
        let(:email_raw) { fixture_file('emails/no_content_with_quote.eml') }

        it 'raises an EmptyEmailError' do
          expect { receiver.execute }.to raise_error(Gitlab::Email::EmptyEmailError)
        end
      end

      context 'when email contains quoted text and quick commands only' do
        let(:email_raw) { fixture_file('emails/commands_only_reply.eml') }

        it 'does not create a discussion' do
          expect { receiver.execute }.not_to change { noteable.notes.count }
        end
      end
    end

    context 'when noteable is not an issue' do
      let_it_be(:note) { create(:note_on_merge_request, project: project) }

      it_behaves_like 'no content message'

      context 'when email contains text, quoted text and quick commands' do
        let(:email_raw) { fixture_file('emails/commands_in_reply.eml') }

        it 'creates a discussion without appended reply' do
          expect { receiver.execute }.to change { noteable.notes.count }.by(1)
          new_note = noteable.notes.last

          expect(new_note.note).not_to include('<details><summary>...</summary>')
        end
      end
    end

    context 'when noteable is an issue' do
      let_it_be(:note) { create(:note_on_issue, project: project) }

      it_behaves_like 'no content message'

      context 'when email contains text, quoted text and quick commands' do
        let(:email_raw) { fixture_file('emails/commands_in_reply.eml') }

        it 'creates a discussion with appended reply' do
          expect { receiver.execute }.to change { noteable.notes.count }.by(1)
          new_note = noteable.notes.last

          expect(new_note.note).to include('<details><summary>...</summary>')
        end
      end
    end
  end

  context 'when note is not a discussion' do
    let(:note) { create(:note_on_merge_request, project: project) }

    it_behaves_like 'a reply to existing comment'
  end

  context 'when note is authored from external author for service desk' do
    before do
      SentNotification.find_by(reply_key: mail_key).update!(recipient: Users::Internal.support_bot)
    end

    context 'when email contains text, quoted text and quick commands' do
      let(:email_raw) { fixture_file('emails/commands_in_reply.eml') }

      it 'creates a discussion' do
        expect { receiver.execute }.to change { noteable.notes.count }.by(1)
      end

      it 'links external participant' do
        receiver.execute

        new_note = noteable.notes.last

        expect(new_note.note_metadata.external_author).to eq('jake@adventuretime.ooo')
      end
    end
  end

  context 'when issue is closed' do
    let_it_be(:noteable) { create(:issue, :closed, :confidential, project: project) }
    let_it_be(:note) { create(:note, noteable: noteable, project: project) }

    let!(:sent_notification) do
      allow(::ServiceDesk).to receive(:enabled?).with(project).and_return(true)
      SentNotification.record_note(note, Users::Internal.support_bot.id)
    end

    let(:reply_address) { "support+#{sent_notification.reply_key}@example.com" }
    let(:reopen_note) { noteable.notes.last }
    let(:email_raw) do
      <<~EMAIL
      From: from@example.com
      To: #{reply_address}
      Subject: Issue title

      Issue description
      EMAIL
    end

    before do
      stub_incoming_email_setting(enabled: true, address: 'support+%{key}@example.com')
    end

    it 'does not reopen issue but adds external participants comment' do
      # Only 1 from received email
      expect { receiver.execute }.to change { noteable.notes.count }.by(1)
      expect(noteable).to be_closed
    end

    context 'when noteable is a commit' do
      let!(:note) { create(:note_on_commit, project: project) }
      let!(:noteable) { note.noteable }

      let!(:sent_notification) do
        allow(::ServiceDesk).to receive(:enabled?).with(project).and_return(true)
        SentNotification.record_note(note, Users::Internal.support_bot.id)
      end

      it 'does not reopen issue but adds external participants comment' do
        expect { receiver.execute }.to change { noteable.notes.count }.by(1)
      end
    end

    context 'when reopen_issue_on_external_participant_note is true' do
      shared_examples 'an automatically reopened issue' do
        it 'reopens issue, adds external participants comment and reopen comment' do
          # 1 from received email and 1 reopen comment
          expect { receiver.execute }.to change { noteable.notes.count }.by(2)
          expect(noteable.reset).to be_open

          expect(reopen_note).to be_confidential
          expect(reopen_note.author).to eq(Users::Internal.support_bot)
          expect(reopen_note.note).to include(reopen_comment_body)
        end
      end

      let!(:settings) do
        create(:service_desk_setting, project: project, reopen_issue_on_external_participant_note: true)
      end

      let(:reopen_comment_body) do
        s_(
          "ServiceDesk|This issue has been reopened because it received a new comment from an external participant."
        )
      end

      it_behaves_like 'an automatically reopened issue'

      it 'does not contain an assignee mention' do
        receiver.execute
        expect(reopen_note.note).not_to include("@")
      end

      context 'when issue is assigned to a user' do
        before do
          noteable.update!(assignees: [user])
        end

        it_behaves_like 'an automatically reopened issue'

        it 'contains an assignee mention' do
          receiver.execute
          expect(reopen_note.note).to include(user.to_reference)
        end
      end

      context 'when issue is assigned to multiple users' do
        let_it_be(:another_user) { create(:user) }

        before do
          noteable.update!(assignees: [user, another_user])
        end

        it_behaves_like 'an automatically reopened issue'

        it 'contains two assignee mentions' do
          receiver.execute
          expect(reopen_note.note).to include(user.to_reference)
          expect(reopen_note.note).to include(another_user.to_reference)
        end
      end
    end
  end
end
