require 'spec_helper'

describe NotificationService do
  let(:notification) { NotificationService.new }

  describe 'Keys' do
    describe :new_key do
      let!(:key) { create(:personal_key) }

      it { notification.new_key(key).should be_true }

      it 'should sent email to key owner' do
        Notify.should_receive(:new_ssh_key_email).with(key.id)
        notification.new_key(key)
      end
    end
  end

  describe 'Email' do
    describe :new_email do
      let!(:email) { create(:email) }

      it { notification.new_email(email).should be_true }

      it 'should send email to email owner' do
        Notify.should_receive(:new_email_email).with(email.id)
        notification.new_email(email)
      end
    end
  end

  describe 'Notes' do
    context 'issue note' do
      let(:issue) { create(:issue, assignee: create(:user)) }
      let(:mentioned_issue) { create(:issue, assignee: issue.assignee) }
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

        it 'filters out "mentioned in" notes' do
          mentioned_note = Note.create_cross_reference_note(mentioned_issue, issue, issue.author, issue.project)

          Notify.should_not_receive(:note_issue_email)
          notification.new_note(mentioned_note)
        end
      end

      describe 'new note on issue in project that belongs to a group' do
        let(:group) { create(:group) }

        before do
          note.project.namespace_id = group.id
          note.project.group.add_user(@u_watcher, UsersGroup::MASTER)
          note.project.save
          user_project = note.project.users_projects.find_by_user_id(@u_watcher.id)
          user_project.notification_level = Notification::N_PARTICIPATING
          user_project.save
          user_group = note.project.group.users_groups.find_by_user_id(@u_watcher.id)
          user_group.notification_level = Notification::N_GLOBAL
          user_group.save
        end

        it do
          should_email(note.noteable.author_id)
          should_email(note.noteable.assignee_id)
          should_email(@u_mentioned.id)
          should_not_email(@u_watcher.id)
          should_not_email(note.author_id)
          should_not_email(@u_participating.id)
          should_not_email(@u_disabled.id)
          notification.new_note(note)
        end
      end

      def should_email(user_id)
        Notify.should_receive(:note_issue_email).with(user_id, note.id)
      end

      def should_not_email(user_id)
        Notify.should_not_receive(:note_issue_email).with(user_id, note.id)
      end
    end

    context 'issue note mention' do
      let(:issue) { create(:issue, assignee: create(:user)) }
      let(:mentioned_issue) { create(:issue, assignee: issue.assignee) }
      let(:note) { create(:note_on_issue, noteable: issue, project_id: issue.project_id, note: '@all mentioned') }

      before do
        build_team(note.project)
      end

      describe :new_note do
        it do
          # Notify all team members
          note.project.team.members.each do |member|
            # User with disabled notification should not be notified
            next if member.id == @u_disabled.id
            should_email(member.id)
          end
          should_email(note.noteable.author_id)
          should_email(note.noteable.assignee_id)

          should_not_email(note.author_id)
          should_not_email(@u_disabled.id)
          should_not_email(@u_not_mentioned.id)
          notification.new_note(note)
        end

        it 'filters out "mentioned in" notes' do
          mentioned_note = Note.create_cross_reference_note(mentioned_issue, issue, issue.author, issue.project)

          Notify.should_not_receive(:note_issue_email)
          notification.new_note(mentioned_note)
        end
      end

      def should_email(user_id)
        Notify.should_receive(:note_issue_email).with(user_id, note.id)
      end

      def should_not_email(user_id)
        Notify.should_not_receive(:note_issue_email).with(user_id, note.id)
      end
    end

    context 'commit note' do
      let(:note) { create(:note_on_commit) }

      before do
        build_team(note.project)
        note.stub(:commit_author => @u_committer)
      end

      describe :new_note do
        it do
          should_email(@u_committer.id, note)
          should_email(@u_watcher.id, note)
          should_not_email(@u_mentioned.id, note)
          should_not_email(note.author_id, note)
          should_not_email(@u_participating.id, note)
          should_not_email(@u_disabled.id, note)
          notification.new_note(note)
        end

        it do
          note.update_attribute(:note, '@mention referenced')
          should_email(@u_committer.id, note)
          should_email(@u_watcher.id, note)
          should_email(@u_mentioned.id, note)
          should_not_email(note.author_id, note)
          should_not_email(@u_participating.id, note)
          should_not_email(@u_disabled.id, note)
          notification.new_note(note)
        end

        def should_email(user_id, n)
          Notify.should_receive(:note_commit_email).with(user_id, n.id)
        end

        def should_not_email(user_id, n)
          Notify.should_not_receive(:note_commit_email).with(user_id, n.id)
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
        Notify.should_receive(:reassigned_issue_email).with(user_id, issue.id, nil, @u_disabled.id)
      end

      def should_not_email(user_id)
        Notify.should_not_receive(:reassigned_issue_email).with(user_id, issue.id, issue.assignee_id, @u_disabled.id)
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

    describe :reopen_issue do
      it 'should send email to issue assignee and issue author' do
        should_email(issue.assignee_id)
        should_email(issue.author_id)
        should_email(@u_watcher.id)
        should_not_email(@u_participating.id)
        should_not_email(@u_disabled.id)

        notification.reopen_issue(issue, @u_disabled)
      end

      def should_email(user_id)
        Notify.should_receive(:issue_status_changed_email).with(user_id, issue.id, 'reopened', @u_disabled.id)
      end

      def should_not_email(user_id)
        Notify.should_not_receive(:issue_status_changed_email).with(user_id, issue.id, 'reopened', @u_disabled.id)
      end
    end
  end

  describe 'Merge Requests' do
    let(:merge_request) { create :merge_request, assignee: create(:user) }

    before do
      build_team(merge_request.target_project)
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
        Notify.should_receive(:reassigned_merge_request_email).with(user_id, merge_request.id, nil, merge_request.author_id)
      end

      def should_not_email(user_id)
        Notify.should_not_receive(:reassigned_merge_request_email).with(user_id, merge_request.id, merge_request.assignee_id, merge_request.author_id)
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
        notification.merge_mr(merge_request, @u_disabled)
      end

      def should_email(user_id)
        Notify.should_receive(:merged_merge_request_email).with(user_id, merge_request.id, @u_disabled.id)
      end

      def should_not_email(user_id)
        Notify.should_not_receive(:merged_merge_request_email).with(user_id, merge_request.id, @u_disabled.id)
      end
    end

    describe :reopen_merge_request do
      it do
        should_email(merge_request.assignee_id)
        should_email(@u_watcher.id)
        should_not_email(@u_participating.id)
        should_not_email(@u_disabled.id)
        notification.reopen_mr(merge_request, @u_disabled)
      end

      def should_email(user_id)
        Notify.should_receive(:merge_request_status_email).with(user_id, merge_request.id, 'reopened', @u_disabled.id)
      end

      def should_not_email(user_id)
        Notify.should_not_receive(:merge_request_status_email).with(user_id, merge_request.id, 'reopened', @u_disabled.id)
      end
    end
  end

  describe 'Projects' do
    let(:project) { create :project }

    before do
      build_team(project)
    end

    describe :project_was_moved do
      it do
        should_email(@u_watcher.id)
        should_email(@u_participating.id)
        should_not_email(@u_disabled.id)
        notification.project_was_moved(project)
      end

      def should_email(user_id)
        Notify.should_receive(:project_was_moved_email).with(project.id, user_id)
      end

      def should_not_email(user_id)
        Notify.should_not_receive(:project_was_moved_email).with(project.id, user_id)
      end
    end
  end

  def build_team(project)
    @u_watcher = create(:user, notification_level: Notification::N_WATCH)
    @u_participating = create(:user, notification_level: Notification::N_PARTICIPATING)
    @u_disabled = create(:user, notification_level: Notification::N_DISABLED)
    @u_mentioned = create(:user, username: 'mention', notification_level: Notification::N_PARTICIPATING)
    @u_committer = create(:user, username: 'committer')
    @u_not_mentioned = create(:user, username: 'regular', notification_level: Notification::N_PARTICIPATING)

    project.team << [@u_watcher, :master]
    project.team << [@u_participating, :master]
    project.team << [@u_disabled, :master]
    project.team << [@u_mentioned, :master]
    project.team << [@u_committer, :master]
  end
end
