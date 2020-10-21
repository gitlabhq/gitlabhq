# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Handler::CreateNoteHandler do
  include_context :email_shared_context
  let!(:sent_notification) do
    SentNotification.record_note(note, user.id, mail_key)
  end

  let(:noteable)  { note.noteable }
  let(:note)      { create(:diff_note_on_merge_request, project: project) }
  let(:user)      { create(:user) }
  let(:project)   { create(:project, :public, :repository) }
  let(:email_raw) { fixture_file('emails/valid_reply.eml') }

  it_behaves_like :reply_processing_shared_examples

  before do
    stub_incoming_email_setting(enabled: true, address: "reply+%{key}@appmail.adventuretime.ooo")
    stub_config_setting(host: 'localhost')
  end

  context "when the recipient address doesn't include a mail key" do
    let(:email_raw) { fixture_file('emails/valid_reply.eml').gsub(mail_key, "") }

    it "raises a UnknownIncomingEmail" do
      expect { receiver.execute }.to raise_error(Gitlab::Email::UnknownIncomingEmail)
    end
  end

  context "when no sent notification for the mail key could be found" do
    let(:email_raw) { fixture_file('emails/wrong_mail_key.eml') }

    it "raises a SentNotificationNotFoundError" do
      expect { receiver.execute }.to raise_error(Gitlab::Email::SentNotificationNotFoundError)
    end
  end

  context "when the noteable could not be found" do
    before do
      noteable.destroy
    end

    it "raises a NoteableNotFoundError" do
      expect { receiver.execute }.to raise_error(Gitlab::Email::NoteableNotFoundError)
    end
  end

  context "when the note could not be saved" do
    before do
      allow_any_instance_of(Note).to receive(:persisted?).and_return(false)
    end

    it "raises an InvalidNoteError" do
      expect { receiver.execute }.to raise_error(Gitlab::Email::InvalidNoteError)
    end

    context 'because the note was update commands only' do
      let!(:email_raw) { fixture_file("emails/update_commands_only_reply.eml") }

      context 'and current user cannot update noteable' do
        it 'raises a CommandsOnlyNoteError' do
          expect { receiver.execute }.to raise_error(Gitlab::Email::InvalidNoteError)
        end
      end

      context "and current user can update noteable" do
        before do
          project.add_developer(user)
        end

        it 'does not raise an error' do
          expect { receiver.execute }.to change { noteable.resource_state_events.count }.by(1)

          expect(noteable.reload).to be_closed
        end
      end
    end
  end

  context 'when the note contains quick actions' do
    let!(:email_raw) { fixture_file("emails/commands_in_reply.eml") }

    context 'and current user cannot update the noteable' do
      it 'only executes the commands that the user can perform' do
        expect { receiver.execute }
          .to change { noteable.notes.user.count }.by(1)
          .and change { user.todos_pending_count }.from(0).to(1)

        expect(noteable.reload).to be_open
      end
    end

    context 'and current user can update noteable' do
      before do
        project.add_developer(user)
      end

      it 'posts a note and updates the noteable' do
        expect(TodoService.new.todo_exist?(noteable, user)).to be_falsy

        expect { receiver.execute }
          .to change { noteable.notes.user.count }.by(1)
          .and change { user.todos_pending_count }.from(0).to(1)

        expect(noteable.reload).to be_closed
      end
    end
  end

  context "when the reply is blank" do
    let!(:email_raw) { fixture_file("emails/no_content_reply.eml") }

    it "raises an EmptyEmailError" do
      expect { receiver.execute }.to raise_error(Gitlab::Email::EmptyEmailError)
    end
  end

  shared_examples "checks permissions on noteable" do
    context "when user has access" do
      before do
        project.add_reporter(user)
      end

      it "creates a comment" do
        expect { receiver.execute }.to change { noteable.notes.count }.by(1)
      end
    end

    context "when user does not have access" do
      it "raises UserNotAuthorizedError" do
        expect { receiver.execute }.to raise_error(Gitlab::Email::UserNotAuthorizedError)
      end
    end
  end

  context "when discussion is locked" do
    before do
      noteable.update_attribute(:discussion_locked, true)
    end

    it_behaves_like "checks permissions on noteable"
  end

  context "when issue is confidential" do
    let(:issue) { create(:issue, project: project) }
    let(:note) { create(:note, noteable: issue, project: project) }

    before do
      issue.update_attribute(:confidential, true)
    end

    it_behaves_like "checks permissions on noteable"
  end

  shared_examples 'a reply to existing comment' do
    it "creates a comment" do
      expect { receiver.execute }.to change { noteable.notes.count }.by(1)
      new_note = noteable.notes.last

      expect(new_note.author).to eq(sent_notification.recipient)
      expect(new_note.position).to eq(note.position)
      expect(new_note.note).to include("I could not disagree more.")
      expect(new_note.in_reply_to?(note)).to be_truthy

      if note.part_of_discussion?
        expect(new_note.discussion_id).to eq(note.discussion_id)
      else
        expect(new_note.discussion_id).not_to eq(note.discussion_id)
      end
    end
  end

  context "when everything is fine" do
    before do
      setup_attachment
    end

    it_behaves_like 'a reply to existing comment'

    it "adds all attachments" do
      expect_next_instance_of(Gitlab::Email::AttachmentUploader) do |uploader|
        expect(uploader).to receive(:execute).with(upload_parent: project, uploader_class: FileUploader).and_return(
          [
            {
              url: "uploads/image.png",
              alt: "image",
              markdown: markdown
            }
          ]
        )
      end

      receiver.execute

      note = noteable.notes.last
      expect(note.note).to include(markdown)
    end

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

  context "when note is not a discussion" do
    let(:note) { create(:note_on_merge_request, project: project) }

    it_behaves_like 'a reply to existing comment'
  end

  context 'when the service desk' do
    let(:project) { create(:project, :public, service_desk_enabled: true) }
    let(:support_bot) { User.support_bot }
    let(:noteable) { create(:issue, project: project, author: support_bot, title: 'service desk issue') }
    let(:note) { create(:note, project: project, noteable: noteable) }
    let(:email_raw) { fixture_file('emails/valid_reply_with_quick_actions.eml') }

    let!(:sent_notification) do
      SentNotification.record_note(note, support_bot.id, mail_key)
    end

    context 'is enabled' do
      before do
        allow(Gitlab::ServiceDesk).to receive(:enabled?).with(project: project).and_return(true)
        project.project_feature.update!(issues_access_level: issues_access_level)
      end

      context 'when issues are enabled for everyone' do
        let(:issues_access_level) { ProjectFeature::ENABLED }

        it 'creates a comment' do
          expect { receiver.execute }.to change { noteable.notes.count }.by(1)
        end

        context 'when quick actions are present' do
          it 'encloses quick actions with code span markdown' do
            receiver.execute
            noteable.reload

            note = Note.last
            expect(note.note).to include("Jake out\n\n`/close`\n`/title test`")
            expect(noteable.title).to eq('service desk issue')
            expect(noteable).to be_opened
          end
        end
      end

      context 'when issues are protected members only' do
        let(:issues_access_level) { ProjectFeature::PRIVATE }

        it 'creates a comment' do
          expect { receiver.execute }.to change { noteable.notes.count }.by(1)
        end
      end

      context 'when issues are disabled' do
        let(:issues_access_level) { ProjectFeature::DISABLED }

        it 'does not create a comment' do
          expect { receiver.execute }.to raise_error(Gitlab::Email::UserNotAuthorizedError)
        end
      end
    end

    context 'is disabled' do
      before do
        allow(Gitlab::ServiceDesk).to receive(:enabled?).and_return(false)
        allow(Gitlab::ServiceDesk).to receive(:enabled?).with(project: project).and_return(false)
      end

      it 'does not create a comment' do
        expect { receiver.execute }.to raise_error(Gitlab::Email::ProjectNotFound)
      end
    end
  end
end
