require 'spec_helper'

describe NotificationService do
  let(:notification) { NotificationService.new }
  let(:deliveries) { Notify.deliveries }

  before(:each) do
    deliveries.clear
  end

  describe 'Keys' do
    describe :new_key do
      let!(:key) { create(:personal_key) }

      it { expect(notification.new_key(key)).to be_truthy }

      it 'should sent email to key owner' do
        notification.new_key(key)
        expect(sent?('SSH key was added to your account', key.user_id)).to be_truthy
      end
    end
  end

  describe 'Email' do
    describe :new_email do
      let!(:email) { create(:email) }

      it { expect(notification.new_email(email)).to be_truthy }

      it 'should send email to email owner' do
        notification.new_email(email)
        expect(sent?('Email was added to your account', email.user_id)).to be_truthy
      end
    end
  end

  describe 'Notes' do
    context 'issue note' do
      let(:project) { create(:empty_project, :private) }
      let(:issue) { create(:issue, project: project, assignee: create(:user)) }
      let(:mentioned_issue) { create(:issue, assignee: issue.assignee) }
      let(:note) { create(:note_on_issue, noteable: issue, project_id: issue.project_id, note: '@mention referenced, @outsider also') }

      before do
        build_team(note.project)
        project.team << [issue.author, :master]
        project.team << [issue.assignee, :master]
        project.team << [note.author, :master]
      end

      describe :new_note do
        it do
          add_users_with_subscription(note.project, issue)

          notification.new_note(note)

          should_email(@u_watcher.id)
          should_email(note.noteable.author_id)
          should_email(note.noteable.assignee_id)
          should_email(@u_mentioned.id)
          should_email(@subscriber.id)
          should_not_email(note.author_id)
          should_not_email(@u_participating.id)
          should_not_email(@u_disabled.id)
          should_not_email(@unsubscriber.id)
          should_not_email(@u_outsider_mentioned)
        end

        it 'filters out "mentioned in" notes' do
          mentioned_note = SystemNoteService.cross_reference(mentioned_issue, issue, issue.author)

          notification.new_note(mentioned_note)
          expect(deliveries.length).to eq(0)
        end
      end

      describe 'new note on issue in project that belongs to a group' do
        let(:group) { create(:group) }

        before do
          note.project.namespace_id = group.id
          note.project.group.add_user(@u_watcher, GroupMember::MASTER)
          note.project.save
          user_project = note.project.project_members.find_by_user_id(@u_watcher.id)
          user_project.notification_level = Notification::N_PARTICIPATING
          user_project.save
          group_member = note.project.group.group_members.find_by_user_id(@u_watcher.id)
          group_member.notification_level = Notification::N_GLOBAL
          group_member.save
        end

        it do
          notification.new_note(note)

          should_email(note.noteable.author_id)
          should_email(note.noteable.assignee_id)
          should_email(@u_mentioned.id)
          should_not_email(@u_watcher.id)
          should_not_email(note.author_id)
          should_not_email(@u_participating.id)
          should_not_email(@u_disabled.id)
        end
      end

      def should_email(user_id)
        expect(sent?(note.noteable.title, user_id)).to be_truthy
      end

      def should_not_email(user_id)
        expect(sent?(note.noteable.title, user_id)).to be_falsey
      end
    end

    context 'issue note mention' do
      let(:project) { create(:empty_project, :public) }
      let(:issue) { create(:issue, project: project, assignee: create(:user)) }
      let(:mentioned_issue) { create(:issue, assignee: issue.assignee) }
      let(:note) { create(:note_on_issue, noteable: issue, project_id: issue.project_id, note: '@all mentioned') }

      before do
        build_team(note.project)
      end

      describe :new_note do
        it do
          notification.new_note(note)

          # Notify all team members
          note.project.team.members.each do |member|
            # User with disabled notification should not be notified
            next if member.id == @u_disabled.id
            should_email(member.id)
          end
          should_email(note.noteable.author_id)
          should_email(note.noteable.assignee_id)

          should_not_email(note.author_id)
          should_not_email(@u_mentioned.id)
          should_not_email(@u_disabled.id)
          should_not_email(@u_not_mentioned.id)
        end

        it 'filters out "mentioned in" notes' do
          mentioned_note = SystemNoteService.cross_reference(mentioned_issue, issue, issue.author)

          notification.new_note(mentioned_note)
          expect(deliveries.length).to eq(0)
        end
      end

      def should_email(user_id)
        expect(sent?(note.noteable.title, user_id)).to be_truthy
      end

      def should_not_email(user_id)
        expect(sent?(note.noteable.title, user_id)).to be_falsey
      end
    end

    context 'commit note' do
      let(:project) { create(:project, :public) }
      let(:note) { create(:note_on_commit, project: project) }

      before do
        build_team(note.project)
        allow_any_instance_of(Commit).to receive(:author).and_return(@u_committer)
      end

      describe :new_note do
        it do
          notification.new_note(note)

          should_email(@u_committer.id, note)
          should_email(@u_watcher.id, note)
          should_not_email(@u_mentioned.id, note)
          should_not_email(note.author_id, note)
          should_not_email(@u_participating.id, note)
          should_not_email(@u_disabled.id, note)
        end

        it do
          note.update_attribute(:note, '@mention referenced')
          notification.new_note(note)

          should_email(@u_committer.id, note)
          should_email(@u_watcher.id, note)
          should_email(@u_mentioned.id, note)
          should_not_email(note.author_id, note)
          should_not_email(@u_participating.id, note)
          should_not_email(@u_disabled.id, note)
        end

        it do
          @u_committer.update_attributes(notification_level: Notification::N_MENTION)
          notification.new_note(note)

          should_not_email(@u_committer.id, note)
        end

        def should_email(user_id, n)
          expect(sent?(n.noteable.title, user_id)).to be_truthy
        end

        def should_not_email(user_id, n)
          expect(sent?(n.noteable.title, user_id)).to be_falsey
        end
      end
    end
  end

  describe 'Issues' do
    let(:project) { create(:empty_project, :public) }
    let(:issue) { create :issue, project: project, assignee: create(:user), description: 'cc @participant' }

    before do
      build_team(issue.project)
      add_users_with_subscription(issue.project, issue)
    end

    describe :new_issue do
      it do
        notification.new_issue(issue, @u_disabled)

        should_email(issue.assignee_id)
        should_email(@u_watcher.id)
        should_email(@u_participant_mentioned.id)
        should_not_email(@u_mentioned.id)
        should_not_email(@u_participating.id)
        should_not_email(@u_disabled.id)
      end

      it do
        issue.assignee.update_attributes(notification_level: Notification::N_MENTION)
        notification.new_issue(issue, @u_disabled)

        should_not_email(issue.assignee_id)
      end

      def should_email(user_id)
        expect(sent?(issue.title, user_id)).to be_truthy
      end

      def should_not_email(user_id)
        expect(sent?(issue.title, user_id)).to be_falsey
      end
    end

    describe :reassigned_issue do
      it 'should email new assignee' do
        notification.reassigned_issue(issue, @u_disabled)

        should_email(issue.assignee_id)
        should_email(@u_watcher.id)
        should_email(@u_participant_mentioned.id)
        should_email(@subscriber.id)
        should_not_email(@unsubscriber.id)
        should_not_email(@u_participating.id)
        should_not_email(@u_disabled.id)
      end

      def should_email(user_id)
        expect(sent?(issue.title, user_id)).to be_truthy
      end

      def should_not_email(user_id)
        expect(sent?(issue.title, user_id)).to be_falsey
      end
    end

    describe :close_issue do
      it 'should sent email to issue assignee and issue author' do
        notification.close_issue(issue, @u_disabled)

        should_email(issue.assignee_id)
        should_email(issue.author_id)
        should_email(@u_watcher.id)
        should_email(@u_participant_mentioned.id)
        should_email(@subscriber.id)
        should_not_email(@unsubscriber.id)
        should_not_email(@u_participating.id)
        should_not_email(@u_disabled.id)
      end

      def should_email(user_id)
        expect(sent?(issue.title, user_id)).to be_truthy
      end

      def should_not_email(user_id)
        expect(sent?(issue.title, user_id)).to be_falsey
      end
    end

    describe :reopen_issue do
      it 'should send email to issue assignee and issue author' do
        notification.reopen_issue(issue, @u_disabled)

        should_email(issue.assignee_id)
        should_email(issue.author_id)
        should_email(@u_watcher.id)
        should_email(@u_participant_mentioned.id)
        should_email(@subscriber.id)
        should_not_email(@unsubscriber.id)
        should_not_email(@u_participating.id)
        should_not_email(@u_disabled.id)
      end

      def should_email(user_id)
        expect(sent?(issue.title, user_id)).to be_truthy
      end

      def should_not_email(user_id)
        expect(sent?(issue.title, user_id)).to be_falsey
      end
    end
  end

  describe 'Merge Requests' do
    let(:project) { create(:project, :public) }
    let(:merge_request) { create :merge_request, source_project: project, assignee: create(:user), description: 'cc @participant' }

    before do
      build_team(merge_request.target_project)
      add_users_with_subscription(merge_request.target_project, merge_request)
    end

    describe :new_merge_request do
      it do
        notification.new_merge_request(merge_request, @u_disabled)

        should_email(merge_request.assignee_id)
        should_email(@u_watcher.id)
        should_email(@u_participant_mentioned.id)
        should_not_email(@u_participating.id)
        should_not_email(@u_disabled.id)
      end

      def should_email(user_id)
        expect(sent?(merge_request.title, user_id)).to be_truthy
      end

      def should_not_email(user_id)
        expect(sent?(merge_request.title, user_id)).to be_falsey
      end
    end

    describe :reassigned_merge_request do
      it do
        notification.reassigned_merge_request(merge_request, merge_request.author)

        should_email(merge_request.assignee_id)
        should_email(@u_watcher.id)
        should_email(@u_participant_mentioned.id)
        should_email(@subscriber.id)
        should_not_email(@unsubscriber.id)
        should_not_email(@u_participating.id)
        should_not_email(@u_disabled.id)
      end

      def should_email(user_id)
        expect(sent?(merge_request.title, user_id)).to be_truthy
      end

      def should_not_email(user_id)
        expect(sent?(merge_request.title, user_id)).to be_falsey
      end
    end

    describe :closed_merge_request do
      it do
        notification.close_mr(merge_request, @u_disabled)
        should_email(merge_request.assignee_id)
        should_email(@u_watcher.id)
        should_email(@u_participant_mentioned.id)
        should_email(@subscriber.id)
        should_not_email(@unsubscriber.id)
        should_not_email(@u_participating.id)
        should_not_email(@u_disabled.id)
      end

      def should_email(user_id)
        expect(sent?(merge_request.title, user_id)).to be_truthy
      end

      def should_not_email(user_id)
        expect(sent?(merge_request.title, user_id)).to be_falsey
      end
    end

    describe :merged_merge_request do
      it do
        notification.merge_mr(merge_request, @u_disabled)
        should_email(merge_request.assignee_id)
        should_email(@u_watcher.id)
        should_email(@u_participant_mentioned.id)
        should_email(@subscriber.id)
        should_not_email(@unsubscriber.id)
        should_not_email(@u_participating.id)
        should_not_email(@u_disabled.id)
      end

      def should_email(user_id)
        expect(sent?(merge_request.title, user_id)).to be_truthy
      end

      def should_not_email(user_id)
        expect(sent?(merge_request.title, user_id)).to be_falsey
      end
    end

    describe :reopen_merge_request do
      it do
        notification.reopen_mr(merge_request, @u_disabled)
        should_email(merge_request.assignee_id)
        should_email(@u_watcher.id)
        should_email(@u_participant_mentioned.id)
        should_email(@subscriber.id)
        should_not_email(@unsubscriber.id)
        should_not_email(@u_participating.id)
        should_not_email(@u_disabled.id)
      end

      def should_email(user_id)
        expect(sent?(merge_request.title, user_id)).to be_truthy
      end

      def should_not_email(user_id)
        expect(sent?(merge_request.title, user_id)).to be_falsey
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
        notification.project_was_moved(project, "gitlab/gitlab")
        should_email(@u_watcher.id)
        should_email(@u_participating.id)
        should_not_email(@u_disabled.id)
      end

      def should_email(user_id)
        expect(sent?('Project was moved', user_id)).to be_truthy
      end

      def should_not_email(user_id)
        expect(sent?('Project was moved', user_id)).to be_falsey
      end
    end
  end

  def build_team(project)
    @u_watcher = create(:user, notification_level: Notification::N_WATCH)
    @u_participating = create(:user, notification_level: Notification::N_PARTICIPATING)
    @u_participant_mentioned = create(:user, username: 'participant', notification_level: Notification::N_PARTICIPATING)
    @u_disabled = create(:user, notification_level: Notification::N_DISABLED)
    @u_mentioned = create(:user, username: 'mention', notification_level: Notification::N_MENTION)
    @u_committer = create(:user, username: 'committer')
    @u_not_mentioned = create(:user, username: 'regular', notification_level: Notification::N_PARTICIPATING)
    @u_outsider_mentioned = create(:user, username: 'outsider')

    project.team << [@u_watcher, :master]
    project.team << [@u_participating, :master]
    project.team << [@u_participant_mentioned, :master]
    project.team << [@u_disabled, :master]
    project.team << [@u_mentioned, :master]
    project.team << [@u_committer, :master]
    project.team << [@u_not_mentioned, :master]
  end

  def add_users_with_subscription(project, issuable)
    @subscriber = create :user
    @unsubscriber = create :user

    project.team << [@subscriber, :master]
    project.team << [@unsubscriber, :master]

    issuable.subscriptions.create(user: @subscriber, subscribed: true)
    issuable.subscriptions.create(user: @unsubscriber, subscribed: false)
  end

  def sent?(subject, recipient_id)
    recipient = User.find(recipient_id)

    deliveries.any? do |delivery|
      delivery.subject.include?(subject) &&
        delivery.to.include?(recipient.notification_email)
    end
  end
end
