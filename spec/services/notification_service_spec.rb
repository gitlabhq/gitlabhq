require 'spec_helper'

describe NotificationService do
  let(:notification) { NotificationService.new }

  describe 'Keys' do
    describe :new_key do
      let(:key) { create(:personal_key) }

      it { notification.new_key(key).should be_true }

      it 'should sent email to key owner' do
        Notify.should_receive(:new_ssh_key_email).with(key.id)
        notification.new_key(key)
      end
    end
  end

  describe 'Notes' do
    context 'issue note' do
      let(:issue) { create(:issue, assignee: create(:user)) }
      let(:note) { create(:note_on_issue, noteable: issue, project_id: issue.project_id, note: '@mention referenced') }

      before do
        build_team(note.project)
      end

      describe :new_note do
        it do
          should_email(@u_watcher.id)
          should_email(note.noteable.author_id)
          should_email(note.noteable.assignee_id)
          should_email(@u_mentioned.id)
          should_not_email(note.author_id)
          should_not_email(@u_participating.id)
          should_not_email(@u_disabled.id)
          notification.new_note(note)
        end

        def should_email(user_id)
          Notify.should_receive(:note_issue_email).with(user_id, note.id)
        end

        def should_not_email(user_id)
          Notify.should_not_receive(:note_issue_email).with(user_id, note.id)
        end
      end
    end

    context 'commit note' do
      let(:note) { create :note_on_commit }

      before do
        build_team(note.project)
      end

      describe :new_note do
        it do
          should_email(@u_watcher.id)
          should_not_email(note.author_id)
          should_not_email(@u_participating.id)
          should_not_email(@u_disabled.id)
          notification.new_note(note)
        end

        it do
          create(:note_on_commit,
                 author: @u_participating,
                 project_id: note.project_id,
                 commit_id: note.commit_id)

          should_email(@u_watcher.id)
          should_email(@u_participating.id)
          should_not_email(note.author_id)
          should_not_email(@u_disabled.id)
          notification.new_note(note)
        end

        def should_email(user_id)
          Notify.should_receive(:note_commit_email).with(user_id, note.id)
        end

        def should_not_email(user_id)
          Notify.should_not_receive(:note_commit_email).with(user_id, note.id)
        end
      end
    end
  end

  describe 'Issues' do
    let(:issue) { create :issue, assignee: create(:user) }

    before do
      build_team(issue.project)
    end

    describe :new_issue do
      it do
        should_email(issue.assignee_id)
        should_email(@u_watcher.id)
        should_not_email(@u_participating.id)
        should_not_email(@u_disabled.id)
        notification.new_issue(issue, @u_disabled)
      end

      def should_email(user_id)
        Notify.should_receive(:new_issue_email).with(user_id, issue.id)
      end

      def should_not_email(user_id)
        Notify.should_not_receive(:new_issue_email).with(user_id, issue.id)
      end
    end

    describe :reassigned_issue do
      it 'should email new assignee' do
        should_email(issue.assignee_id)
        should_email(@u_watcher.id)
        should_not_email(@u_participating.id)
        should_not_email(@u_disabled.id)

        notification.reassigned_issue(issue, @u_disabled)
      end

      def should_email(user_id)
        Notify.should_receive(:reassigned_issue_email).with(user_id, issue.id, issue.assignee_id)
      end

      def should_not_email(user_id)
        Notify.should_not_receive(:reassigned_issue_email).with(user_id, issue.id, issue.assignee_id)
      end
    end

    describe :close_issue do
      it 'should sent email to issue assignee and issue author' do
        should_email(issue.assignee_id)
        should_email(issue.author_id)
        should_email(@u_watcher.id)
        should_not_email(@u_participating.id)
        should_not_email(@u_disabled.id)

        notification.close_issue(issue, @u_disabled)
      end

      def should_email(user_id)
        Notify.should_receive(:closed_issue_email).with(user_id, issue.id, @u_disabled.id)
      end

      def should_not_email(user_id)
        Notify.should_not_receive(:closed_issue_email).with(user_id, issue.id, @u_disabled.id)
      end
    end
  end

  describe 'Merge Requests' do
    let(:merge_request) { create :merge_request, assignee: create(:user) }

    before do
      build_team(merge_request.project)
    end

    describe :new_merge_request do
      it do
        should_email(merge_request.assignee_id)
        should_email(@u_watcher.id)
        should_not_email(@u_participating.id)
        should_not_email(@u_disabled.id)
        notification.new_merge_request(merge_request, @u_disabled)
      end

      def should_email(user_id)
        Notify.should_receive(:new_merge_request_email).with(user_id, merge_request.id)
      end

      def should_not_email(user_id)
        Notify.should_not_receive(:new_merge_request_email).with(user_id, merge_request.id)
      end
    end

    describe :reassigned_merge_request do
      it do
        should_email(merge_request.assignee_id)
        should_email(@u_watcher.id)
        should_not_email(@u_participating.id)
        should_not_email(@u_disabled.id)
        notification.reassigned_merge_request(merge_request, merge_request.author)
      end

      def should_email(user_id)
        Notify.should_receive(:reassigned_merge_request_email).with(user_id, merge_request.id, merge_request.assignee_id)
      end

      def should_not_email(user_id)
        Notify.should_not_receive(:reassigned_merge_request_email).with(user_id, merge_request.id, merge_request.assignee_id)
      end
    end

    describe :closed_merge_request do
      it do
        should_email(merge_request.assignee_id)
        should_email(@u_watcher.id)
        should_not_email(@u_participating.id)
        should_not_email(@u_disabled.id)
        notification.close_mr(merge_request, @u_disabled)
      end

      def should_email(user_id)
        Notify.should_receive(:closed_merge_request_email).with(user_id, merge_request.id, @u_disabled.id)
      end

      def should_not_email(user_id)
        Notify.should_not_receive(:closed_merge_request_email).with(user_id, merge_request.id, @u_disabled.id)
      end
    end

    describe :merged_merge_request do
      it do
        should_email(merge_request.assignee_id)
        should_email(@u_watcher.id)
        should_not_email(@u_participating.id)
        should_not_email(@u_disabled.id)
        notification.merge_mr(merge_request)
      end

      def should_email(user_id)
        Notify.should_receive(:merged_merge_request_email).with(user_id, merge_request.id)
      end

      def should_not_email(user_id)
        Notify.should_not_receive(:merged_merge_request_email).with(user_id, merge_request.id)
      end
    end
  end

  def build_team(project)
    @u_watcher = create(:user, notification_level: Notification::N_WATCH)
    @u_participating = create(:user, notification_level: Notification::N_PARTICIPATING)
    @u_disabled = create(:user, notification_level: Notification::N_DISABLED)
    @u_mentioned = create(:user, username: 'mention', notification_level: Notification::N_WATCH)

    project.team << [@u_watcher, :master]
    project.team << [@u_participating, :master]
    project.team << [@u_disabled, :master]
    project.team << [@u_mentioned, :master]
  end
end
