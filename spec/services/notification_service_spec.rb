# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotificationService, :mailer do
  include EmailSpec::Matchers
  include ExternalAuthorizationServiceHelpers
  include NotificationHelpers

  let_it_be(:project, reload: true) { create(:project, :public) }
  let_it_be_with_refind(:assignee) { create(:user) }

  let(:notification) { described_class.new }

  around(:example, :deliver_mails_inline) do |example|
    # This is a temporary `around` hook until all the examples check the
    # background jobs queue instead of the delivered emails array.
    # `perform_enqueued_jobs` makes the ActiveJob jobs (e.g. mailer jobs) run inline
    # compared to `Sidekiq::Testing.inline!` which makes the Sidekiq jobs run inline.
    perform_enqueued_jobs { example.run }
  end

  shared_examples 'altered milestone notification on issue' do
    it 'sends the email to the correct people' do
      should_email(subscriber_to_new_milestone)
      issue.assignees.each do |a|
        should_email(a)
      end
      should_email(@u_watcher)
      should_email(@u_guest_watcher)
      should_email(@u_participant_mentioned)
      should_email(@subscriber)
      should_email(@subscribed_participant)
      should_email(@watcher_and_subscriber)
      should_not_email(@u_guest_custom)
      should_not_email(@u_committer)
      should_not_email(@unsubscriber)
      should_not_email(@u_participating)
      should_not_email(@u_lazy_participant)
      should_not_email(issue.author)
      should_not_email(@u_disabled)
      should_not_email(@u_custom_global)
      should_not_email(@u_mentioned)
    end
  end

  shared_examples 'altered milestone notification on merge request' do
    it 'sends the email to the correct people' do
      should_email(subscriber_to_new_milestone)
      merge_request.assignees.each do |a|
        should_email(a)
      end
      should_email(@u_watcher)
      should_email(@u_guest_watcher)
      should_email(@u_participant_mentioned)
      should_email(@subscriber)
      should_email(@subscribed_participant)
      should_email(@watcher_and_subscriber)
      should_not_email(@u_guest_custom)
      should_not_email(@u_committer)
      should_not_email(@unsubscriber)
      should_not_email(@u_participating)
      should_not_email(@u_lazy_participant)
      should_not_email(merge_request.author)
      should_not_email(@u_disabled)
      should_not_email(@u_custom_global)
      should_not_email(@u_mentioned)
    end
  end

  shared_examples 'notifications for new mentions' do
    it 'sends no emails when no new mentions are present' do
      send_notifications
      should_not_email_anyone
    end

    it 'emails new mentions with a watch level higher than mention' do
      send_notifications(@u_watcher, @u_participant_mentioned, @u_custom_global, @u_mentioned)
      should_only_email(@u_watcher, @u_participant_mentioned, @u_custom_global, @u_mentioned)
    end

    it 'does not email new mentions with a watch level equal to or less than mention' do
      send_notifications(@u_disabled)
      should_not_email_anyone
    end

    it 'emails new mentions despite being unsubscribed' do
      send_notifications(@unsubscribed_mentioned)

      should_only_email(@unsubscribed_mentioned)
    end

    it 'sends the proper notification reason header' do
      send_notifications(@u_watcher)
      should_only_email(@u_watcher)
      email = find_email_for(@u_watcher)

      expect(email).to have_header('X-GitLab-NotificationReason', NotificationReason::MENTIONED)
    end
  end

  shared_examples 'is not able to send notifications' do
    it 'does not send any notification' do
      user_1 = create(:user)
      recipient_1 = NotificationRecipient.new(user_1, :custom, custom_action: :new_release)
      allow(NotificationRecipients::BuildService).to receive(:build_new_release_recipients).and_return([recipient_1])

      expect(Gitlab::AppLogger).to receive(:warn).with(message: 'Skipping sending notifications', user: current_user.id, klass: object.class.to_s, object_id: object.id)

      action

      should_not_email(@u_mentioned)
      should_not_email(@u_guest_watcher)
      should_not_email(user_1)
      should_not_email(current_user)
    end
  end

  # Next shared examples are intended to test notifications of "participants"
  #
  # they take the following parameters:
  # * issuable
  # * notification trigger
  # * participant
  #
  shared_examples 'participating by note notification' do
    it 'emails the participant' do
      create(:note_on_issue, noteable: issuable, project_id: project.id, note: 'anything', author: participant)

      notification_trigger

      should_email(participant)
    end

    context 'for subgroups' do
      before do
        build_group(project)
      end

      it 'emails the participant' do
        create(:note_on_issue, noteable: issuable, project_id: project.id, note: 'anything', author: @pg_participant)

        notification_trigger

        should_email_nested_group_user(@pg_participant)
      end
    end
  end

  shared_examples 'participating by assignee notification' do
    it 'emails the participant' do
      issuable.assignees << participant

      notification_trigger

      should_email(participant)
    end
  end

  shared_examples 'participating by author notification' do
    it 'emails the participant' do
      issuable.author = participant

      notification_trigger

      should_email(participant)
    end
  end

  shared_examples 'participating by reviewer notification' do
    it 'emails the participant' do
      issuable.reviewers << participant

      notification_trigger

      should_email(participant)
    end
  end

  shared_examples_for 'participating notifications' do
    it_behaves_like 'participating by note notification'
    it_behaves_like 'participating by author notification'
    it_behaves_like 'participating by assignee notification'
  end

  describe '#async' do
    let(:async) { notification.async }

    let_it_be(:key) { create(:personal_key) }

    it 'returns an Async object with the correct parent' do
      expect(async).to be_a(described_class::Async)
      expect(async.parent).to eq(notification)
    end

    context 'when receiving a public method' do
      it 'schedules a MailScheduler::NotificationServiceWorker' do
        expect(MailScheduler::NotificationServiceWorker)
          .to receive(:perform_async).with('new_key', key)

        async.new_key(key)
      end
    end

    context 'when receiving a private method' do
      it 'raises NoMethodError' do
        expect { async.notifiable?(key) }.to raise_error(NoMethodError)
      end
    end

    context 'when receiving a non-existent method' do
      it 'raises NoMethodError' do
        expect { async.foo(key) }.to raise_error(NoMethodError)
      end
    end
  end

  describe 'Keys' do
    describe '#new_key' do
      let(:key_options) { {} }
      let!(:key) { build_stubbed(:personal_key, key_options) }

      subject { notification.new_key(key) }

      it "sends email to key owner" do
        expect { subject }.to have_enqueued_email(key.id, mail: "new_ssh_key_email")
      end

      describe "never emails the ghost user" do
        let(:key_options) { { user: User.ghost } }

        it "does not send email to key owner" do
          expect { subject }.not_to have_enqueued_email(key.id, mail: "new_ssh_key_email")
        end
      end
    end
  end

  describe 'GpgKeys' do
    describe '#new_gpg_key' do
      let(:key_options) { {} }
      let(:key) { create(:gpg_key, key_options) }

      subject { notification.new_gpg_key(key) }

      it "sends email to key owner" do
        expect { subject }.to have_enqueued_email(key.id, mail: "new_gpg_key_email")
      end

      describe "never emails the ghost user" do
        let(:key_options) { { user: User.ghost } }

        it "does not send email to key owner" do
          expect { subject }.not_to have_enqueued_email(key.id, mail: "new_gpg_key_email")
        end
      end
    end
  end

  describe 'AccessToken' do
    describe '#access_token_about_to_expire' do
      let_it_be(:user) { create(:user) }
      let_it_be(:pat) { create(:personal_access_token, user: user, expires_at: 5.days.from_now) }

      subject { notification.access_token_about_to_expire(user, [pat.name]) }

      it 'sends email to the token owner' do
        expect { subject }.to have_enqueued_email(user, [pat.name], mail: "access_token_about_to_expire_email")
      end
    end

    describe '#access_token_expired' do
      let_it_be(:user) { create(:user) }

      subject { notification.access_token_expired(user) }

      it 'sends email to the token owner' do
        expect { subject }.to have_enqueued_email(user, mail: "access_token_expired_email")
      end

      context 'when user is not allowed to receive notifications' do
        before do
          user.block!
        end

        it 'does not send email to the token owner' do
          expect { subject }.not_to have_enqueued_email(user, mail: "access_token_expired_email")
        end
      end
    end
  end

  describe 'SSH Keys' do
    let_it_be_with_reload(:user) { create(:user) }
    let_it_be(:fingerprints) { ["aa:bb:cc:dd:ee:zz"] }

    shared_context 'block user' do
      before do
        user.block!
      end
    end

    describe '#ssh_key_expired' do
      subject { notification.ssh_key_expired(user, fingerprints) }

      it 'sends email to the token owner' do
        expect { subject }.to have_enqueued_email(user, fingerprints, mail: "ssh_key_expired_email")
      end

      context 'when user is not allowed to receive notifications' do
        include_context 'block user'

        it 'does not send email to the token owner' do
          expect { subject }.not_to have_enqueued_email(user, fingerprints, mail: "ssh_key_expired_email")
        end
      end
    end

    describe '#ssh_key_expiring_soon' do
      subject { notification.ssh_key_expiring_soon(user, fingerprints) }

      it 'sends email to the token owner' do
        expect { subject }.to have_enqueued_email(user, fingerprints, mail: "ssh_key_expiring_soon_email")
      end

      context 'when user is not allowed to receive notifications' do
        include_context 'block user'

        it 'does not send email to the token owner' do
          expect { subject }.not_to have_enqueued_email(user, fingerprints, mail: "ssh_key_expiring_soon_email")
        end
      end
    end
  end

  describe '#unknown_sign_in' do
    let_it_be(:user) { create(:user) }
    let_it_be(:ip) { '127.0.0.1' }
    let_it_be(:time) { Time.current }

    subject { notification.unknown_sign_in(user, ip, time) }

    it 'sends email to the user' do
      expect { subject }.to have_enqueued_email(user, ip, time, mail: 'unknown_sign_in_email')
    end
  end

  describe '#disabled_two_factor' do
    let_it_be(:user) { create(:user) }

    subject { notification.disabled_two_factor(user) }

    it 'sends email to the user' do
      expect { subject }.to have_enqueued_email(user, mail: 'disabled_two_factor_email')
    end
  end

  describe 'Notes' do
    context 'issue note' do
      let_it_be(:project) { create(:project, :private) }
      let_it_be_with_reload(:issue) { create(:issue, project: project, assignees: [assignee]) }
      let_it_be(:mentioned_issue) { create(:issue, assignees: issue.assignees) }
      let_it_be_with_reload(:author) { create(:user) }

      let(:note) { create(:note_on_issue, author: author, noteable: issue, project_id: issue.project_id, note: '@mention referenced, @unsubscribed_mentioned and @outsider also') }

      subject { notification.new_note(note) }

      context 'issue_email_participants' do
        before do
          allow(Notify).to receive(:service_desk_new_note_email)
                             .with(Integer, Integer, String).and_return(mailer)

          allow(::Gitlab::IncomingEmail).to receive(:enabled?) { true }
          allow(::Gitlab::IncomingEmail).to receive(:supports_wildcard?) { true }
        end

        let(:subject) { NotificationService.new }
        let(:mailer) { double(deliver_later: true) }
        let(:issue) { create(:issue, author: User.support_bot) }
        let(:project) { issue.project }
        let(:note) { create(:note, noteable: issue, project: project) }

        shared_examples 'notification with exact metric events' do |number_of_events|
          it 'adds metric event' do
            metric_transaction = double('Gitlab::Metrics::WebTransaction', increment: true, observe: true)
            allow(::Gitlab::Metrics::BackgroundTransaction).to receive(:current).and_return(metric_transaction)
            expect(metric_transaction).to receive(:add_event).with(:service_desk_new_note_email).exactly(number_of_events).times

            subject.new_note(note)
          end
        end

        shared_examples 'no participants are notified' do
          it 'does not send the email' do
            expect(Notify).not_to receive(:service_desk_new_note_email)

            subject.new_note(note)
          end

          it_behaves_like 'notification with exact metric events', 0
        end

        it_behaves_like 'no participants are notified'

        context 'do exist and note not confidential' do
          let!(:issue_email_participant) { issue.issue_email_participants.create!(email: 'service.desk@example.com') }

          before do
            issue.update!(external_author: 'service.desk@example.com')
            project.update!(service_desk_enabled: true)
          end

          it 'sends the email' do
            expect(Notify).to receive(:service_desk_new_note_email)
              .with(issue.id, note.id, issue.external_author)

            subject.new_note(note)
          end

          it_behaves_like 'notification with exact metric events', 1
        end

        context 'do exist and note is confidential' do
          let(:note) { create(:note, noteable: issue, project: project, confidential: true) }
          let!(:issue_email_participant) { issue.issue_email_participants.create!(email: 'service.desk@example.com') }

          before do
            issue.update!(external_author: 'service.desk@example.com')
            project.update!(service_desk_enabled: true)
          end

          it_behaves_like 'no participants are notified'
        end
      end

      describe '#new_note' do
        before_all do
          build_team(project)
          project.add_maintainer(issue.author)
          project.add_maintainer(assignee)
          project.add_maintainer(author)

          @u_custom_off = create_user_with_notification(:custom, 'custom_off')
          project.add_guest(@u_custom_off)

          create(
            :note_on_issue,
            author: @u_custom_off,
            noteable: issue,
            project_id: issue.project_id,
            note: 'i think @subscribed_participant should see this'
          )

          update_custom_notification(:new_note, @u_guest_custom, resource: project)
          update_custom_notification(:new_note, @u_custom_global)
        end

        context 'with users' do
          before_all do
            add_users(project)
            add_user_subscriptions(issue)
          end

          before do
            reset_delivered_emails!
          end

          it 'sends emails to recipients', :aggregate_failures do
            subject

            expect_delivery_jobs_count(10)
            expect_enqueud_email(@u_watcher.id, note.id, nil, mail: "note_issue_email")
            expect_enqueud_email(note.noteable.author.id, note.id, nil, mail: "note_issue_email")
            expect_enqueud_email(note.noteable.assignees.first.id, note.id, nil, mail: "note_issue_email")
            expect_enqueud_email(@u_custom_global.id, note.id, nil, mail: "note_issue_email")
            expect_enqueud_email(@u_mentioned.id, note.id, "mentioned", mail: "note_issue_email")
            expect_enqueud_email(@subscriber.id, note.id, "subscribed", mail: "note_issue_email")
            expect_enqueud_email(@watcher_and_subscriber.id, note.id, "subscribed", mail: "note_issue_email")
            expect_enqueud_email(@subscribed_participant.id, note.id, "subscribed", mail: "note_issue_email")
            expect_enqueud_email(@u_custom_off.id, note.id, nil, mail: "note_issue_email")
            expect_enqueud_email(@unsubscribed_mentioned.id, note.id, "mentioned", mail: "note_issue_email")
          end

          it "emails the note author if they've opted into notifications about their activity", :deliver_mails_inline do
            note.author.notified_of_own_activity = true

            notification.new_note(note)

            should_email(note.author)
            expect(find_email_for(note.author)).to have_header('X-GitLab-NotificationReason', 'own_activity')
          end

          it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
            let(:notification_target)  { note }
            let(:notification_trigger) { notification.new_note(note) }
          end
        end

        it 'filters out "mentioned in" notes' do
          mentioned_note = SystemNoteService.cross_reference(mentioned_issue, issue, issue.author)
          reset_delivered_emails!

          notification.new_note(mentioned_note)

          expect_no_delivery_jobs
        end

        context 'participating' do
          context 'by note' do
            before do
              note.author = @u_lazy_participant
              note.save!
            end

            it { expect { subject }.not_to have_enqueued_email(@u_lazy_participant.id, note.id, mail: "note_issue_email") }
          end
        end

        context 'in project that belongs to a group' do
          let_it_be(:parent_group) { create(:group) }

          before do
            note.project.namespace_id = group.id
            group.add_user(@u_watcher, GroupMember::MAINTAINER)
            group.add_user(@u_custom_global, GroupMember::MAINTAINER)
            note.project.save!

            @u_watcher.notification_settings_for(note.project).participating!
            @u_watcher.notification_settings_for(group).global!
            update_custom_notification(:new_note, @u_custom_global)
            reset_delivered_emails!
          end

          shared_examples 'new note notifications' do
            it 'sends notifications', :deliver_mails_inline do
              notification.new_note(note)

              should_email(note.noteable.author)
              should_email(note.noteable.assignees.first)
              should_email(@u_mentioned)
              should_email(@u_custom_global)
              should_not_email(@u_guest_custom)
              should_not_email(@u_guest_watcher)
              should_not_email(@u_watcher)
              should_not_email(note.author)
              should_not_email(@u_participating)
              should_not_email(@u_disabled)
              should_not_email(@u_lazy_participant)

              expect(find_email_for(@u_mentioned)).to have_header('X-GitLab-NotificationReason', 'mentioned')
              expect(find_email_for(@u_custom_global)).to have_header('X-GitLab-NotificationReason', '')
            end
          end

          context 'which is a top-level group' do
            let!(:group) { parent_group }

            it_behaves_like 'new note notifications'

            it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
              let(:notification_target)  { note }
              let(:notification_trigger) { notification.new_note(note) }
            end
          end

          context 'which is a subgroup' do
            let!(:group) { create(:group, parent: parent_group) }

            it_behaves_like 'new note notifications'

            it 'overrides child objects with global level' do
              user = create(:user)
              parent_group.add_developer(user)
              user.notification_settings_for(parent_group).watch!
              reset_delivered_emails!

              notification.new_note(note)

              expect_enqueud_email(user.id, note.id, nil, mail: "note_issue_email")
            end
          end
        end
      end
    end

    context 'confidential issue note' do
      let(:author) { create(:user) }
      let(:non_member) { create(:user) }
      let(:member) { create(:user) }
      let(:guest) { create(:user) }
      let(:admin) { create(:admin) }
      let(:confidential_issue) { create(:issue, :confidential, project: project, author: author, assignees: [assignee]) }
      let(:note) { create(:note_on_issue, noteable: confidential_issue, project: project, note: "#{author.to_reference} #{assignee.to_reference} #{non_member.to_reference} #{member.to_reference} #{admin.to_reference}") }
      let(:guest_watcher) { create_user_with_notification(:watch, "guest-watcher-confidential") }

      subject { notification.new_note(note) }

      before do
        project.add_developer(member)
        project.add_guest(guest)
        reset_delivered_emails!
      end

      it 'filters out users that can not read the issue' do
        subject

        expect_delivery_jobs_count(4)
        expect_enqueud_email(author.id, note.id, "mentioned", mail: "note_issue_email")
        expect_enqueud_email(assignee.id, note.id, "mentioned", mail: "note_issue_email")
        expect_enqueud_email(member.id, note.id, "mentioned", mail: "note_issue_email")
        expect_enqueud_email(admin.id, note.id, "mentioned", mail: "note_issue_email")
      end

      context 'on project that belongs to subgroup' do
        let(:group_reporter) { create(:user) }
        let(:group_guest) { create(:user) }
        let(:parent_group) { create(:group) }
        let(:child_group) { create(:group, parent: parent_group) }
        let(:project) { create(:project, namespace: child_group) }

        context 'when user is group guest member' do
          before do
            parent_group.add_reporter(group_reporter)
            parent_group.add_guest(group_guest)
            group_guest.notification_settings_for(parent_group).watch!
            group_reporter.notification_settings_for(parent_group).watch!
            reset_delivered_emails!
          end

          it 'does not email guest user' do
            subject

            expect_enqueud_email(group_reporter.id, note.id, nil, mail: "note_issue_email")
            expect_not_enqueud_email(group_guest.id, "mentioned", mail: "note_issue_email")
          end
        end
      end
    end

    context 'issue note mention', :deliver_mails_inline do
      let_it_be(:issue) { create(:issue, project: project, assignees: [assignee]) }
      let_it_be(:mentioned_issue) { create(:issue, assignees: issue.assignees) }
      let_it_be(:author) { create(:user) }

      let(:note) { create(:note_on_issue, author: author, noteable: issue, project_id: issue.project_id, note: '@all mentioned') }

      before_all do
        build_team(project)
        build_group(project)
        add_users(project)
        add_user_subscriptions(issue)
        project.add_maintainer(author)
      end

      before do
        reset_delivered_emails!
      end

      describe '#new_note' do
        it 'notifies the team members' do
          notification.new_note(note)

          # Make sure @unsubscribed_mentioned is part of the team
          expect(note.project.team.members).to include(@unsubscribed_mentioned)

          # Notify all team members
          note.project.team.members.each do |member|
            # User with disabled notification should not be notified
            next if member.id == @u_disabled.id
            # Author should not be notified
            next if member.id == note.author.id

            should_email(member)
          end

          should_email(@u_guest_watcher)
          should_email(note.noteable.author)
          should_email(note.noteable.assignees.first)
          should_email_nested_group_user(@pg_watcher)
          should_email(@u_mentioned)
          should_email(@u_not_mentioned)
          should_not_email(note.author)
          should_not_email(@u_disabled)
          should_not_email_nested_group_user(@pg_disabled)
        end

        it 'notifies parent group members with mention level' do
          note = create(:note_on_issue, noteable: issue, project_id: issue.project_id, note: "@#{@pg_mention.username}")

          notification.new_note(note)

          should_email_nested_group_user(@pg_mention)
        end

        it 'filters out "mentioned in" notes' do
          mentioned_note = SystemNoteService.cross_reference(mentioned_issue, issue, issue.author)

          expect(Notify).not_to receive(:note_issue_email)
          notification.new_note(mentioned_note)
        end

        it_behaves_like 'project emails are disabled' do
          let(:notification_target)  { note }
          let(:notification_trigger) { notification.new_note(note) }
        end
      end
    end

    context 'project snippet note', :deliver_mails_inline do
      let(:snippet) { create(:project_snippet, project: project, author: create(:user)) }
      let(:author) { create(:user) }
      let(:note) { create(:note_on_project_snippet, author: author, noteable: snippet, project_id: project.id, note: '@all mentioned') }

      before do
        build_team(project)
        build_group(project)
        project.add_maintainer(author)

        # make sure these users can read the project snippet!
        project.add_guest(@u_guest_watcher)
        project.add_guest(@u_guest_custom)
        add_member_for_parent_group(@pg_watcher, project)
        reset_delivered_emails!
      end

      describe '#new_note' do
        it 'notifies the team members' do
          notification.new_note(note)
          # Notify all team members
          note.project.team.members.each do |member|
            # User with disabled notification should not be notified
            next if member.id == @u_disabled.id
            # Author should not be notified
            next if member.id == note.author.id

            should_email(member)
          end

          # it emails custom global users on mention
          should_email(@u_custom_global)

          should_email(@u_guest_watcher)
          should_email(note.noteable.author)
          should_not_email(note.author)
          should_email(@u_mentioned)
          should_not_email(@u_disabled)
          should_email(@u_not_mentioned)
        end
      end
    end

    context 'personal snippet note', :deliver_mails_inline do
      let(:snippet) { create(:personal_snippet, :public, author: @u_snippet_author) }
      let(:note)    { create(:note_on_personal_snippet, noteable: snippet, note: '@mentioned note', author: @u_note_author) }

      before do
        @u_watcher               = create_global_setting_for(create(:user), :watch)
        @u_participant           = create_global_setting_for(create(:user), :participating)
        @u_disabled              = create_global_setting_for(create(:user), :disabled)
        @u_mentioned             = create_global_setting_for(create(:user, username: 'mentioned'), :mention)
        @u_mentioned_level       = create_global_setting_for(create(:user, username: 'participator'), :mention)
        @u_note_author           = create(:user, username: 'note_author')
        @u_snippet_author        = create(:user, username: 'snippet_author')
        @u_not_mentioned         = create_global_setting_for(create(:user, username: 'regular'), :participating)

        reset_delivered_emails!
      end

      let!(:notes) do
        [
          create(:note_on_personal_snippet, noteable: snippet, note: 'note', author: @u_watcher),
          create(:note_on_personal_snippet, noteable: snippet, note: 'note', author: @u_participant),
          create(:note_on_personal_snippet, noteable: snippet, note: 'note', author: @u_mentioned),
          create(:note_on_personal_snippet, noteable: snippet, note: 'note', author: @u_disabled),
          create(:note_on_personal_snippet, noteable: snippet, note: 'note', author: @u_note_author)
        ]
      end

      describe '#new_note' do
        it 'notifies the participants' do
          notification.new_note(note)

          # it emails participants
          should_email(@u_watcher)
          should_email(@u_participant)
          should_email(@u_watcher)
          should_email(@u_snippet_author)

          # it emails mentioned users
          should_email(@u_mentioned)

          # it does not email participants with mention notification level
          should_not_email(@u_mentioned_level)

          # it does not email note author
          should_not_email(@u_note_author)
        end
      end
    end

    context 'commit note', :deliver_mails_inline do
      let_it_be(:project) { create(:project, :public, :repository) }
      let_it_be(:note) { create(:note_on_commit, project: project) }

      before_all do
        build_team(project)
        build_group(project)
        update_custom_notification(:new_note, @u_guest_custom, resource: project)
        update_custom_notification(:new_note, @u_custom_global)
      end

      before do
        reset_delivered_emails!
        allow(note.noteable).to receive(:author).and_return(@u_committer)
      end

      describe '#new_note, #perform_enqueued_jobs' do
        it do
          notification.new_note(note)
          should_email(@u_guest_watcher)
          should_email(@u_custom_global)
          should_email(@u_guest_custom)
          should_email(@u_committer)
          should_email(@u_watcher)
          should_email_nested_group_user(@pg_watcher)
          should_not_email(@u_mentioned)
          should_not_email(note.author)
          should_not_email(@u_participating)
          should_not_email(@u_disabled)
          should_not_email(@u_lazy_participant)
          should_not_email_nested_group_user(@pg_disabled)
        end

        it do
          note.update_attribute(:note, '@mention referenced')
          notification.new_note(note)

          should_email(@u_guest_watcher)
          should_email(@u_committer)
          should_email(@u_watcher)
          should_email(@u_mentioned)
          should_email_nested_group_user(@pg_watcher)
          should_not_email(note.author)
          should_not_email(@u_participating)
          should_not_email(@u_disabled)
          should_not_email(@u_lazy_participant)
          should_not_email_nested_group_user(@pg_disabled)
        end

        it do
          @u_committer = create_global_setting_for(@u_committer, :mention)
          notification.new_note(note)
          should_not_email(@u_committer)
        end

        it_behaves_like 'project emails are disabled' do
          let(:notification_target)  { note }
          let(:notification_trigger) { notification.new_note(note) }
        end
      end
    end

    context "merge request diff note", :deliver_mails_inline do
      let_it_be(:project) { create(:project, :repository) }
      let_it_be(:user) { create(:user) }
      let_it_be(:merge_request) { create(:merge_request, source_project: project, assignees: [user], author: create(:user)) }
      let_it_be(:note) { create(:diff_note_on_merge_request, project: project, noteable: merge_request) }

      before_all do
        build_team(note.project)
        project.add_maintainer(merge_request.author)
        merge_request.assignees.each { |assignee| project.add_maintainer(assignee) }
      end

      describe '#new_note' do
        it "records sent notifications" do
          # 3 SentNotification are sent: the MR assignee and author, and the @u_watcher
          expect(SentNotification).to receive(:record_note).with(note, any_args).exactly(3).times.and_call_original

          notification.new_note(note)

          expect(SentNotification.last(3).map(&:recipient).map(&:id))
            .to contain_exactly(*merge_request.assignees.pluck(:id), merge_request.author.id, @u_watcher.id)
          expect(SentNotification.last.in_reply_to_discussion_id).to eq(note.discussion_id)
        end

        it_behaves_like 'project emails are disabled' do
          let(:notification_target)  { note }
          let(:notification_trigger) { notification.new_note(note) }
        end
      end
    end

    context 'design diff note', :deliver_mails_inline do
      include DesignManagementTestHelpers

      let_it_be(:design) { create(:design, :with_file) }
      let_it_be(:project) { design.project }
      let_it_be(:member_and_mentioned) { create(:user, developer_projects: [project]) }
      let_it_be(:member_and_author_of_second_note) { create(:user, developer_projects: [project]) }
      let_it_be(:member_and_not_mentioned) { create(:user, developer_projects: [project]) }
      let_it_be(:non_member_and_mentioned) { create(:user) }
      let_it_be(:note) do
        create(:diff_note_on_design,
           noteable: design,
           note: "Hello #{member_and_mentioned.to_reference}, G'day #{non_member_and_mentioned.to_reference}")
      end

      let_it_be(:note_2) do
        create(:diff_note_on_design, noteable: design, author: member_and_author_of_second_note)
      end

      context 'design management is enabled' do
        before do
          enable_design_management
        end

        it 'sends new note notifications', :aggregate_failures do
          notification.new_note(note)

          should_email(design.authors.first)
          should_email(member_and_mentioned)
          should_email(member_and_author_of_second_note)
          should_not_email(member_and_not_mentioned)
          should_not_email(non_member_and_mentioned)
          should_not_email(note.author)
        end
      end

      context 'design management is disabled' do
        before do
          enable_design_management(false)
        end

        it 'does not notify anyone' do
          notification.new_note(note)

          should_not_email_anyone
        end
      end
    end
  end

  describe '#send_new_release_notifications', :deliver_mails_inline do
    let(:release) { create(:release, author: current_user) }
    let(:object) { release }
    let(:action) { notification.send_new_release_notifications(release) }

    context 'when release author is blocked' do
      let(:current_user) { create(:user, :blocked) }

      include_examples 'is not able to send notifications'
    end

    context 'when release author is a ghost' do
      let(:current_user) { create(:user, :ghost) }

      include_examples 'is not able to send notifications'
    end

    context 'when recipients for a new release exist' do
      let(:current_user) { create(:user) }

      it 'calls new_release_email for each relevant recipient' do
        user_1 = create(:user)
        user_2 = create(:user)
        user_3 = create(:user)
        recipient_1 = NotificationRecipient.new(user_1, :custom, custom_action: :new_release)
        recipient_2 = NotificationRecipient.new(user_2, :custom, custom_action: :new_release)
        allow(NotificationRecipients::BuildService).to receive(:build_new_release_recipients).and_return([recipient_1, recipient_2])

        notification.send_new_release_notifications(release)

        should_email(user_1)
        should_email(user_2)
        should_not_email(user_3)
      end
    end
  end

  describe 'Participating project notification settings have priority over group and global settings if available', :deliver_mails_inline do
    let_it_be(:group) { create(:group) }
    let_it_be(:maintainer) { group.add_owner(create(:user, username: 'maintainer')).user }
    let_it_be(:user1) { group.add_developer(create(:user, username: 'user_with_project_and_custom_setting')).user }
    let_it_be(:project) { create(:project, :public, namespace: group) }

    let(:issue) { create :issue, project: project, assignees: [assignee], description: '' }

    before do
      reset_delivered_emails!

      create_notification_setting(user1, project, :participating)
    end

    context 'custom on group' do
      [nil, true].each do |new_issue_value|
        value_caption = new_issue_value || 'nil'
        it "does not send an email to user1 when a new issue is created and new_issue is set to #{value_caption}" do
          update_custom_notification(:new_issue, user1, resource: group, value: new_issue_value)

          notification.new_issue(issue, maintainer)
          should_not_email(user1)
        end
      end
    end

    context 'watch on group' do
      it 'does not send an email' do
        user1.notification_settings_for(group).update!(level: :watch)

        notification.new_issue(issue, maintainer)
        should_not_email(user1)
      end
    end

    context 'custom on global, global on group' do
      it 'does not send an email' do
        user1.notification_settings_for(nil).update!(level: :custom)

        user1.notification_settings_for(group).update!(level: :global)

        notification.new_issue(issue, maintainer)
        should_not_email(user1)
      end
    end

    context 'watch on global, global on group' do
      it 'does not send an email' do
        user1.notification_settings_for(nil).update!(level: :watch)

        user1.notification_settings_for(group).update!(level: :global)

        notification.new_issue(issue, maintainer)
        should_not_email(user1)
      end
    end
  end

  describe 'Issues', :deliver_mails_inline do
    let(:another_project) { create(:project, :public, namespace: group) }
    let(:issue) { create :issue, project: project, assignees: [assignee], description: 'cc @participant @unsubscribed_mentioned' }

    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :public, namespace: group) }

    before_all do
      build_team(project)
      build_group(project)
      add_users(project)
    end

    before do
      add_user_subscriptions(issue)
      reset_delivered_emails!
      update_custom_notification(:new_issue, @u_guest_custom, resource: project)
      update_custom_notification(:new_issue, @u_custom_global)

      issue.author.notified_of_own_activity = false
    end

    describe '#new_issue' do
      it 'notifies the expected users' do
        notification.new_issue(issue, @u_disabled)

        should_email(assignee)
        should_email(@u_watcher)
        should_email(@u_guest_watcher)
        should_email(@u_guest_custom)
        should_email(@u_custom_global)
        should_email(@u_participant_mentioned)
        should_email(@g_global_watcher)
        should_email(@g_watcher)
        should_email(@unsubscribed_mentioned)
        should_email_nested_group_user(@pg_watcher)
        should_not_email(@u_mentioned)
        should_not_email(@u_participating)
        should_not_email(@u_disabled)
        should_not_email(@u_lazy_participant)
        should_not_email_nested_group_user(@pg_disabled)
        should_not_email_nested_group_user(@pg_mention)
      end

      it do
        create_global_setting_for(issue.assignees.first, :mention)
        notification.new_issue(issue, @u_disabled)

        should_not_email(issue.assignees.first)
      end

      it 'properly prioritizes notification reason' do
        # have assignee be both assigned and mentioned
        issue.update_attribute(:description, "/cc #{assignee.to_reference} #{@u_mentioned.to_reference}")

        notification.new_issue(issue, @u_disabled)

        email = find_email_for(assignee)
        expect(email).to have_header('X-GitLab-NotificationReason', 'assigned')

        email = find_email_for(@u_mentioned)
        expect(email).to have_header('X-GitLab-NotificationReason', 'mentioned')
      end

      it 'adds "assigned" reason for assignees if any' do
        notification.new_issue(issue, @u_disabled)

        email = find_email_for(assignee)

        expect(email).to have_header('X-GitLab-NotificationReason', 'assigned')
      end

      it "emails any mentioned users with the mention level" do
        issue.description = @u_mentioned.to_reference

        notification.new_issue(issue, @u_disabled)

        email = find_email_for(@u_mentioned)
        expect(email).not_to be_nil
        expect(email).to have_header('X-GitLab-NotificationReason', 'mentioned')
      end

      it "emails the author if they've opted into notifications about their activity" do
        issue.author.notified_of_own_activity = true

        notification.new_issue(issue, issue.author)

        should_email(issue.author)
      end

      it "doesn't email the author if they haven't opted into notifications about their activity" do
        notification.new_issue(issue, issue.author)

        should_not_email(issue.author)
      end

      it "emails subscribers of the issue's labels" do
        user_1 = create(:user)
        user_2 = create(:user)
        user_3 = create(:user)
        user_4 = create(:user)
        label = create(:label, project: project, issues: [issue])
        group_label = create(:group_label, group: group, issues: [issue])
        issue.reload
        label.toggle_subscription(user_1, project)
        group_label.toggle_subscription(user_2, project)
        group_label.toggle_subscription(user_3, another_project)
        group_label.toggle_subscription(user_4)

        notification.new_issue(issue, @u_disabled)

        should_email(user_1)
        should_email(user_2)
        should_not_email(user_3)
        should_email(user_4)
      end

      it 'adds "subscribed" reason to subscriber emails' do
        user_1 = create(:user)
        label = create(:label, project: project, issues: [issue])
        issue.reload
        label.subscribe(user_1)

        notification.new_issue(issue, @u_disabled)

        email = find_email_for(user_1)
        expect(email).to have_header('X-GitLab-NotificationReason', NotificationReason::SUBSCRIBED)
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { issue }
        let(:notification_trigger) { notification.new_issue(issue, @u_disabled) }
      end

      context 'confidential issues' do
        let(:author) { create(:user) }
        let(:non_member) { create(:user) }
        let(:member) { create(:user) }
        let(:guest) { create(:user) }
        let(:admin) { create(:admin) }
        let(:confidential_issue) { create(:issue, :confidential, project: project, title: 'Confidential issue', author: author, assignees: [assignee]) }

        it "emails subscribers of the issue's labels that can read the issue" do
          project.add_developer(member)
          project.add_guest(guest)

          label = create(:label, project: project, issues: [confidential_issue])
          confidential_issue.reload
          label.toggle_subscription(non_member, project)
          label.toggle_subscription(author, project)
          label.toggle_subscription(assignee, project)
          label.toggle_subscription(member, project)
          label.toggle_subscription(guest, project)
          label.toggle_subscription(admin, project)

          reset_delivered_emails!

          notification.new_issue(confidential_issue, @u_disabled)

          should_not_email(@u_guest_watcher)
          should_not_email(non_member)
          should_not_email(author)
          should_not_email(guest)
          should_email(assignee)
          should_email(member)
          should_email(admin)
        end
      end

      context 'when the author is not allowed to trigger notifications' do
        let(:current_user) { nil }
        let(:object) { issue }
        let(:action) { notification.new_issue(issue, current_user) }

        context 'because they are blocked' do
          let(:current_user) { create(:user, :blocked) }

          include_examples 'is not able to send notifications'
        end

        context 'because they are a ghost' do
          let(:current_user) { create(:user, :ghost) }

          include_examples 'is not able to send notifications'
        end
      end
    end

    describe '#new_mentions_in_issue' do
      let(:notification_method) { :new_mentions_in_issue }
      let(:mentionable) { issue }
      let(:object) { mentionable }
      let(:action) { send_notifications(@u_mentioned, current_user: current_user) }

      include_examples 'notifications for new mentions'

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { issue }
        let(:notification_trigger) { send_notifications(@u_watcher, @u_participant_mentioned, @u_custom_global, @u_mentioned) }
      end

      context 'where current_user is blocked' do
        let(:current_user) { create(:user, :blocked) }

        include_examples 'is not able to send notifications'
      end

      context 'where current_user is a ghost' do
        let(:current_user) { create(:user, :ghost) }

        include_examples 'is not able to send notifications'
      end
    end

    describe '#reassigned_issue' do
      before do
        update_custom_notification(:reassign_issue, @u_guest_custom, resource: project)
        update_custom_notification(:reassign_issue, @u_custom_global)
      end

      it 'emails new assignee' do
        notification.reassigned_issue(issue, @u_disabled, [assignee])

        should_email(issue.assignees.first)
        should_email(@u_watcher)
        should_email(@u_guest_watcher)
        should_email(@u_guest_custom)
        should_email(@u_custom_global)
        should_email(@u_participant_mentioned)
        should_email(@subscriber)
        should_not_email(@unsubscriber)
        should_not_email(@u_participating)
        should_not_email(@u_disabled)
        should_not_email(@u_lazy_participant)
      end

      it 'adds "assigned" reason for new assignee' do
        notification.reassigned_issue(issue, @u_disabled, [assignee])

        email = find_email_for(assignee)

        expect(email).to have_header('X-GitLab-NotificationReason', NotificationReason::ASSIGNED)
      end

      it 'emails previous assignee even if they have the "on mention" notif level' do
        issue.assignees = [@u_mentioned]
        notification.reassigned_issue(issue, @u_disabled, [@u_watcher])

        should_email(@u_mentioned)
        should_email(@u_watcher)
        should_email(@u_guest_watcher)
        should_email(@u_guest_custom)
        should_email(@u_participant_mentioned)
        should_email(@subscriber)
        should_email(@u_custom_global)
        should_not_email(@unsubscriber)
        should_not_email(@u_participating)
        should_not_email(@u_disabled)
        should_not_email(@u_lazy_participant)
      end

      it 'emails new assignee even if they have the "on mention" notif level' do
        issue.assignees = [@u_mentioned]
        notification.reassigned_issue(issue, @u_disabled, [@u_mentioned])

        expect(issue.assignees.first).to be @u_mentioned
        should_email(issue.assignees.first)
        should_email(@u_watcher)
        should_email(@u_guest_watcher)
        should_email(@u_guest_custom)
        should_email(@u_participant_mentioned)
        should_email(@subscriber)
        should_email(@u_custom_global)
        should_not_email(@unsubscriber)
        should_not_email(@u_participating)
        should_not_email(@u_disabled)
        should_not_email(@u_lazy_participant)
      end

      it 'does not email new assignee if they are the current user' do
        issue.assignees = [@u_mentioned]
        notification.reassigned_issue(issue, @u_mentioned, [@u_mentioned])

        expect(issue.assignees.first).to be @u_mentioned
        should_email(@u_watcher)
        should_email(@u_guest_watcher)
        should_email(@u_guest_custom)
        should_email(@u_participant_mentioned)
        should_email(@subscriber)
        should_email(@u_custom_global)
        should_not_email(issue.assignees.first)
        should_not_email(@unsubscriber)
        should_not_email(@u_participating)
        should_not_email(@u_disabled)
        should_not_email(@u_lazy_participant)
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { issue }
        let(:notification_trigger) { notification.reassigned_issue(issue, @u_disabled, [assignee]) }
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { issue }
        let(:notification_trigger) { notification.reassigned_issue(issue, @u_disabled, [assignee]) }
      end
    end

    describe '#relabeled_issue' do
      let(:group_label_1) { create(:group_label, group: group, title: 'Group Label 1', issues: [issue]) }
      let(:group_label_2) { create(:group_label, group: group, title: 'Group Label 2') }
      let(:label_1) { create(:label, project: project, title: 'Label 1', issues: [issue]) }
      let(:label_2) { create(:label, project: project, title: 'Label 2') }
      let!(:subscriber_to_group_label_1) { create(:user) { |u| group_label_1.toggle_subscription(u, project) } }
      let!(:subscriber_1_to_group_label_2) { create(:user) { |u| group_label_2.toggle_subscription(u, project) } }
      let!(:subscriber_2_to_group_label_2) { create(:user) { |u| group_label_2.toggle_subscription(u) } }
      let!(:subscriber_to_group_label_2_on_another_project) { create(:user) { |u| group_label_2.toggle_subscription(u, another_project) } }
      let!(:subscriber_to_label_1) { create(:user) { |u| label_1.toggle_subscription(u, project) } }
      let!(:subscriber_to_label_2) { create(:user) { |u| label_2.toggle_subscription(u, project) } }

      it "emails the current user if they've opted into notifications about their activity" do
        subscriber_to_label_2.notified_of_own_activity = true
        notification.relabeled_issue(issue, [group_label_2, label_2], subscriber_to_label_2)

        should_email(subscriber_to_label_2)
      end

      it "doesn't email the current user if they haven't opted into notifications about their activity" do
        notification.relabeled_issue(issue, [group_label_2, label_2], subscriber_to_label_2)

        should_not_email(subscriber_to_label_2)
      end

      it "doesn't send email to anyone but subscribers of the given labels" do
        notification.relabeled_issue(issue, [group_label_2, label_2], @u_disabled)

        should_not_email(subscriber_to_label_1)
        should_not_email(subscriber_to_group_label_1)
        should_not_email(subscriber_to_group_label_2_on_another_project)
        should_email(subscriber_1_to_group_label_2)
        should_email(subscriber_2_to_group_label_2)
        should_email(subscriber_to_label_2)
        should_not_email(issue.assignees.first)
        should_not_email(issue.author)
        should_not_email(@u_watcher)
        should_not_email(@u_guest_watcher)
        should_not_email(@u_participant_mentioned)
        should_not_email(@subscriber)
        should_not_email(@watcher_and_subscriber)
        should_not_email(@unsubscriber)
        should_not_email(@u_participating)
      end

      it "doesn't send multiple email when a user is subscribed to multiple given labels" do
        subscriber_to_both = create(:user) do |user|
          [label_1, label_2].each { |label| label.toggle_subscription(user, project) }
        end

        notification.relabeled_issue(issue, [label_1, label_2], @u_disabled)

        should_email(subscriber_to_label_1)
        should_email(subscriber_to_label_2)
        should_email(subscriber_to_both)
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { issue }
        let(:notification_trigger) { notification.relabeled_issue(issue, [group_label_2, label_2], @u_disabled) }
      end

      context 'confidential issues' do
        let(:author) { create(:user) }
        let(:non_member) { create(:user) }
        let(:member) { create(:user) }
        let(:guest) { create(:user) }
        let(:admin) { create(:admin) }
        let(:confidential_issue) { create(:issue, :confidential, project: project, title: 'Confidential issue', author: author, assignees: [assignee]) }
        let!(:label_1) { create(:label, project: project, issues: [confidential_issue]) }
        let!(:label_2) { create(:label, project: project) }

        it "emails subscribers of the issue's labels that can read the issue" do
          project.add_developer(member)
          project.add_guest(guest)

          label_2.toggle_subscription(non_member, project)
          label_2.toggle_subscription(author, project)
          label_2.toggle_subscription(assignee, project)
          label_2.toggle_subscription(member, project)
          label_2.toggle_subscription(guest, project)
          label_2.toggle_subscription(admin, project)

          reset_delivered_emails!

          notification.relabeled_issue(confidential_issue, [label_2], @u_disabled)

          should_not_email(non_member)
          should_not_email(guest)
          should_email(author)
          should_email(assignee)
          should_email(member)
          should_email(admin)
        end
      end
    end

    describe '#removed_milestone_issue' do
      context do
        let(:milestone) { create(:milestone, project: project, issues: [issue]) }
        let!(:subscriber_to_new_milestone) { create(:user) { |u| issue.toggle_subscription(u, project) } }

        it_behaves_like 'altered milestone notification on issue' do
          before do
            notification.removed_milestone_issue(issue, issue.author)
          end
        end

        it_behaves_like 'project emails are disabled' do
          let(:notification_target)  { issue }
          let(:notification_trigger) { notification.removed_milestone_issue(issue, issue.author) }
        end
      end

      context 'confidential issues' do
        let(:author) { create(:user) }
        let(:non_member) { create(:user) }
        let(:member) { create(:user) }
        let(:guest) { create(:user) }
        let(:admin) { create(:admin) }
        let(:confidential_issue) { create(:issue, :confidential, project: project, title: 'Confidential issue', author: author, assignees: [assignee]) }
        let(:milestone) { create(:milestone, project: project, issues: [confidential_issue]) }

        it "emails subscribers of the issue's milestone that can read the issue" do
          project.add_developer(member)
          project.add_guest(guest)

          confidential_issue.subscribe(non_member, project)
          confidential_issue.subscribe(author, project)
          confidential_issue.subscribe(assignee, project)
          confidential_issue.subscribe(member, project)
          confidential_issue.subscribe(guest, project)
          confidential_issue.subscribe(admin, project)

          reset_delivered_emails!

          notification.removed_milestone_issue(confidential_issue, @u_disabled)

          should_not_email(non_member)
          should_not_email(guest)
          should_email(author)
          should_email(assignee)
          should_email(member)
          should_email(admin)
        end
      end
    end

    describe '#changed_milestone_issue' do
      context do
        let(:new_milestone) { create(:milestone, project: project, issues: [issue]) }
        let!(:subscriber_to_new_milestone) { create(:user) { |u| issue.toggle_subscription(u, project) } }

        it_behaves_like 'altered milestone notification on issue' do
          before do
            notification.changed_milestone_issue(issue, new_milestone, issue.author)
          end
        end

        it_behaves_like 'project emails are disabled' do
          let(:notification_target)  { issue }
          let(:notification_trigger) { notification.changed_milestone_issue(issue, new_milestone, issue.author) }
        end
      end

      context 'confidential issues' do
        let(:author) { create(:user) }
        let(:non_member) { create(:user) }
        let(:member) { create(:user) }
        let(:guest) { create(:user) }
        let(:admin) { create(:admin) }
        let(:confidential_issue) { create(:issue, :confidential, project: project, title: 'Confidential issue', author: author, assignees: [assignee]) }
        let(:new_milestone) { create(:milestone, project: project, issues: [confidential_issue]) }

        it "emails subscribers of the issue's milestone that can read the issue" do
          project.add_developer(member)
          project.add_guest(guest)

          confidential_issue.subscribe(non_member, project)
          confidential_issue.subscribe(author, project)
          confidential_issue.subscribe(assignee, project)
          confidential_issue.subscribe(member, project)
          confidential_issue.subscribe(guest, project)
          confidential_issue.subscribe(admin, project)

          reset_delivered_emails!

          notification.changed_milestone_issue(confidential_issue, new_milestone, @u_disabled)

          should_not_email(non_member)
          should_not_email(guest)
          should_email(author)
          should_email(assignee)
          should_email(member)
          should_email(admin)
        end
      end
    end

    describe '#close_issue' do
      before do
        update_custom_notification(:close_issue, @u_guest_custom, resource: project)
        update_custom_notification(:close_issue, @u_custom_global)
      end

      it 'sends email to issue assignee and issue author' do
        notification.close_issue(issue, @u_disabled)

        should_email(issue.assignees.first)
        should_email(issue.author)
        should_email(@u_watcher)
        should_email(@u_guest_watcher)
        should_email(@u_guest_custom)
        should_email(@u_custom_global)
        should_email(@u_participant_mentioned)
        should_email(@subscriber)
        should_email(@watcher_and_subscriber)
        should_not_email(@unsubscriber)
        should_not_email(@u_participating)
        should_not_email(@u_disabled)
        should_not_email(@u_lazy_participant)
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { issue }
        let(:notification_trigger) { notification.close_issue(issue, @u_disabled) }
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { issue }
        let(:notification_trigger) { notification.close_issue(issue, @u_disabled) }
      end

      it 'adds "subscribed" reason to subscriber emails' do
        user_1 = create(:user)
        issue.subscribe(user_1)
        issue.reload

        notification.close_issue(issue, @u_disabled)

        email = find_email_for(user_1)
        expect(email).to have_header('X-GitLab-NotificationReason', NotificationReason::SUBSCRIBED)
      end
    end

    describe '#reopen_issue' do
      before do
        update_custom_notification(:reopen_issue, @u_guest_custom, resource: project)
        update_custom_notification(:reopen_issue, @u_custom_global)
      end

      it 'sends email to issue notification recipients' do
        notification.reopen_issue(issue, @u_disabled)

        should_email(issue.assignees.first)
        should_email(issue.author)
        should_email(@u_watcher)
        should_email(@u_guest_watcher)
        should_email(@u_guest_custom)
        should_email(@u_custom_global)
        should_email(@u_participant_mentioned)
        should_email(@subscriber)
        should_email(@watcher_and_subscriber)
        should_not_email(@unsubscriber)
        should_not_email(@u_participating)
        should_not_email(@u_disabled)
        should_not_email(@u_lazy_participant)
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { issue }
        let(:notification_trigger) { notification.reopen_issue(issue, @u_disabled) }
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { issue }
        let(:notification_trigger) { notification.reopen_issue(issue, @u_disabled) }
      end
    end

    describe '#issue_moved' do
      let(:new_issue) { create(:issue) }

      it 'sends email to issue notification recipients' do
        notification.issue_moved(issue, new_issue, @u_disabled)

        should_email(issue.assignees.first)
        should_email(issue.author)
        should_email(@u_watcher)
        should_email(@u_guest_watcher)
        should_email(@u_participant_mentioned)
        should_email(@subscriber)
        should_email(@watcher_and_subscriber)
        should_not_email(@unsubscriber)
        should_not_email(@u_participating)
        should_not_email(@u_disabled)
        should_not_email(@u_lazy_participant)
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { issue }
        let(:notification_trigger) { notification.issue_moved(issue, new_issue, @u_disabled) }
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { issue }
        let(:notification_trigger) { notification.issue_moved(issue, new_issue, @u_disabled) }
      end
    end

    describe '#issue_cloned' do
      let(:new_issue) { create(:issue) }

      it 'sends email to issue notification recipients' do
        notification.issue_cloned(issue, new_issue, @u_disabled)

        should_email(issue.assignees.first)
        should_email(issue.author)
        should_email(@u_watcher)
        should_email(@u_guest_watcher)
        should_email(@u_participant_mentioned)
        should_email(@subscriber)
        should_email(@watcher_and_subscriber)
        should_not_email(@unsubscriber)
        should_not_email(@u_participating)
        should_not_email(@u_disabled)
        should_not_email(@u_lazy_participant)
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { issue }
        let(:notification_trigger) { notification.issue_cloned(issue, new_issue, @u_disabled) }
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { issue }
        let(:notification_trigger) { notification.issue_cloned(issue, new_issue, @u_disabled) }
      end
    end

    describe '#issue_due' do
      before do
        issue.update!(due_date: Date.today)

        update_custom_notification(:issue_due, @u_guest_custom, resource: project)
        update_custom_notification(:issue_due, @u_custom_global)
      end

      it 'sends email to issue notification recipients, excluding watchers' do
        notification.issue_due(issue)

        should_email(issue.assignees.first)
        should_email(issue.author)
        should_email(@u_guest_custom)
        should_email(@u_custom_global)
        should_email(@u_participant_mentioned)
        should_email(@subscriber)
        should_email(@watcher_and_subscriber)
        should_not_email(@u_watcher)
        should_not_email(@u_guest_watcher)
        should_not_email(@unsubscriber)
        should_not_email(@u_participating)
        should_not_email(@u_disabled)
        should_not_email(@u_lazy_participant)
      end

      it 'sends the email from the author' do
        notification.issue_due(issue)
        email = find_email_for(@subscriber)

        expect(email.header[:from].display_names).to eq(["#{issue.author.name} (@#{issue.author.username})"])
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { issue }
        let(:notification_trigger) { notification.issue_due(issue) }
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { issue }
        let(:notification_trigger) { notification.issue_due(issue) }
      end
    end
  end

  describe 'Merge Requests', :deliver_mails_inline do
    let(:another_project) { create(:project, :public, namespace: group) }
    let(:assignees) { Array.wrap(assignee) }
    let(:merge_request) { create :merge_request, author: author, source_project: project, assignees: assignees, description: 'cc @participant' }

    let_it_be_with_reload(:author) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :public, :repository, namespace: group) }

    before_all do
      build_team(project)
      add_users(project)

      project.add_maintainer(author)
      project.add_maintainer(assignee)
    end

    before do
      add_user_subscriptions(merge_request)
      update_custom_notification(:new_merge_request, @u_guest_custom, resource: project)
      update_custom_notification(:new_merge_request, @u_custom_global)
      reset_delivered_emails!
    end

    describe '#new_merge_request' do
      it do
        notification.new_merge_request(merge_request, @u_disabled)

        merge_request.assignees.each { |assignee| should_email(assignee) }
        should_email(@u_watcher)
        should_email(@watcher_and_subscriber)
        should_email(@u_participant_mentioned)
        should_email(@u_guest_watcher)
        should_email(@u_guest_custom)
        should_email(@u_custom_global)
        should_not_email(@u_participating)
        should_not_email(@u_disabled)
        should_not_email(@u_lazy_participant)
      end

      it 'adds "assigned" reason for assignee, if any' do
        notification.new_merge_request(merge_request, @u_disabled)

        merge_request.assignees.each do |assignee|
          email = find_email_for(assignee)

          expect(email).to have_header('X-GitLab-NotificationReason', NotificationReason::ASSIGNED)
        end
      end

      it "emails any mentioned users with the mention level" do
        merge_request.description = @u_mentioned.to_reference

        notification.new_merge_request(merge_request, @u_disabled)

        should_email(@u_mentioned)
      end

      it "emails the author if they've opted into notifications about their activity" do
        merge_request.author.notified_of_own_activity = true

        notification.new_merge_request(merge_request, merge_request.author)

        should_email(merge_request.author)

        email = find_email_for(merge_request.author)
        expect(email).to have_header('X-GitLab-NotificationReason', NotificationReason::OWN_ACTIVITY)
      end

      it "doesn't email the author if they haven't opted into notifications about their activity" do
        notification.new_merge_request(merge_request, merge_request.author)

        should_not_email(merge_request.author)
      end

      it "emails subscribers of the merge request's labels" do
        user_1 = create(:user)
        user_2 = create(:user)
        user_3 = create(:user)
        user_4 = create(:user)
        label = create(:label, project: project, merge_requests: [merge_request])
        group_label = create(:group_label, group: group, merge_requests: [merge_request])
        label.toggle_subscription(user_1, project)
        group_label.toggle_subscription(user_2, project)
        group_label.toggle_subscription(user_3, another_project)
        group_label.toggle_subscription(user_4)

        notification.new_merge_request(merge_request, @u_disabled)

        should_email(user_1)
        should_email(user_2)
        should_not_email(user_3)
        should_email(user_4)
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.new_merge_request(merge_request, @u_disabled) }
      end

      context 'participating' do
        it_behaves_like 'participating by assignee notification' do
          let(:participant) { create(:user, username: 'user-participant')}
          let(:issuable) { merge_request }
          let(:notification_trigger) { notification.new_merge_request(merge_request, @u_disabled) }
        end

        it_behaves_like 'participating by note notification' do
          let(:participant) { create(:user, username: 'user-participant')}
          let(:issuable) { merge_request }
          let(:notification_trigger) { notification.new_merge_request(merge_request, @u_disabled) }
        end

        context 'by author' do
          let(:participant) { create(:user, username: 'user-participant')}

          before do
            merge_request.author = participant
            merge_request.save!
            notification.new_merge_request(merge_request, @u_disabled)
          end

          it { should_not_email(participant) }
        end
      end

      context 'when the author is not allowed to trigger notifications' do
        let(:current_user) { nil }
        let(:object) { merge_request }
        let(:action) { notification.new_merge_request(merge_request, current_user) }

        context 'because they are blocked' do
          let(:current_user) { create(:user, :blocked) }

          it_behaves_like 'is not able to send notifications'
        end

        context 'because they are a ghost' do
          let(:current_user) { create(:user, :ghost) }

          it_behaves_like 'is not able to send notifications'
        end
      end
    end

    describe '#new_mentions_in_merge_request' do
      let(:notification_method) { :new_mentions_in_merge_request }
      let(:mentionable) { merge_request }
      let(:object) { mentionable }
      let(:action) { send_notifications(@u_mentioned, current_user: current_user) }

      include_examples 'notifications for new mentions'

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { send_notifications(@u_watcher, @u_participant_mentioned, @u_custom_global, @u_mentioned) }
      end

      context 'where current_user is blocked' do
        let(:current_user) { create(:user, :blocked) }

        include_examples 'is not able to send notifications'
      end

      context 'where current_user is a ghost' do
        let(:current_user) { create(:user, :ghost) }

        include_examples 'is not able to send notifications'
      end
    end

    describe '#reassigned_merge_request' do
      let(:current_user) { create(:user) }

      before do
        update_custom_notification(:reassign_merge_request, @u_guest_custom, resource: project)
        update_custom_notification(:reassign_merge_request, @u_custom_global)
      end

      it do
        notification.reassigned_merge_request(merge_request, current_user, [assignee])

        merge_request.assignees.each { |assignee| should_email(assignee) }
        should_email(merge_request.author)
        should_email(@u_watcher)
        should_email(@u_participant_mentioned)
        should_email(@subscriber)
        should_email(@watcher_and_subscriber)
        should_email(@u_guest_watcher)
        should_email(@u_guest_custom)
        should_email(@u_custom_global)
        should_not_email(@unsubscriber)
        should_not_email(@u_participating)
        should_not_email(@u_disabled)
        should_not_email(@u_lazy_participant)
      end

      it 'adds "assigned" reason for new assignee' do
        notification.reassigned_merge_request(merge_request, current_user, [assignee])

        merge_request.assignees.each do |assignee|
          email = find_email_for(assignee)

          expect(email).to have_header('X-GitLab-NotificationReason', NotificationReason::ASSIGNED)
        end
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { merge_request }
        let(:notification_trigger) { notification.reassigned_merge_request(merge_request, current_user, [assignee]) }
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.reassigned_merge_request(merge_request, current_user, [assignee]) }
      end
    end

    describe '#changed_reviewer_of_merge_request' do
      let(:merge_request) { create(:merge_request, author: author, source_project: project, reviewers: [reviewer], description: 'cc @participant') }

      let_it_be(:current_user) { create(:user) }
      let_it_be(:reviewer) { create(:user) }

      before do
        update_custom_notification(:change_reviewer_merge_request, @u_guest_custom, resource: project)
        update_custom_notification(:change_reviewer_merge_request, @u_custom_global)
      end

      it 'sends emails to relevant users only', :aggregate_failures do
        notification.changed_reviewer_of_merge_request(merge_request, current_user, [reviewer])

        merge_request.reviewers.each { |reviewer| should_email(reviewer) }
        should_email(merge_request.author)
        should_email(@u_watcher)
        should_email(@u_participant_mentioned)
        should_email(@subscriber)
        should_email(@watcher_and_subscriber)
        should_email(@u_guest_watcher)
        should_email(@u_guest_custom)
        should_email(@u_custom_global)
        should_not_email(@unsubscriber)
        should_not_email(@u_participating)
        should_not_email(@u_disabled)
        should_not_email(@u_lazy_participant)
      end

      it 'adds "review requested" reason for new reviewer' do
        notification.changed_reviewer_of_merge_request(merge_request, current_user, [reviewer])

        merge_request.reviewers.each do |assignee|
          email = find_email_for(assignee)

          expect(email).to have_header('X-GitLab-NotificationReason', NotificationReason::REVIEW_REQUESTED)
        end
      end

      context 'participating notifications with reviewers' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { merge_request }
        let(:notification_trigger) { notification.changed_reviewer_of_merge_request(merge_request, current_user, [reviewer]) }

        it_behaves_like 'participating notifications'
        it_behaves_like 'participating by reviewer notification'
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.changed_reviewer_of_merge_request(merge_request, current_user, [reviewer]) }
      end
    end

    describe '#change_in_merge_request_draft_status' do
      let(:merge_request) { create(:merge_request, author: author, source_project: project) }

      let_it_be(:current_user) { create(:user) }

      it 'sends emails to relevant users only', :aggregate_failures do
        notification.change_in_merge_request_draft_status(merge_request, current_user)

        merge_request.reviewers.each { |reviewer| should_email(reviewer) }
        merge_request.assignees.each { |assignee| should_email(assignee) }
        should_email(merge_request.author)
        should_email(@u_watcher)
        should_email(@subscriber)
        should_email(@watcher_and_subscriber)
        should_email(@u_guest_watcher)
        should_not_email(@u_participant_mentioned)
        should_not_email(@u_guest_custom)
        should_not_email(@u_custom_global)
        should_not_email(@unsubscriber)
        should_not_email(@u_participating)
        should_not_email(@u_disabled)
        should_not_email(@u_lazy_participant)
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { merge_request }
        let(:notification_trigger) { notification.change_in_merge_request_draft_status(merge_request, @u_disabled) }
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.change_in_merge_request_draft_status(merge_request, @u_disabled) }
      end
    end

    describe '#push_to_merge_request' do
      before do
        update_custom_notification(:push_to_merge_request, @u_guest_custom, resource: project)
        update_custom_notification(:push_to_merge_request, @u_custom_global)
      end

      it do
        notification.push_to_merge_request(merge_request, @u_disabled)

        merge_request.assignees.each { |assignee| should_email(assignee) }
        should_email(@u_guest_custom)
        should_email(@u_custom_global)
        should_email(@u_participant_mentioned)
        should_email(@subscriber)
        should_email(@watcher_and_subscriber)
        should_not_email(@u_watcher)
        should_not_email(@u_guest_watcher)
        should_not_email(@unsubscriber)
        should_not_email(@u_participating)
        should_not_email(@u_disabled)
        should_not_email(@u_lazy_participant)
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { merge_request }
        let(:notification_trigger) { notification.push_to_merge_request(merge_request, @u_disabled) }
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.push_to_merge_request(merge_request, @u_disabled) }
      end
    end

    describe '#relabel_merge_request' do
      let(:group_label_1) { create(:group_label, group: group, title: 'Group Label 1', merge_requests: [merge_request]) }
      let(:group_label_2) { create(:group_label, group: group, title: 'Group Label 2') }
      let(:label_1) { create(:label, project: project, title: 'Label 1', merge_requests: [merge_request]) }
      let(:label_2) { create(:label, project: project, title: 'Label 2') }
      let!(:subscriber_to_group_label_1) { create(:user) { |u| group_label_1.toggle_subscription(u, project) } }
      let!(:subscriber_1_to_group_label_2) { create(:user) { |u| group_label_2.toggle_subscription(u, project) } }
      let!(:subscriber_2_to_group_label_2) { create(:user) { |u| group_label_2.toggle_subscription(u) } }
      let!(:subscriber_to_group_label_2_on_another_project) { create(:user) { |u| group_label_2.toggle_subscription(u, another_project) } }
      let!(:subscriber_to_label_1) { create(:user) { |u| label_1.toggle_subscription(u, project) } }
      let!(:subscriber_to_label_2) { create(:user) { |u| label_2.toggle_subscription(u, project) } }

      it "doesn't send email to anyone but subscribers of the given labels" do
        notification.relabeled_merge_request(merge_request, [group_label_2, label_2], @u_disabled)

        should_not_email(subscriber_to_label_1)
        should_not_email(subscriber_to_group_label_1)
        should_not_email(subscriber_to_group_label_2_on_another_project)
        should_email(subscriber_1_to_group_label_2)
        should_email(subscriber_2_to_group_label_2)
        should_email(subscriber_to_label_2)
        merge_request.assignees.each { |assignee| should_not_email(assignee) }
        should_not_email(merge_request.author)
        should_not_email(@u_watcher)
        should_not_email(@u_participant_mentioned)
        should_not_email(@subscriber)
        should_not_email(@watcher_and_subscriber)
        should_not_email(@unsubscriber)
        should_not_email(@u_participating)
        should_not_email(@u_lazy_participant)
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.relabeled_merge_request(merge_request, [group_label_2, label_2], @u_disabled) }
      end
    end

    describe '#removed_milestone_merge_request' do
      let(:milestone) { create(:milestone, project: project, merge_requests: [merge_request]) }
      let!(:subscriber_to_new_milestone) { create(:user) { |u| merge_request.toggle_subscription(u, project) } }

      it_behaves_like 'altered milestone notification on merge request' do
        before do
          notification.removed_milestone_merge_request(merge_request, merge_request.author)
        end
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.removed_milestone_merge_request(merge_request, merge_request.author) }
      end
    end

    describe '#changed_milestone_merge_request' do
      let(:new_milestone) { create(:milestone, project: project, merge_requests: [merge_request]) }
      let!(:subscriber_to_new_milestone) { create(:user) { |u| merge_request.toggle_subscription(u, project) } }

      it_behaves_like 'altered milestone notification on merge request' do
        before do
          notification.changed_milestone_merge_request(merge_request, new_milestone, merge_request.author)
        end
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.changed_milestone_merge_request(merge_request, new_milestone, merge_request.author) }
      end
    end

    describe '#merge_request_unmergeable' do
      it "sends email to merge request author" do
        notification.merge_request_unmergeable(merge_request)

        should_email(merge_request.author)
        expect(email_recipients.size).to eq(1)
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.merge_request_unmergeable(merge_request) }
      end

      describe 'when merge_when_pipeline_succeeds is true' do
        before do
          merge_request.update!(
            merge_when_pipeline_succeeds: true,
            merge_user: create(:user)
          )
        end

        it "sends email to merge request author and merge_user" do
          notification.merge_request_unmergeable(merge_request)

          should_email(merge_request.author)
          should_email(merge_request.merge_user)
          expect(email_recipients.size).to eq(2)
        end
      end
    end

    describe '#closed_merge_request' do
      before do
        update_custom_notification(:close_merge_request, @u_guest_custom, resource: project)
        update_custom_notification(:close_merge_request, @u_custom_global)
      end

      it do
        notification.close_mr(merge_request, @u_disabled)

        merge_request.assignees.each { |assignee| should_email(assignee) }
        should_email(@u_watcher)
        should_email(@u_guest_watcher)
        should_email(@u_guest_custom)
        should_email(@u_custom_global)
        should_email(@u_participant_mentioned)
        should_email(@subscriber)
        should_email(@watcher_and_subscriber)
        should_not_email(@unsubscriber)
        should_not_email(@u_participating)
        should_not_email(@u_disabled)
        should_not_email(@u_lazy_participant)
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { merge_request }
        let(:notification_trigger) { notification.close_mr(merge_request, @u_disabled) }
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.close_mr(merge_request, @u_disabled) }
      end
    end

    describe '#merged_merge_request' do
      before do
        update_custom_notification(:merge_merge_request, @u_guest_custom, resource: project)
        update_custom_notification(:merge_merge_request, @u_custom_global)
      end

      it do
        notification.merge_mr(merge_request, @u_disabled)

        merge_request.assignees.each { |assignee| should_email(assignee) }
        should_email(@u_watcher)
        should_email(@u_guest_watcher)
        should_email(@u_guest_custom)
        should_email(@u_custom_global)
        should_email(@u_participant_mentioned)
        should_email(@subscriber)
        should_email(@watcher_and_subscriber)
        should_not_email(@unsubscriber)
        should_not_email(@u_participating)
        should_not_email(@u_disabled)
        should_not_email(@u_lazy_participant)
      end

      it "notifies the merger when the pipeline succeeds is true" do
        merge_request.merge_when_pipeline_succeeds = true
        notification.merge_mr(merge_request, @u_watcher)

        should_email(@u_watcher)
      end

      it "does not notify the merger when the pipeline succeeds is false" do
        merge_request.merge_when_pipeline_succeeds = false
        notification.merge_mr(merge_request, @u_watcher)

        should_not_email(@u_watcher)
      end

      it "notifies the merger when the pipeline succeeds is false but they've opted into notifications about their activity" do
        merge_request.merge_when_pipeline_succeeds = false
        @u_watcher.notified_of_own_activity = true
        notification.merge_mr(merge_request, @u_watcher)

        should_email(@u_watcher)
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { merge_request }
        let(:notification_trigger) { notification.merge_mr(merge_request, @u_disabled) }
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.merge_mr(merge_request, @u_disabled) }
      end
    end

    describe '#reopen_merge_request' do
      before do
        update_custom_notification(:reopen_merge_request, @u_guest_custom, resource: project)
        update_custom_notification(:reopen_merge_request, @u_custom_global)
      end

      it do
        notification.reopen_mr(merge_request, @u_disabled)

        merge_request.assignees.each { |assignee| should_email(assignee) }
        should_email(@u_watcher)
        should_email(@u_participant_mentioned)
        should_email(@subscriber)
        should_email(@watcher_and_subscriber)
        should_email(@u_guest_watcher)
        should_email(@u_guest_custom)
        should_email(@u_custom_global)
        should_not_email(@unsubscriber)
        should_not_email(@u_participating)
        should_not_email(@u_disabled)
        should_not_email(@u_lazy_participant)
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { merge_request }
        let(:notification_trigger) { notification.reopen_mr(merge_request, @u_disabled) }
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.reopen_mr(merge_request, @u_disabled) }
      end
    end

    describe "#resolve_all_discussions" do
      it do
        notification.resolve_all_discussions(merge_request, @u_disabled)

        merge_request.assignees.each { |assignee| should_email(assignee) }
        should_email(@u_watcher)
        should_email(@u_participant_mentioned)
        should_email(@subscriber)
        should_email(@watcher_and_subscriber)
        should_email(@u_guest_watcher)
        should_not_email(@unsubscriber)
        should_not_email(@u_participating)
        should_not_email(@u_disabled)
        should_not_email(@u_lazy_participant)
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { merge_request }
        let(:notification_trigger) { notification.resolve_all_discussions(merge_request, @u_disabled) }
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.resolve_all_discussions(merge_request, @u_disabled) }
      end
    end

    describe '#merge_when_pipeline_succeeds' do
      before do
        update_custom_notification(:merge_when_pipeline_succeeds, @u_guest_custom, resource: project)
        update_custom_notification(:merge_when_pipeline_succeeds, @u_custom_global)
      end

      it 'send notification that merge will happen when pipeline succeeds' do
        notification.merge_when_pipeline_succeeds(merge_request, assignee)

        should_email(merge_request.author)
        should_email(@u_watcher)
        should_email(@subscriber)
        should_email(@u_guest_custom)
        should_email(@u_custom_global)
        should_not_email(@unsubscriber)
        should_not_email(@u_disabled)
      end

      it 'does not send notification if the custom event is disabled' do
        update_custom_notification(:merge_when_pipeline_succeeds, @u_guest_custom, resource: project, value: false)
        update_custom_notification(:merge_when_pipeline_succeeds, @u_custom_global, resource: nil, value: false)
        notification.merge_when_pipeline_succeeds(merge_request, assignee)

        should_not_email(@u_guest_custom)
        should_not_email(@u_custom_global)
      end

      it 'sends notification to participants even if the custom event is disabled' do
        update_custom_notification(:merge_when_pipeline_succeeds, merge_request.author, resource: project, value: false)
        update_custom_notification(:merge_when_pipeline_succeeds, @u_watcher, resource: project, value: false)
        update_custom_notification(:merge_when_pipeline_succeeds, @subscriber, resource: project, value: false)
        notification.merge_when_pipeline_succeeds(merge_request, assignee)

        should_email(merge_request.author)
        should_email(@u_watcher)
        should_email(@subscriber)
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { merge_request }
        let(:notification_trigger) { notification.merge_when_pipeline_succeeds(merge_request, @u_disabled) }
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.merge_when_pipeline_succeeds(merge_request, @u_disabled) }
      end
    end

    describe '#review_requested_of_merge_request' do
      let(:merge_request) { create(:merge_request, author: author, source_project: project, reviewers: [reviewer]) }

      let_it_be(:current_user) { create(:user) }
      let_it_be(:reviewer) { create(:user) }

      it 'sends email to reviewer', :aggregate_failures do
        notification.review_requested_of_merge_request(merge_request, current_user, reviewer)

        merge_request.reviewers.each { |reviewer| should_email(reviewer) }
        should_not_email(merge_request.author)
        should_not_email(@u_watcher)
        should_not_email(@u_participant_mentioned)
        should_not_email(@subscriber)
        should_not_email(@watcher_and_subscriber)
        should_not_email(@u_guest_watcher)
        should_not_email(@u_guest_custom)
        should_not_email(@u_custom_global)
        should_not_email(@unsubscriber)
        should_not_email(@u_participating)
        should_not_email(@u_disabled)
        should_not_email(@u_lazy_participant)
      end

      it 'adds "review requested" reason for new reviewer' do
        notification.review_requested_of_merge_request(merge_request, current_user, [reviewer])

        merge_request.reviewers.each do |reviewer|
          email = find_email_for(reviewer)

          expect(email).to have_header('X-GitLab-NotificationReason', NotificationReason::REVIEW_REQUESTED)
        end
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.review_requested_of_merge_request(merge_request, current_user, reviewer) }
      end
    end
  end

  describe 'Projects', :deliver_mails_inline do
    before_all do
      build_team(project)
      reset_delivered_emails!
    end

    describe '#project_was_moved' do
      context 'when notifications are disabled' do
        before do
          @u_custom_global.global_notification_setting.update!(moved_project: false)
        end

        it 'does not send a notification' do
          notification.project_was_moved(project, "gitlab/gitlab")

          should_not_email(@u_custom_global)
        end
      end

      context 'with users at both project and group level' do
        let(:maintainer) { create(:user) }
        let(:developer) { create(:user) }
        let(:group_owner) { create(:user) }
        let(:group_maintainer) { create(:user) }
        let(:group_developer) { create(:user) }
        let(:blocked_user) { create(:user, :blocked) }
        let(:invited_user) { create(:user) }

        let!(:group) do
          create(:group, :public) do |group|
            project.group = group
            project.save!

            group.add_owner(group_owner)
            group.add_maintainer(group_maintainer)
            group.add_developer(group_developer)
            # This is to check for dupes
            group.add_maintainer(maintainer)
            group.add_maintainer(blocked_user)
          end
        end

        before do
          project.add_maintainer(maintainer)
          project.add_developer(developer)
          project.add_maintainer(blocked_user)
          reset_delivered_emails!
        end

        it 'notifies the expected users' do
          notification.project_was_moved(project, "gitlab/gitlab")

          should_email(@u_watcher)
          should_email(@u_participating)
          should_email(@u_lazy_participant)
          should_email(@u_custom_global)
          should_not_email(@u_guest_watcher)
          should_not_email(@u_guest_custom)
          should_not_email(@u_disabled)

          should_email(maintainer)
          should_email(group_owner)
          should_email(group_maintainer)
          should_not_email(group_developer)
          should_not_email(developer)
          should_not_email(blocked_user)
        end
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { project }
        let(:notification_trigger) { notification.project_was_moved(project, "gitlab/gitlab") }
      end

      context 'users not having access to the new location' do
        it 'does not send email' do
          old_user = create(:user)
          ProjectAuthorization.create!(project: project, user: old_user, access_level: Gitlab::Access::GUEST)

          build_group(project)
          reset_delivered_emails!

          notification.project_was_moved(project, "gitlab/gitlab")

          should_email(@g_watcher)
          should_email(@g_global_watcher)
          should_email(project.creator)
          should_not_email(old_user)
        end
      end
    end

    context 'user with notifications disabled' do
      describe '#project_exported' do
        it do
          notification.project_exported(project, @u_disabled)

          should_not_email_anyone
        end
      end

      describe '#project_not_exported' do
        it do
          notification.project_not_exported(project, @u_disabled, ['error'])

          should_not_email_anyone
        end
      end
    end

    context 'user with notifications enabled' do
      describe '#project_exported' do
        it do
          notification.project_exported(project, @u_participating)

          should_only_email(@u_participating)
        end

        it_behaves_like 'project emails are disabled' do
          let(:notification_target)  { project }
          let(:notification_trigger) { notification.project_exported(project, @u_participating) }
        end
      end

      describe '#project_not_exported' do
        it do
          notification.project_not_exported(project, @u_participating, ['error'])

          should_only_email(@u_participating)
        end

        it_behaves_like 'project emails are disabled' do
          let(:notification_target)  { project }
          let(:notification_trigger) { notification.project_not_exported(project, @u_participating, ['error']) }
        end
      end
    end
  end

  describe '#invite_member_reminder' do
    let_it_be(:group_member) { create(:group_member) }

    subject { notification.invite_member_reminder(group_member, 'token', 0) }

    it 'calls the Notify.invite_member_reminder method with the right params' do
      expect(Notify).to receive(:member_invited_reminder_email).with('Group', group_member.id, 'token', 0).at_least(:once).and_call_original

      subject
    end

    it 'sends exactly one email' do
      subject

      expect_delivery_jobs_count(1)
      expect_enqueud_email('Group', group_member.id, 'token', 0, mail: 'member_invited_reminder_email')
    end
  end

  describe '#new_instance_access_request', :deliver_mails_inline do
    let_it_be(:user) { create(:user, :blocked_pending_approval) }
    let_it_be(:admins) { create_list(:admin, 12, :with_sign_ins) }

    subject { notification.new_instance_access_request(user) }

    before do
      reset_delivered_emails!
      stub_application_setting(require_admin_approval_after_user_signup: true)
    end

    it 'sends notification only to a maximum of ten most recently active instance admins' do
      ten_most_recently_active_instance_admins = User.admins.active.sort_by(&:current_sign_in_at).last(10)

      subject

      should_only_email(*ten_most_recently_active_instance_admins)
    end
  end

  describe '#user_admin_rejection', :deliver_mails_inline do
    let_it_be(:user) { create(:user, :blocked_pending_approval) }

    before do
      reset_delivered_emails!
    end

    it 'sends the user a rejection email' do
      notification.user_admin_rejection(user.name, user.email)

      should_only_email(user)
    end
  end

  describe 'GroupMember', :deliver_mails_inline do
    let(:added_user) { create(:user) }

    describe '#new_access_request' do
      context 'recipients' do
        let(:maintainer) { create(:user) }
        let(:owner) { create(:user) }
        let(:developer) { create(:user) }

        let!(:group) do
          create(:group, :public) do |group|
            group.add_owner(owner)
            group.add_maintainer(maintainer)
            group.add_developer(developer)
          end
        end

        before do
          reset_delivered_emails!
        end

        it 'sends notification only to group owners' do
          group.request_access(added_user)

          should_email(owner)
          should_not_email(maintainer)
          should_not_email(developer)
        end

        it_behaves_like 'group emails are disabled' do
          let(:notification_target)  { group }
          let(:notification_trigger) { group.request_access(added_user) }
        end
      end

      it_behaves_like 'sends notification only to a maximum of ten, most recently active group owners' do
        let(:group) { create(:group, :public) }
        let(:notification_trigger) { group.request_access(added_user) }
      end
    end

    describe '#decline_group_invite' do
      let(:creator) { create(:user) }
      let(:group) { create(:group) }
      let(:member) { create(:user) }

      before do
        group.add_owner(creator)
        group.add_developer(member, creator)
      end

      it do
        group_member = group.members.last

        expect do
          notification.decline_group_invite(group_member)
        end.to change { ActionMailer::Base.deliveries.size }.by(1)
      end
    end

    describe '#new_group_member' do
      let(:group) { create(:group) }

      it 'sends a notification' do
        group.add_guest(added_user)
        should_only_email(added_user)
      end

      describe 'when notifications are disabled' do
        before do
          create_global_setting_for(added_user, :disabled)
        end

        it 'does not send a notification' do
          group.add_guest(added_user)
          should_not_email_anyone
        end
      end

      it_behaves_like 'group emails are disabled' do
        let(:notification_target)  { group }
        let(:notification_trigger) { group.add_guest(added_user) }
      end
    end

    describe '#updated_group_member_expiration' do
      let_it_be(:group_member) { create(:group_member) }

      it 'emails the user that their group membership expiry has changed' do
        expect_next_instance_of(NotificationService) do |notification|
          allow(notification).to receive(:updated_group_member_expiration).with(group_member)
        end

        group_member.update!(expires_at: 5.days.from_now)
      end
    end
  end

  describe 'ProjectMember', :deliver_mails_inline do
    let(:added_user) { create(:user) }

    describe '#new_access_request' do
      context 'for a project in a user namespace' do
        context 'recipients' do
          let(:developer) { create(:user) }
          let(:maintainer) { create(:user) }

          let!(:project) do
            create(:project, :public) do |project|
              project.add_developer(developer)
              project.add_maintainer(maintainer)
            end
          end

          before do
            reset_delivered_emails!
          end

          it 'sends notification only to project maintainers' do
            project.request_access(added_user)

            should_email(maintainer)
            should_not_email(developer)
          end

          it_behaves_like 'project emails are disabled' do
            let(:notification_target)  { project }
            let(:notification_trigger) { project.request_access(added_user) }
          end
        end

        it_behaves_like 'sends notification only to a maximum of ten, most recently active project maintainers' do
          let(:notification_trigger) { project.request_access(added_user) }
        end
      end

      context 'for a project in a group' do
        let(:group_owner) { create(:user) }
        let(:group) { create(:group).tap { |g| g.add_owner(group_owner) } }

        context 'when the project has no maintainers' do
          context 'when the group has at least one owner' do
            let!(:project) { create(:project, :public, namespace: group) }

            before do
              reset_delivered_emails!
            end

            context 'recipients' do
              it 'sends notifications to the group owners' do
                project.request_access(added_user)

                should_only_email(group_owner)
              end
            end

            it_behaves_like 'sends notification only to a maximum of ten, most recently active group owners' do
              let(:group) { create(:group, :public) }
              let(:notification_trigger) { project.request_access(added_user) }
            end
          end

          context 'when the group does not have any owners' do
            let(:group) { create(:group) }
            let!(:project) { create(:project, :public, namespace: group) }

            context 'recipients' do
              before do
                reset_delivered_emails!
              end

              it 'does not send any notifications' do
                project.request_access(added_user)

                should_not_email_anyone
              end
            end
          end
        end

        context 'when the project has maintainers' do
          let(:maintainer) { create(:user) }
          let(:developer) { create(:user) }

          let!(:project) do
            create(:project, :public, namespace: group) do |project|
              project.add_maintainer(maintainer)
              project.add_developer(developer)
            end
          end

          before do
            reset_delivered_emails!
          end

          context 'recipients' do
            it 'sends notifications only to project maintainers' do
              project.request_access(added_user)

              should_email(maintainer)
              should_not_email(developer)
              should_not_email(group_owner)
            end
          end

          it_behaves_like 'sends notification only to a maximum of ten, most recently active project maintainers' do
            let(:project) { create(:project, :public, namespace: group) }
            let(:notification_trigger) { project.request_access(added_user) }
          end
        end
      end
    end

    describe '#decline_project_invite' do
      let(:member) { create(:user) }

      before do
        project.add_developer(member, current_user: project.owner)
      end

      it do
        project_member = project.members.last

        expect do
          notification.decline_project_invite(project_member)
        end.to change { ActionMailer::Base.deliveries.size }.by(1)
      end
    end

    describe '#new_project_member' do
      it do
        create_member!
        should_only_email(added_user)
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { project }
        let(:notification_trigger) { create_member! }
      end

      context 'when notifications are disabled' do
        before do
          create_global_setting_for(added_user, :disabled)
        end

        it do
          create_member!
          should_not_email_anyone
        end
      end
    end

    def create_member!
      create(:project_member, user: added_user, project: project)
    end
  end

  context 'guest user in private project', :deliver_mails_inline do
    let(:private_project) { create(:project, :private) }
    let(:guest) { create(:user) }
    let(:developer) { create(:user) }
    let(:merge_request) { create(:merge_request, source_project: private_project, assignees: [assignee]) }
    let(:merge_request1) { create(:merge_request, source_project: private_project, assignees: [assignee], description: "cc @#{guest.username}") }
    let(:note) { create(:note, noteable: merge_request, project: private_project) }

    before do
      private_project.add_developer(assignee)
      private_project.add_developer(developer)
      private_project.add_guest(guest)

      ActionMailer::Base.deliveries.clear
    end

    it 'filters out guests when new note is created' do
      expect(SentNotification).to receive(:record).with(merge_request, any_args).once

      notification.new_note(note)

      should_not_email(guest)
      should_email(assignee)
    end

    it 'filters out guests when new merge request is created' do
      notification.new_merge_request(merge_request1, developer)

      should_not_email(guest)
      should_email(assignee)
    end

    it 'filters out guests when merge request is closed' do
      notification.close_mr(merge_request, developer)

      should_not_email(guest)
      should_email(assignee)
    end

    it 'filters out guests when merge request is reopened' do
      notification.reopen_mr(merge_request, developer)

      should_not_email(guest)
      should_email(assignee)
    end

    it 'filters out guests when merge request is merged' do
      notification.merge_mr(merge_request, developer)

      should_not_email(guest)
      should_email(assignee)
    end
  end

  describe 'Pipelines', :deliver_mails_inline do
    describe '#pipeline_finished' do
      let_it_be(:project) { create(:project, :public, :repository) }
      let_it_be(:u_member) { create(:user) }
      let_it_be(:u_watcher) { create_user_with_notification(:watch, 'watcher') }

      let_it_be(:u_custom_notification_unset) do
        create_user_with_notification(:custom, 'custom_unset')
      end

      let_it_be(:u_custom_notification_enabled) do
        user = create_user_with_notification(:custom, 'custom_enabled')
        update_custom_notification(:success_pipeline, user, resource: project)
        update_custom_notification(:failed_pipeline, user, resource: project)
        update_custom_notification(:fixed_pipeline, user, resource: project)
        user
      end

      let_it_be(:u_custom_notification_disabled) do
        user = create_user_with_notification(:custom, 'custom_disabled')
        update_custom_notification(:success_pipeline, user, resource: project, value: false)
        update_custom_notification(:failed_pipeline, user, resource: project, value: false)
        update_custom_notification(:fixed_pipeline, user, resource: project, value: false)
        user
      end

      let(:commit) { project.commit }

      def create_pipeline(user, status)
        create(:ci_pipeline, status,
               project: project,
               user: user,
               ref: 'refs/heads/master',
               sha: commit.id,
               before_sha: '00000000')
      end

      before_all do
        project.add_maintainer(u_member)
        project.add_maintainer(u_watcher)
        project.add_maintainer(u_custom_notification_unset)
        project.add_maintainer(u_custom_notification_enabled)
        project.add_maintainer(u_custom_notification_disabled)
      end

      before do
        reset_delivered_emails!
      end

      context 'with a successful pipeline' do
        context 'when the creator has default settings' do
          before do
            pipeline = create_pipeline(u_member, :success)
            notification.pipeline_finished(pipeline)
          end

          it 'notifies nobody' do
            should_not_email_anyone
          end
        end

        context 'when the creator has watch set' do
          before do
            pipeline = create_pipeline(u_watcher, :success)
            notification.pipeline_finished(pipeline)
          end

          it 'notifies nobody' do
            should_not_email_anyone
          end
        end

        context 'when the creator has custom notifications, but without any set' do
          before do
            pipeline = create_pipeline(u_custom_notification_unset, :success)
            notification.pipeline_finished(pipeline)
          end

          it 'notifies nobody' do
            should_not_email_anyone
          end
        end

        context 'when the creator has custom notifications disabled' do
          before do
            pipeline = create_pipeline(u_custom_notification_disabled, :success)
            notification.pipeline_finished(pipeline)
          end

          it 'notifies nobody' do
            should_not_email_anyone
          end
        end

        context 'when the creator has custom notifications enabled' do
          let(:pipeline) { create_pipeline(u_custom_notification_enabled, :success) }

          it 'emails only the creator' do
            notification.pipeline_finished(pipeline)

            should_only_email(u_custom_notification_enabled, kind: :bcc)
          end

          it_behaves_like 'project emails are disabled' do
            let(:notification_target)  { pipeline }
            let(:notification_trigger) { notification.pipeline_finished(pipeline) }
          end

          context 'when the creator has group notification email set' do
            let(:group_notification_email) { 'user+group@example.com' }

            before do
              group = create(:group)

              project.update!(group: group)

              create(:email, :confirmed, user: u_custom_notification_enabled, email: group_notification_email)
              create(:notification_setting, user: u_custom_notification_enabled, source: group, notification_email: group_notification_email)
            end

            it 'sends to group notification email' do
              notification.pipeline_finished(pipeline)

              expect(email_recipients(kind: :bcc).first).to eq(group_notification_email)
            end
          end
        end
      end

      context 'with a failed pipeline' do
        context 'when the creator has no custom notification set' do
          let(:pipeline) { create_pipeline(u_member, :failed) }

          it 'emails only the creator' do
            notification.pipeline_finished(pipeline)

            should_only_email(u_member, kind: :bcc)
          end

          it_behaves_like 'project emails are disabled' do
            let(:notification_target)  { pipeline }
            let(:notification_trigger) { notification.pipeline_finished(pipeline) }
          end

          context 'when the creator has group notification email set' do
            let(:group_notification_email) { 'user+group@example.com' }

            before do
              group = create(:group)

              project.update!(group: group)
              create(:email, :confirmed, user: u_member, email: group_notification_email)
              create(:notification_setting, user: u_member, source: group, notification_email: group_notification_email)
            end

            it 'sends to group notification email' do
              notification.pipeline_finished(pipeline)

              expect(email_recipients(kind: :bcc).first).to eq(group_notification_email)
            end
          end
        end

        context 'when the creator has watch set' do
          before do
            pipeline = create_pipeline(u_watcher, :failed)
            notification.pipeline_finished(pipeline)
          end

          it 'emails only the creator' do
            should_only_email(u_watcher, kind: :bcc)
          end
        end

        context 'when the creator has custom notifications, but without any set' do
          before do
            pipeline = create_pipeline(u_custom_notification_unset, :failed)
            notification.pipeline_finished(pipeline)
          end

          it 'emails only the creator' do
            should_only_email(u_custom_notification_unset, kind: :bcc)
          end
        end

        context 'when the creator has custom notifications disabled' do
          before do
            pipeline = create_pipeline(u_custom_notification_disabled, :failed)
            notification.pipeline_finished(pipeline)
          end

          it 'notifies nobody' do
            should_not_email_anyone
          end
        end

        context 'when the creator has custom notifications set' do
          before do
            pipeline = create_pipeline(u_custom_notification_enabled, :failed)
            notification.pipeline_finished(pipeline)
          end

          it 'emails only the creator' do
            should_only_email(u_custom_notification_enabled, kind: :bcc)
          end
        end

        context 'when the creator has no read_build access' do
          before do
            pipeline = create_pipeline(u_member, :failed)
            project.update!(public_builds: false)
            project.team.truncate
            notification.pipeline_finished(pipeline)
          end

          it 'does not send emails' do
            should_not_email_anyone
          end
        end
      end

      context 'with a fixed pipeline' do
        let(:ref_status) { 'fixed' }

        context 'when the creator has no custom notification set' do
          let(:pipeline) { create_pipeline(u_member, :success) }

          it 'emails only the creator' do
            notification.pipeline_finished(pipeline, ref_status: ref_status)

            should_only_email(u_member, kind: :bcc)
          end

          it_behaves_like 'project emails are disabled' do
            let(:notification_target)  { pipeline }
            let(:notification_trigger) { notification.pipeline_finished(pipeline, ref_status: ref_status) }
          end

          context 'when the creator has group notification email set' do
            let(:group_notification_email) { 'user+group@example.com' }

            before do
              group = create(:group)

              project.update!(group: group)
              create(:email, :confirmed, user: u_member, email: group_notification_email)
              create(:notification_setting, user: u_member, source: group, notification_email: group_notification_email)
            end

            it 'sends to group notification email' do
              notification.pipeline_finished(pipeline, ref_status: ref_status)

              expect(email_recipients(kind: :bcc).first).to eq(group_notification_email)
            end
          end
        end

        context 'when the creator has watch set' do
          before do
            pipeline = create_pipeline(u_watcher, :success)
            notification.pipeline_finished(pipeline, ref_status: ref_status)
          end

          it 'emails only the creator' do
            should_only_email(u_watcher, kind: :bcc)
          end
        end

        context 'when the creator has custom notifications, but without any set' do
          before do
            pipeline = create_pipeline(u_custom_notification_unset, :success)
            notification.pipeline_finished(pipeline, ref_status: ref_status)
          end

          it 'emails only the creator' do
            should_only_email(u_custom_notification_unset, kind: :bcc)
          end
        end

        context 'when the creator has custom notifications disabled' do
          before do
            pipeline = create_pipeline(u_custom_notification_disabled, :success)
            notification.pipeline_finished(pipeline, ref_status: ref_status)
          end

          it 'notifies nobody' do
            should_not_email_anyone
          end
        end

        context 'when the creator has custom notifications set' do
          it 'emails only the creator' do
            pipeline = create_pipeline(u_custom_notification_enabled, :success)

            notification.pipeline_finished(pipeline, ref_status: ref_status)

            should_only_email(u_custom_notification_enabled, kind: :bcc)
          end
        end
      end
    end
  end

  describe 'Pages domains', :deliver_mails_inline do
    let_it_be(:project, reload: true) { create(:project) }
    let_it_be(:domain, reload: true) { create(:pages_domain, project: project) }
    let_it_be(:u_blocked) { create(:user, :blocked) }
    let_it_be(:u_silence) { create_user_with_notification(:disabled, 'silent', project) }
    let_it_be(:u_owner) { project.owner }
    let_it_be(:u_maintainer1) { create(:user) }
    let_it_be(:u_maintainer2) { create(:user) }
    let_it_be(:u_developer) { create(:user) }

    before do
      project.add_maintainer(u_blocked)
      project.add_maintainer(u_silence)
      project.add_maintainer(u_maintainer1)
      project.add_maintainer(u_maintainer2)
      project.add_developer(u_developer)

      reset_delivered_emails!
    end

    %i[
      pages_domain_enabled
      pages_domain_disabled
      pages_domain_verification_succeeded
      pages_domain_verification_failed
      pages_domain_auto_ssl_failed
    ].each do |sym|
      describe "##{sym}" do
        subject(:notify!) { notification.send(sym, domain) }

        it 'emails current watching maintainers' do
          expect(Notify).to receive(:"#{sym}_email").at_least(:once).and_call_original

          notify!

          should_only_email(u_maintainer1, u_maintainer2, u_owner)
        end

        it_behaves_like 'project emails are disabled' do
          let(:notification_target)  { domain }
          let(:notification_trigger) { notify! }
        end

        it 'emails nobody if the project is missing' do
          domain.project = nil

          notify!

          should_not_email_anyone
        end
      end
    end
  end

  context 'Auto DevOps notifications', :deliver_mails_inline do
    describe '#autodevops_disabled' do
      let(:owner) { create(:user) }
      let(:namespace) { create(:namespace, owner: owner) }
      let(:project) { create(:project, :repository, :auto_devops, namespace: namespace) }
      let(:pipeline_user) { create(:user) }
      let(:pipeline) { create(:ci_pipeline, :failed, project: project, user: pipeline_user) }

      it 'emails project owner and user that triggered the pipeline' do
        project.add_developer(pipeline_user)

        notification.autodevops_disabled(pipeline, [owner.email, pipeline_user.email])

        should_email(owner, times: 1)         # Once for the disable pipeline.
        should_email(pipeline_user, times: 2) # Once for the new permission, once for the disable.
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { project }
        let(:notification_trigger) { notification.autodevops_disabled(pipeline, [owner.email, pipeline_user.email]) }
      end
    end
  end

  describe 'Repository cleanup', :deliver_mails_inline do
    let(:user) { create(:user) }

    describe '#repository_cleanup_success' do
      it 'emails the specified user only' do
        notification.repository_cleanup_success(project, user)

        should_email(user)
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { project }
        let(:notification_trigger) { notification.repository_cleanup_success(project, user) }
      end
    end

    describe '#repository_cleanup_failure' do
      it 'emails the specified user only' do
        notification.repository_cleanup_failure(project, user, 'Some error')

        should_email(user)
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { project }
        let(:notification_trigger) { notification.repository_cleanup_failure(project, user, 'Some error') }
      end
    end
  end

  context 'Remote mirror notifications', :deliver_mails_inline do
    describe '#remote_mirror_update_failed' do
      let(:remote_mirror) { create(:remote_mirror, project: project) }
      let(:u_blocked) { create(:user, :blocked) }
      let(:u_silence) { create_user_with_notification(:disabled, 'silent-maintainer', project) }
      let(:u_owner)   { project.owner }
      let(:u_maintainer1) { create(:user) }
      let(:u_maintainer2) { create(:user) }
      let(:u_developer) { create(:user) }

      before do
        project.add_maintainer(u_blocked)
        project.add_maintainer(u_silence)
        project.add_maintainer(u_maintainer1)
        project.add_maintainer(u_maintainer2)
        project.add_developer(u_developer)

        # Mock remote update
        allow(project.repository).to receive(:async_remove_remote)
        allow(project.repository).to receive(:add_remote)

        reset_delivered_emails!
      end

      it 'emails current watching maintainers' do
        notification.remote_mirror_update_failed(remote_mirror)

        should_only_email(u_maintainer1, u_maintainer2, u_owner)
      end

      it_behaves_like 'project emails are disabled' do
        let(:notification_target)  { project }
        let(:notification_trigger) { notification.remote_mirror_update_failed(remote_mirror) }
      end
    end
  end

  context 'with external authorization service', :deliver_mails_inline do
    let(:issue) { create(:issue) }
    let(:project) { issue.project }
    let(:note) { create(:note, noteable: issue, project: project) }
    let(:member) { create(:user) }

    subject { NotificationService.new }

    before do
      project.add_maintainer(member)
      member.global_notification_setting.update!(level: :watch)
    end

    it 'sends email when the service is not enabled' do
      expect(Notify).to receive(:new_issue_email).at_least(:once).with(member.id, issue.id, nil).and_call_original

      subject.new_issue(issue, member)
    end

    context 'when the service is enabled' do
      before do
        enable_external_authorization_service_check
      end

      it 'does not send an email' do
        expect(Notify).not_to receive(:new_issue_email)

        subject.new_issue(issue, member)
      end

      context 'with admin user' do
        before do
          member.update!(admin: true)
        end

        context 'when admin mode is enabled', :enable_admin_mode do
          it 'still delivers email to admins' do
            expect(Notify).to receive(:new_issue_email).at_least(:once).with(member.id, issue.id, nil).and_call_original

            subject.new_issue(issue, member)
          end
        end

        context 'when admin mode is disabled' do
          it 'does not send an email' do
            expect(Notify).not_to receive(:new_issue_email)

            subject.new_issue(issue, member)
          end
        end
      end
    end
  end

  describe '#prometheus_alerts_fired' do
    let_it_be(:project) { create(:project) }
    let_it_be(:master) { create(:user) }
    let_it_be(:developer) { create(:user) }
    let_it_be(:alert) { create(:alert_management_alert, project: project) }

    before do
      project.add_maintainer(master)
    end

    it 'sends the email to owners and masters' do
      expect(Notify).to receive(:prometheus_alert_fired_email).with(project, master, alert).and_call_original
      expect(Notify).to receive(:prometheus_alert_fired_email).with(project, project.owner, alert).and_call_original
      expect(Notify).not_to receive(:prometheus_alert_fired_email).with(project, developer, alert)

      subject.prometheus_alerts_fired(project, [alert])
    end

    it_behaves_like 'project emails are disabled' do
      let(:notification_target)  { project }
      let(:notification_trigger) { subject.prometheus_alerts_fired(project, [alert]) }

      around do |example|
        perform_enqueued_jobs { example.run }
      end
    end
  end

  describe '#new_review' do
    let(:project) { create(:project, :repository) }
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let(:reviewer) { create(:user) }
    let(:merge_request) { create(:merge_request, source_project: project, assignees: [user, user2], author: create(:user)) }
    let(:review) { create(:review, merge_request: merge_request, project: project, author: reviewer) }
    let(:note) { create(:diff_note_on_merge_request, project: project, noteable: merge_request, author: reviewer, review: review) }

    before do
      build_team(review.project)
      add_users(review.project)
      add_user_subscriptions(merge_request)
      project.add_maintainer(merge_request.author)
      project.add_maintainer(reviewer)
      merge_request.assignees.each { |assignee| project.add_maintainer(assignee) }

      create(:diff_note_on_merge_request,
             project: project,
             noteable: merge_request,
             author: reviewer,
             review: review,
             note: "cc @mention")
    end

    it 'sends emails' do
      expect(Notify).not_to receive(:new_review_email).with(review.author.id, review.id)
      expect(Notify).not_to receive(:new_review_email).with(@unsubscriber.id, review.id)
      merge_request.assignee_ids.each do |assignee_id|
        expect(Notify).to receive(:new_review_email).with(assignee_id, review.id).and_call_original
      end
      expect(Notify).to receive(:new_review_email).with(merge_request.author.id, review.id).and_call_original
      expect(Notify).to receive(:new_review_email).with(@u_watcher.id, review.id).and_call_original
      expect(Notify).to receive(:new_review_email).with(@u_mentioned.id, review.id).and_call_original
      expect(Notify).to receive(:new_review_email).with(@subscriber.id, review.id).and_call_original
      expect(Notify).to receive(:new_review_email).with(@watcher_and_subscriber.id, review.id).and_call_original
      expect(Notify).to receive(:new_review_email).with(@subscribed_participant.id, review.id).and_call_original

      subject.new_review(review)
    end

    it_behaves_like 'project emails are disabled' do
      let(:notification_target)  { review }
      let(:notification_trigger) { subject.new_review(review) }

      around do |example|
        perform_enqueued_jobs { example.run }
      end
    end
  end

  def build_team(project)
    @u_watcher               = create_global_setting_for(create(:user), :watch)
    @u_participating         = create_global_setting_for(create(:user), :participating)
    @u_participant_mentioned = create_global_setting_for(create(:user, username: 'participant'), :participating)
    @u_disabled              = create_global_setting_for(create(:user), :disabled)
    @u_mentioned             = create_global_setting_for(create(:user, username: 'mention'), :mention)
    @u_committer             = create(:user, username: 'committer')
    @u_not_mentioned         = create_global_setting_for(create(:user, username: 'regular'), :participating)
    @u_outsider_mentioned    = create(:user, username: 'outsider')
    @u_custom_global         = create_global_setting_for(create(:user, username: 'custom_global'), :custom)

    # User to be participant by default
    # This user does not contain any record in notification settings table
    # It should be treated with a :participating notification_level
    @u_lazy_participant = create(:user, username: 'lazy-participant')

    @u_guest_watcher = create_user_with_notification(:watch, 'guest_watching')
    @u_guest_custom = create_user_with_notification(:custom, 'guest_custom')

    project.add_maintainer(@u_watcher)
    project.add_maintainer(@u_participating)
    project.add_maintainer(@u_participant_mentioned)
    project.add_maintainer(@u_disabled)
    project.add_maintainer(@u_mentioned)
    project.add_maintainer(@u_committer)
    project.add_maintainer(@u_not_mentioned)
    project.add_maintainer(@u_lazy_participant)
    project.add_maintainer(@u_custom_global)
  end

  # Users in the project's group but not part of project's team
  # with different notification settings
  def build_group(project, visibility: :public)
    group = create_nested_group(visibility)
    project.update!(namespace_id: group.id)

    # Group member: global=disabled, group=watch
    @g_watcher ||= create_user_with_notification(:watch, 'group_watcher', project.group)
    @g_watcher.notification_settings_for(nil).disabled!

    # Group member: global=watch, group=global
    @g_global_watcher ||= create_global_setting_for(create(:user), :watch)
    group.add_users([@g_watcher, @g_global_watcher], :maintainer)

    group
  end

  def create_nested_group(visibility)
    parent_group = create(:group, visibility)
    child_group = create(:group, visibility, parent: parent_group)

    # Parent group member: global=disabled, parent_group=watch, child_group=global
    @pg_watcher ||= create_user_with_notification(:watch, 'parent_group_watcher', parent_group)
    @pg_watcher.notification_settings_for(nil).disabled!

    # Parent group member: global=global, parent_group=disabled, child_group=global
    @pg_disabled ||= create_user_with_notification(:disabled, 'parent_group_disabled', parent_group)
    @pg_disabled.notification_settings_for(nil).global!

    # Parent group member: global=global, parent_group=mention, child_group=global
    @pg_mention ||= create_user_with_notification(:mention, 'parent_group_mention', parent_group)
    @pg_mention.notification_settings_for(nil).global!

    # Parent group member: global=global, parent_group=participating, child_group=global
    @pg_participant ||= create_user_with_notification(:participating, 'parent_group_participant', parent_group)
    @pg_mention.notification_settings_for(nil).global!

    child_group
  end

  def add_member_for_parent_group(user, project)
    project.reload

    project.group.parent.add_maintainer(user)
  end

  def should_email_nested_group_user(user, times: 1, recipients: email_recipients)
    should_email(user, times: times, recipients: recipients)
  end

  def should_not_email_nested_group_user(user, recipients: email_recipients)
    should_not_email(user, recipients: recipients)
  end

  def add_users(project)
    @subscriber = create :user
    @unsubscriber = create :user
    @unsubscribed_mentioned = create :user, username: 'unsubscribed_mentioned'
    @subscribed_participant = create_global_setting_for(create(:user, username: 'subscribed_participant'), :participating)
    @watcher_and_subscriber = create_global_setting_for(create(:user), :watch)

    project.add_maintainer(@subscribed_participant)
    project.add_maintainer(@subscriber)
    project.add_maintainer(@unsubscriber)
    project.add_maintainer(@watcher_and_subscriber)
    project.add_maintainer(@unsubscribed_mentioned)
  end

  def add_user_subscriptions(issuable)
    issuable.subscriptions.create!(user: @unsubscribed_mentioned, project: project, subscribed: false)
    issuable.subscriptions.create!(user: @subscriber, project: project, subscribed: true)
    issuable.subscriptions.create!(user: @subscribed_participant, project: project, subscribed: true)
    issuable.subscriptions.create!(user: @unsubscriber, project: project, subscribed: false)
    # Make the watcher a subscriber to detect dupes
    issuable.subscriptions.create!(user: @watcher_and_subscriber, project: project, subscribed: true)
  end
end
