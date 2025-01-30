# frozen_string_literal: true

RSpec.shared_context 'email shared context' do
  let(:mail_key) { '59d8df8370b7e95c5a49fbf86aeb2c93' }
  let(:receiver) { Gitlab::Email::Receiver.new(email_raw) }
  let(:markdown) { '![image](uploads/image.png)' }

  def setup_attachment
    allow_any_instance_of(Gitlab::Email::AttachmentUploader).to receive(:execute).and_return(
      [
        {
          url: 'uploads/image.png',
          alt: 'image',
          markdown: markdown
        }
      ]
    )
  end
end

def email_fixture(path)
  fixture_file(path).gsub('project_id', project.project_id.to_s)
end

def service_desk_fixture(path, slug: nil, key: 'mykey')
  slug ||= project.full_path_slug.to_s
  fixture_file(path)
    .gsub('project_slug', slug)
    .gsub('project_key', key)
    .gsub('project_id', project.project_id.to_s)
end

RSpec.shared_examples 'reply processing shared examples' do
  context 'when the user could not be found' do
    before do
      user.destroy!
    end

    it 'raises a UserNotFoundError' do
      expect { receiver.execute }.to raise_error(Gitlab::Email::UserNotFoundError)
    end
  end

  context 'when the user is not authorized to the project' do
    before do
      project.update_attribute(:visibility_level, Project::PRIVATE)
    end

    it 'raises a ProjectNotFound' do
      expect { receiver.execute }.to raise_error(Gitlab::Email::ProjectNotFound)
    end
  end
end

RSpec.shared_examples 'checks permissions on noteable examples' do
  context 'when user has access' do
    before do
      project.add_reporter(user)
    end

    it 'creates a comment' do
      expect { receiver.execute }.to change { noteable.notes.count }.by(1)
    end
  end

  context 'when user does not have access' do
    it 'raises UserNotAuthorizedError' do
      expect { receiver.execute }.to raise_error(Gitlab::Email::UserNotAuthorizedError)
    end
  end
end

RSpec.shared_examples 'note handler shared examples' do |forwardable|
  context 'when the noteable could not be found' do
    before do
      noteable.destroy!
    end

    it 'raises a NoteableNotFoundError' do
      expect { receiver.execute }.to raise_error(Gitlab::Email::NoteableNotFoundError)
    end
  end

  context 'when the note could not be saved' do
    before do
      allow_any_instance_of(Note).to receive(:persisted?).and_return(false)
    end

    it 'raises an InvalidNoteError' do
      expect { receiver.execute }.to raise_error(Gitlab::Email::InvalidNoteError)
    end

    context 'because the note was update commands only' do
      let!(:email_raw) { update_commands_only }

      context 'and current user cannot update noteable' do
        it 'does not raise an error' do
          expect { receiver.execute }.not_to raise_error
        end
      end

      context 'and current user can update noteable' do
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
    let!(:email_raw) { commands_in_reply }

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

  context 'when the reply is blank' do
    let!(:email_raw) { no_content }

    it 'raises an EmptyEmailError', unless: forwardable do
      expect { receiver.execute }.to raise_error(Gitlab::Email::EmptyEmailError)
    end

    it 'allows email to only have quoted text', if: forwardable do
      expect { receiver.execute }.not_to raise_error
    end
  end

  context 'when discussion is locked' do
    before do
      noteable.update_attribute(:discussion_locked, true)
    end

    it_behaves_like 'checks permissions on noteable examples'
  end

  context 'when everything is fine' do
    before do
      setup_attachment
    end

    it 'adds all attachments' do
      expect_next_instance_of(Gitlab::Email::AttachmentUploader) do |uploader|
        expect(uploader).to receive(:execute)
                            .with(
                              upload_parent: project,
                              uploader_class: FileUploader,
                              author: user
                            )
                            .and_return(
                              [
                                {
                                  url: 'uploads/image.png',
                                  alt: 'image',
                                  markdown: markdown
                                }
                              ]
                            )
      end

      receiver.execute

      note = noteable.notes.last
      expect(note.note).to include(markdown)
      expect(note.note).to include('Jake out')
    end
  end

  context 'when the service desk' do
    let(:project) { create(:project, :public, service_desk_enabled: true) }
    let(:support_bot) { Users::Internal.support_bot }
    let(:noteable) { create(:issue, project: project, author: support_bot, title: 'service desk issue') }
    let!(:note) { create(:note, project: project, noteable: noteable) }
    let(:email_raw) { with_quick_actions }

    let!(:sent_notification) do
      allow(::ServiceDesk).to receive(:enabled?).with(project).and_return(true)
      SentNotification.record_note(note, support_bot.id, mail_key)
    end

    context 'is enabled' do
      before do
        allow(::ServiceDesk).to receive(:enabled?).with(project).and_return(true)
        project.project_feature.update!(issues_access_level: issues_access_level)
      end

      context 'when issues are enabled for everyone' do
        let(:issues_access_level) { ProjectFeature::ENABLED }

        it 'creates a comment' do
          expect { receiver.execute }.to change { noteable.notes.count }.by(1)
        end

        context 'when quick actions are present' do
          before do
            receiver.execute
            noteable.reload
          end

          context 'when author is a support_bot', unless: forwardable do
            it 'encloses quick actions with code span markdown' do
              note = Note.last
              expect(note.note).to include("Jake out\n\n`/close`\n`/title test`")
              expect(noteable.title).to eq('service desk issue')
              expect(noteable).to be_opened
            end
          end

          context 'when author is a normal user', if: forwardable do
            it 'extracted the quick actions' do
              note = Note.last
              expect(note.note).to include('Jake out')
              expect(note.note).not_to include("`/close`\n`/title test`")
            end
          end
        end
      end

      context 'when issues are protected members only' do
        let(:issues_access_level) { ProjectFeature::PRIVATE }

        before do
          if recipient.support_bot?
            @changed_by = 1
          else
            @changed_by = 2
            project.add_developer(recipient)
          end
        end

        it 'creates a comment' do
          expect { receiver.execute }.to change { noteable.notes.count }.by(@changed_by)
        end
      end

      context 'when issues are disabled' do
        let(:issues_access_level) { ProjectFeature::DISABLED }

        it 'does not create a comment' do
          expect { receiver.execute }.to raise_error(Gitlab::Email::UserNotAuthorizedError)
        end
      end
    end

    context 'is disabled', unless: forwardable do
      before do
        allow(::ServiceDesk).to receive(:enabled?).and_return(false)
        allow(::ServiceDesk).to receive(:enabled?).with(project).and_return(false)
      end

      it 'does not create a comment' do
        expect { receiver.execute }.to raise_error(Gitlab::Email::ProjectNotFound)
      end
    end
  end
end
