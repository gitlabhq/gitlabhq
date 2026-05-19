# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers -- Tests a lot of notifications so we need to share the setup to make it more efficient
RSpec.describe NotificationService, :mailer, feature_category: :team_planning do
  include EmailSpec::Matchers
  include ExternalAuthorizationServiceHelpers
  include NotificationHelpers

  let_it_be(:parent_group, freeze: true) { create(:group, :public) }
  let_it_be(:child_group, freeze: true) { create(:group, :public, parent: parent_group) }

  let_it_be_with_refind(:project) { create(:project, :public) }
  let_it_be_with_refind(:assignee) { create(:user) }

  let_it_be(:pg_watcher, freeze: true) do
    # Parent group member: global=disabled, parent_group=watch, child_group=global
    create_user_with_notification(:watch, 'parent_group_watcher', parent_group).tap do |user|
      user.notification_settings_for(nil).disabled!
    end
  end

  let_it_be(:pg_disabled, freeze: true) do
    # Parent group member: global=global, parent_group=disabled, child_group=global
    create_user_with_notification(:disabled, 'parent_group_disabled', parent_group).tap do |user|
      user.notification_settings_for(nil).global!
    end
  end

  let_it_be(:pg_mention, freeze: true) do
    # Parent group member: global=global, parent_group=mention, child_group=global
    create_user_with_notification(:mention, 'parent_group_mention', parent_group).tap do |user|
      user.notification_settings_for(nil).global!
    end
  end

  let_it_be(:pg_participant, freeze: true) do
    # Parent group member: global=global, parent_group=participating, child_group=global
    create_user_with_notification(:participating, 'parent_group_participant', parent_group).tap do |user|
      user.notification_settings_for(nil).global!
    end
  end

  let_it_be(:g_watcher, freeze: true) do
    # Group member: global=disabled, group=watch
    create_user_with_notification(:watch, 'group_watcher', child_group).tap do |user|
      user.notification_settings_for(nil).disabled!
      child_group.add_maintainer(user)
    end
  end

  let_it_be(:g_global_watcher, freeze: true) do
    # Group member: global=watch, group=global
    create(:user).tap do |user|
      create_global_setting_for(user, :watch)
      child_group.add_maintainer(user)
    end
  end

  let_it_be(:u_watcher, freeze: true) do
    create(:user).tap { |user| create_global_setting_for(user, :watch) }
  end

  let_it_be(:u_participating, freeze: true) do
    create(:user).tap { |user| create_global_setting_for(user, :participating) }
  end

  let_it_be(:u_participant_mentioned, freeze: true) do
    create(:user, username: 'participant').tap { |user| create_global_setting_for(user, :participating) }
  end

  let_it_be(:u_disabled, freeze: true) do
    create(:user).tap { |user| create_global_setting_for(user, :disabled) }
  end

  let_it_be(:u_mentioned, freeze: true) do
    create(:user, username: 'mention').tap { |user| create_global_setting_for(user, :mention) }
  end

  let_it_be(:u_committer, freeze: true) { create(:user, username: 'committer') }

  let_it_be(:u_not_mentioned, freeze: true) do
    create(:user, username: 'regular').tap { |user| create_global_setting_for(user, :participating) }
  end

  let_it_be(:u_outsider_mentioned, freeze: true) { create(:user, username: 'outsider') }

  let_it_be(:u_custom_global, freeze: true) do
    create(:user, username: 'custom_global').tap { |user| create_global_setting_for(user, :custom) }
  end

  let_it_be(:u_lazy_participant, freeze: true) do
    # User to be participant by default
    # This user does not contain any record in notification settings table
    # It should be treated with a :participating notification_level
    create(:user, username: 'lazy-participant')
  end

  let_it_be(:u_guest_watcher, freeze: true) { create(:user, username: 'guest_watching') }
  let_it_be(:u_guest_custom, freeze: true) { create(:user, username: 'guest_custom') }

  let_it_be(:subscriber, freeze: true) { create(:user) }
  let_it_be(:unsubscriber, freeze: true) { create(:user) }
  let_it_be(:unsubscribed_mentioned, freeze: true) { create(:user, username: 'unsubscribed_mentioned') }
  let_it_be(:subscribed_participant, freeze: true) { create(:user).tap { |user| create_global_setting_for(user, :participating) } }
  let_it_be(:watcher_and_subscriber, freeze: true) { create(:user).tap { |user| create_global_setting_for(user, :watch) } }

  let_it_be(:ghost_user, freeze: true) { Users::Internal.in_organization(project.organization).ghost }
  let_it_be(:blocked_user, freeze: true) { create(:user, :blocked) }

  let(:notification) { described_class.new }

  around(:example, :deliver_mails_inline) do |example|
    # This is a temporary `around` hook until all the examples check the
    # background jobs queue instead of the delivered emails array.
    # `perform_enqueued_jobs` makes the ActiveJob jobs (e.g. mailer jobs) run inline
    # compared to `Sidekiq::Testing.inline!` which makes the Sidekiq jobs run inline.
    perform_enqueued_jobs { example.run }
  end

  shared_examples 'altered milestone notification' do
    it 'sends the email to the correct people' do
      expect do
        notification_trigger
      end.to enqueue_mail_with(Notify, mailer_method, subscriber_to_new_milestone, any_args)
        .and(enqueue_mail_with(Notify, mailer_method, notification_target.assignees.first, any_args))
        .and(enqueue_mail_with(Notify, mailer_method, u_watcher, any_args))
        .and(enqueue_mail_with(Notify, mailer_method, u_guest_watcher, any_args))
        .and(enqueue_mail_with(Notify, mailer_method, u_participant_mentioned, any_args))
        .and(enqueue_mail_with(Notify, mailer_method, subscriber, any_args))
        .and(enqueue_mail_with(Notify, mailer_method, subscribed_participant, any_args))
        .and(enqueue_mail_with(Notify, mailer_method, watcher_and_subscriber, any_args))
        .and(not_enqueue_mail_with(Notify, mailer_method, u_guest_custom, any_args))
        .and(not_enqueue_mail_with(Notify, mailer_method, u_committer, any_args))
        .and(not_enqueue_mail_with(Notify, mailer_method, unsubscriber, any_args))
        .and(not_enqueue_mail_with(Notify, mailer_method, u_participating, any_args))
        .and(not_enqueue_mail_with(Notify, mailer_method, u_lazy_participant, any_args))
        .and(not_enqueue_mail_with(Notify, mailer_method, notification_target.author, any_args))
        .and(not_enqueue_mail_with(Notify, mailer_method, u_disabled, any_args))
        .and(not_enqueue_mail_with(Notify, mailer_method, u_custom_global, any_args))
        .and(not_enqueue_mail_with(Notify, mailer_method, u_mentioned, any_args))
    end
  end

  shared_examples 'notifications for new mentions' do
    it 'sends no emails when no new mentions are present' do
      send_notifications
      should_not_email_anyone
    end

    it 'emails new mentions with a watch level higher than mention' do
      send_notifications(u_watcher, u_participant_mentioned, u_custom_global, u_mentioned)
      should_only_email(u_watcher, u_participant_mentioned, u_custom_global, u_mentioned)
    end

    it 'does not email new mentions with a watch level equal to or less than mention' do
      send_notifications(u_disabled)
      should_not_email_anyone
    end

    it 'emails new mentions despite being unsubscribed' do
      send_notifications(unsubscribed_mentioned)

      should_only_email(unsubscribed_mentioned)
    end

    it 'sends the proper notification reason header' do
      send_notifications(u_watcher)
      should_only_email(u_watcher)
      email = find_email_for(u_watcher)

      expect(email).to have_header('X-GitLab-NotificationReason', NotificationReason::MENTIONED)
    end
  end

  shared_examples 'is not able to send notifications' do |check_delivery_jobs_queue: false|
    it 'does not send any notification' do
      user_1 = create(:user)
      recipient_1 = NotificationRecipient.new(user_1, :custom, custom_action: :new_release)
      allow(NotificationRecipients::BuildService).to receive(:build_new_release_recipients).and_return([recipient_1])

      expect(Gitlab::AppLogger).to receive(:warn).with(message: 'Skipping sending notifications', user: current_user.id, klass: object.class.to_s, object_id: object.id)

      if check_delivery_jobs_queue
        expect do
          action
        end.to not_enqueue_mail_with(Notify, notification_method, u_mentioned, any_args)
          .and(not_enqueue_mail_with(Notify, notification_method, u_guest_watcher, any_args))
          .and(not_enqueue_mail_with(Notify, notification_method, user_1, any_args))
          .and(not_enqueue_mail_with(Notify, notification_method, current_user, any_args))
      else
        action

        should_not_email(u_mentioned)
        should_not_email(u_guest_watcher)
        should_not_email(user_1)
        should_not_email(current_user)
      end
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

      expect do
        notification_trigger
      end.to enqueue_mail_with(Notify, mailer_method, participant, any_args)
    end

    context 'for subgroups' do
      before do
        move_to_child_group(project)
      end

      it 'emails the participant' do
        create(:note_on_issue, noteable: issuable, project_id: project.id, note: 'anything', author: pg_participant)

        expect do
          notification_trigger
        end.to enqueue_mail_with(Notify, mailer_method, pg_participant, any_args)
      end
    end
  end

  shared_examples 'participating by confidential note notification' do
    context 'when user is mentioned on confidential note' do
      let_it_be(:guest_1) { create(:user) }
      let_it_be(:guest_2) { create(:user) }
      let_it_be(:reporter) { create(:user) }

      before do
        issuable.resource_parent.add_guest(guest_1)
        issuable.resource_parent.add_guest(guest_2)
        issuable.resource_parent.add_reporter(reporter)
      end

      it 'only emails authorized users' do
        confidential_note_text = "#{guest_1.to_reference} and #{guest_2.to_reference} and #{reporter.to_reference}"
        note_text = "Mentions #{guest_2.to_reference}"
        create(:note_on_issue, noteable: issuable, project_id: project.id, note: confidential_note_text, confidential: true)
        create(:note_on_issue, noteable: issuable, project_id: project.id, note: note_text)

        expect do
          notification_trigger
        end.to enqueue_mail_with(Notify, mailer_method, guest_2, any_args)
          .and(enqueue_mail_with(Notify, mailer_method, reporter, any_args))
          .and(not_enqueue_mail_with(Notify, mailer_method, guest_1, any_args))
      end
    end
  end

  shared_examples 'participating by assignee notification' do
    it 'emails the participant' do
      issuable.assignees << participant

      expect do
        notification_trigger
      end.to enqueue_mail_with(Notify, mailer_method, participant, any_args)
    end
  end

  shared_examples 'participating by author notification' do
    it 'emails the participant' do
      issuable.author = participant

      expect do
        notification_trigger
      end.to enqueue_mail_with(Notify, mailer_method, participant, any_args)
    end
  end

  shared_examples 'participating by reviewer notification' do
    it 'emails the participant' do
      issuable.reviewers << participant

      expect do
        notification_trigger
      end.to enqueue_mail_with(Notify, mailer_method, participant, any_args)
    end
  end

  shared_examples_for 'participating notifications' do
    it_behaves_like 'participating by note notification'
    it_behaves_like 'participating by author notification'
    it_behaves_like 'participating by assignee notification'
  end

  describe '.permitted_actions' do
    it 'includes public methods' do
      expect(described_class.permitted_actions).to include(:access_token_created)
    end

    it 'excludes EXCLUDED_ACTIONS' do
      described_class::EXCLUDED_ACTIONS.each do |action|
        expect(described_class.permitted_actions).not_to include(action)
      end
    end

    it 'excludes protected and private methods' do
      expect(described_class.permitted_actions).not_to include(:new_resource_email)
      expect(described_class.permitted_actions).not_to include(:approve_mr_email)
    end
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
        let(:key_options) { { user: ghost_user } }

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
        let(:key_options) { { user: ghost_user } }

        it "does not send email to key owner" do
          expect { subject }.not_to have_enqueued_email(key.id, mail: "new_gpg_key_email")
        end
      end
    end
  end

  describe 'AccessToken' do
    describe '#access_token_created' do
      let_it_be(:user) { create(:user) }
      let_it_be(:pat) { create(:personal_access_token, user: user) }

      subject(:notification_service) { notification.access_token_created(user, pat.name) }

      it 'sends email to the token owner' do
        expect { notification_service }.to have_enqueued_email(user, pat.name, mail: "access_token_created_email")
      end

      context 'when user is not allowed to receive notifications' do
        before do
          user.block!
        end

        it 'does not send email to the token owner' do
          expect { notification_service }.not_to have_enqueued_email(user, pat.name, mail: "access_token_created_email")
        end
      end
    end

    describe '#resource_access_token_about_to_expire' do
      let_it_be(:project_bot) { create(:user, :project_bot, username: 'project_bot') }
      let_it_be(:expiring_token) { "Expiring Token" }

      let_it_be(:owner1) { create(:user, username: 'owner1') }
      let_it_be(:owner2) { create(:user, username: 'owner2') }
      let_it_be(:maintainer) { create(:user, username: 'maintainer') }
      let_it_be(:parent_group) { create(:group) }
      let_it_be(:group) { create(:group, parent: parent_group) }

      subject(:notification_service) do
        notification.bot_resource_access_token_about_to_expire(project_bot, expiring_token)
      end

      context 'when the resource is a group' do
        before_all do
          group.add_owner(owner1)
          group.add_owner(owner2)
          group.add_reporter(project_bot)
          group.add_maintainer(maintainer)
        end

        it 'sends emails to the group owners' do
          expect { notification_service }.to(
            have_enqueued_email(
              owner1,
              project_bot.resource_bot_resource,
              expiring_token,
              {},
              mail: "bot_resource_access_token_about_to_expire_email"
            ).and(
              have_enqueued_email(
                owner2,
                project_bot.resource_bot_resource,
                expiring_token,
                {},
                mail: "bot_resource_access_token_about_to_expire_email"
              )
            )
          )
        end

        it "logs notication sent message" do
          expect(Gitlab::AppLogger).to(
            receive(:info)
              .with({ message: "Notifying resource access token owner about expiring tokens",
                      class: described_class,
                      user_id: owner1.id })
          )

          expect(Gitlab::AppLogger).to(
            receive(:info)
            .with({ message: "Notifying resource access token owner about expiring tokens",
              class: described_class,
              user_id: owner2.id })
          )

          notification_service
        end

        it 'does not send an email to group maintainer' do
          expect { notification_service }.not_to(
            have_enqueued_email(
              maintainer,
              project_bot.resource_bot_resource,
              expiring_token,
              mail: "bot_resource_access_token_about_to_expire_email"
            )
          )
        end

        context 'when group has inherited members' do
          let_it_be(:parent_owner) { create(:user) }
          let_it_be(:expiring_token_1) { "Expiring Token 1" }
          let_it_be(:expiring_token_2) { "Expirigin Token 2" }

          subject(:notification_service) do
            notification.bot_resource_access_token_about_to_expire(project_bot, [expiring_token_1, expiring_token_2])
          end

          before_all do
            parent_group.add_owner(parent_owner)
          end

          before(:context) do
            group.resource_access_token_notify_inherited = true
            group.save!
          end

          # since this setting is on namespace_settings, it doesn't get automatically rolled back correctly
          after(:context) do
            group.resource_access_token_notify_inherited = nil
            group.save!
          end

          it 'sends email to inherited members' do
            expect { notification_service }.to(
              have_enqueued_email(
                owner1,
                project_bot.resource_bot_resource,
                [expiring_token_1, expiring_token_2],
                {},
                mail: "bot_resource_access_token_about_to_expire_email"
              ).and(
                have_enqueued_email(
                  parent_owner,
                  project_bot.resource_bot_resource,
                  [expiring_token_1, expiring_token_2],
                  {},
                  mail: "bot_resource_access_token_about_to_expire_email"
                )
              )
            )
          end

          context 'when multiple memberships exist for the same user' do
            before do
              parent_group.add_owner(owner1)

              # GroupFinder by default uses DISTINCT ON (user_id, invite_email), so the duplicate memberships
              # must have differences in these columns to produce duplicate emails
              member = Member.find_by(source: parent_group, user: owner1)
              member.update!(invite_email: owner1.email)
            end

            it 'does not send duplicate emails to owner1' do
              expect { notification_service }.to(
                have_enqueued_email(
                  owner1,
                  project_bot.resource_bot_resource,
                  [expiring_token_1, expiring_token_2],
                  {},
                  mail: "bot_resource_access_token_about_to_expire_email"
                ).once
              )
            end
          end

          shared_examples 'does not email inherited members' do
            it 'sends email to direct members' do
              expect { notification_service }.to(
                have_enqueued_email(
                  owner1,
                  project_bot.resource_bot_resource,
                  [expiring_token_1, expiring_token_2],
                  {},
                  mail: "bot_resource_access_token_about_to_expire_email"
                ).and(
                  have_enqueued_email(
                    owner2,
                    project_bot.resource_bot_resource,
                    [expiring_token_1, expiring_token_2],
                    {},
                    mail: "bot_resource_access_token_about_to_expire_email"
                  )
                )
              )
            end

            it 'does not send email to inherited members' do
              expect { notification_service }.not_to(
                have_enqueued_email(
                  parent_owner,
                  project_bot.resource_bot_resource,
                  [expiring_token_1, expiring_token_2],
                  {},
                  mail: "bot_resource_access_token_about_to_expire_email"
                )
              )
            end
          end

          context 'when instance setting resource_access_token_notify_inherited is enforced' do
            before do
              stub_application_setting(
                resource_access_token_notify_inherited: false,
                lock_resource_access_token_notify_inherited: true
              )
            end

            it_behaves_like 'does not email inherited members'
          end

          context 'when group setting resource_access_token_notify_inherited is false' do
            before(:context) do
              group.resource_access_token_notify_inherited = false
              group.save!
            end

            # since this setting is on namespace_settings, it doesn't get automatically rolled back correctly
            after(:context) do
              group.resource_access_token_notify_inherited = nil
              group.save!
            end

            it_behaves_like 'does not email inherited members'
          end

          context 'when parent group setting resource_access_token_notify_inherited is false' do
            before(:context) do
              parent_group.resource_access_token_notify_inherited = false
              parent_group.save!
            end

            # since this setting is on namespace_settings, it doesn't get automatically rolled back correctly
            after(:context) do
              parent_group.resource_access_token_notify_inherited = nil
              parent_group.save!
            end

            it_behaves_like 'does not email inherited members'
          end
        end
      end

      context 'when the resource is a project' do
        let_it_be(:namespace) { create(:namespace, :with_namespace_settings) }
        let_it_be(:project) { create(:project, namespace: namespace) }

        before_all do
          project.add_maintainer(maintainer)
          project.add_reporter(project_bot)
        end

        it 'sends emails to the project maintainers and owners' do
          expect(project.owner).to be_a(User)

          expect { notification_service }.to(
            have_enqueued_email(
              maintainer,
              project_bot.resource_bot_resource,
              expiring_token,
              {},
              mail: "bot_resource_access_token_about_to_expire_email"
            ).and(
              have_enqueued_email(
                project.owner,
                project_bot.resource_bot_resource,
                expiring_token,
                {},
                mail: "bot_resource_access_token_about_to_expire_email"
              )
            )
          )
        end

        context 'when project has inherited members' do
          before_all do
            project.namespace = group
            project.save!
            group.add_owner(owner1)
            project.add_owner(owner2)
          end

          before(:context) do
            group.resource_access_token_notify_inherited = true
            group.save!
          end

          # since this setting is on namespace_settings, it doesn't get automatically rolled back correctly
          after(:context) do
            group.resource_access_token_notify_inherited = nil
            group.save!
          end

          it 'sends email to inherited members' do
            expect { notification_service }.to(
              have_enqueued_email(
                maintainer,
                project_bot.resource_bot_resource,
                expiring_token,
                {},
                mail: "bot_resource_access_token_about_to_expire_email"
              ).and(
                have_enqueued_email(
                  owner1,
                  project_bot.resource_bot_resource,
                  expiring_token,
                  {},
                  mail: "bot_resource_access_token_about_to_expire_email"
                )
              )
            )
          end

          context 'when multiple memberships exist for the same user' do
            before do
              parent_group.add_owner(owner1)

              # MembersFinder by defaul tuses DISTINCT ON (user_id, invite_email), so the duplicate memberships
              # must have differences in these columns to produce duplicate emails
              member = Member.find_by(source: parent_group, user: owner1)
              member.update!(invite_email: owner1.email)
            end

            it 'does not send duplicate emails to owner1' do
              expect { notification_service }.to(
                have_enqueued_email(
                  owner1,
                  project_bot.resource_bot_resource,
                  expiring_token,
                  {},
                  mail: "bot_resource_access_token_about_to_expire_email"
                ).once
              )
            end
          end

          shared_examples 'does not email inherited members' do
            it 'sends email to direct members' do
              expect { notification_service }.to(
                have_enqueued_email(
                  maintainer,
                  project_bot.resource_bot_resource,
                  expiring_token,
                  {},
                  mail: "bot_resource_access_token_about_to_expire_email"
                ).and(
                  have_enqueued_email(
                    owner2,
                    project_bot.resource_bot_resource,
                    expiring_token,
                    {},
                    mail: "bot_resource_access_token_about_to_expire_email"
                  )
                )
              )
            end

            it 'does not send email to inherited members' do
              expect { notification_service }.not_to(
                have_enqueued_email(
                  owner1,
                  project_bot.resource_bot_resource,
                  expiring_token,
                  {},
                  mail: "bot_resource_access_token_about_to_expire_email"
                )
              )
            end
          end

          context 'when instance setting resource_access_token_notify_inherited is enforced' do
            before do
              stub_application_setting(
                resource_access_token_notify_inherited: false,
                lock_resource_access_token_notify_inherited: true
              )
            end

            it_behaves_like 'does not email inherited members'
          end

          context 'when group setting resource_access_token_notify_inherited is false' do
            before(:context) do
              group.resource_access_token_notify_inherited = false
              group.save!
            end

            # since this setting is on namespace_settings, it doesn't get automatically rolled back correctly
            after(:context) do
              group.resource_access_token_notify_inherited = nil
              group.save!
            end

            it_behaves_like 'does not email inherited members'
          end

          context 'when parent group setting resource_access_token_notify_inherited is false' do
            before(:context) do
              parent_group.lock_resource_access_token_notify_inherited = true
              parent_group.resource_access_token_notify_inherited = false
              parent_group.save!
            end

            # since this setting is on namespace_settings, it doesn't get automatically rolled back correctly
            after(:context) do
              parent_group.lock_resource_access_token_notify_inherited = false
              parent_group.resource_access_token_notify_inherited = nil
              parent_group.save!
            end

            it_behaves_like 'does not email inherited members'
          end
        end
      end

      # this should never happen in real-world usage, but we have to make rspec coverage happy
      context 'when resource is missing' do
        it 'raises an ArgumentError for invalid project bot' do
          allow(notification).to receive(:send_bot_rat_expiry_to_inherited?).and_return(true)
          resource_double = double('Not Real Class')
          allow(project_bot).to receive(:resource_bot_resource).and_return(resource_double)

          expect { notification_service }.to raise_error(ArgumentError)
        end
      end
    end

    describe '#access_token_about_to_expire' do
      let_it_be(:user) { create(:user) }
      let_it_be(:pat) { create(:personal_access_token, user: user, expires_at: 5.days.from_now) }

      subject(:notification_service) { notification.access_token_about_to_expire(user, [pat.name]) }

      it 'sends email to the token owner' do
        expect { notification_service }.to have_enqueued_email(user, [pat.name], {}, mail: "access_token_about_to_expire_email")
      end

      it "logs notication sent message" do
        expect(Gitlab::AppLogger).to(
          receive(:info)
            .with({ message: "Notifying User about expiring tokens",
                    class: described_class,
                    user_id: user.id })
        )

        notification_service
      end
    end

    describe '#deploy_token_about_to_expire' do
      let_it_be(:project) { create(:project) }
      let_it_be(:regular_user) { create(:user) }
      let_it_be(:project_owner) { create(:user) }
      let_it_be(:project_maintainer) { create(:user) }
      let_it_be(:deploy_token) { create(:deploy_token, expires_at: 5.days.from_now.iso8601) }
      let_it_be(:project_deploy_token) { create(:project_deploy_token, project: project, deploy_token: deploy_token) }

      before do
        project.add_owner(project_owner)
        project.add_maintainer(project_maintainer)
      end

      it 'sends emails to project owner and maintainer' do
        expect do
          notification.deploy_token_about_to_expire(project_owner, deploy_token.name, project)
        end.to have_enqueued_email(project_owner, deploy_token.name, project, {}, mail: "deploy_token_about_to_expire_email")

        expect do
          notification.deploy_token_about_to_expire(project_maintainer, deploy_token.name, project)
        end.to have_enqueued_email(project_maintainer, deploy_token.name, project, {}, mail: "deploy_token_about_to_expire_email")
      end

      it 'logs notification sent message for both users' do
        expect(Gitlab::AppLogger).to receive(:info).with({
          message: "Notifying user about expiring deploy tokens",
          class: described_class,
          user_id: project_owner.id
        })

        expect(Gitlab::AppLogger).to receive(:info).with({
          message: "Notifying user about expiring deploy tokens",
          class: described_class,
          user_id: project_maintainer.id
        })

        notification.deploy_token_about_to_expire(project_owner, deploy_token.name, project)
        notification.deploy_token_about_to_expire(project_maintainer, deploy_token.name, project)
      end

      context 'when user is not allowed to receive notifications' do
        before do
          project_owner.block!
        end

        it 'does not send email to blocked user' do
          expect do
            notification.deploy_token_about_to_expire(project_owner, deploy_token.name, project)
          end.not_to have_enqueued_email(project_owner, deploy_token.name, project, {}, mail: "deploy_token_about_to_expire_email")

          expect do
            notification.deploy_token_about_to_expire(project_maintainer, deploy_token.name, project)
          end.to have_enqueued_email(project_maintainer, deploy_token.name, project, {}, mail: "deploy_token_about_to_expire_email")
        end
      end

      context 'when user is neither owner nor maintainer' do
        let(:regular_user) { create(:user) }

        it 'does not send email to users without proper permissions' do
          expect do
            notification.deploy_token_about_to_expire(regular_user, deploy_token.name, project)
          end.not_to have_enqueued_email(regular_user, deploy_token.name, project, {}, mail: "deploy_token_about_to_expire_email")
        end

        it 'does not log notification message for unauthorized users' do
          expect(Gitlab::AppLogger).not_to receive(:info)
          notification.deploy_token_about_to_expire(regular_user, deploy_token.name, project)
        end
      end
    end

    describe '#access_token_expired' do
      let_it_be(:user) { create(:user) }
      let_it_be(:pat) { create(:personal_access_token, user: user) }

      subject { notification.access_token_expired(user, pat.name) }

      it 'sends email to the token owner' do
        expect { subject }.to have_enqueued_email(user, pat.name, mail: "access_token_expired_email")
      end

      context 'when user is not allowed to receive notifications' do
        before do
          user.block!
        end

        it 'does not send email to the token owner' do
          expect { subject }.not_to have_enqueued_email(user, pat.name, mail: "access_token_expired_email")
        end
      end
    end

    describe '#access_token_revoked' do
      let_it_be(:user) { create(:user) }
      let_it_be(:pat) { create(:personal_access_token, user: user) }

      subject(:notification_service) { notification.access_token_revoked(user, pat.name) }

      it 'sends email to the token owner without source' do
        expect { notification_service }.to have_enqueued_email(user, pat.name, nil, mail: "access_token_revoked_email")
      end

      it 'sends email to the token owner with source' do
        expect do
          notification.access_token_revoked(user, pat.name, 'secret_detection')
        end.to have_enqueued_email(user, pat.name, 'secret_detection', mail: "access_token_revoked_email")
      end

      context 'when user is not allowed to receive notifications' do
        before do
          user.block!
        end

        it 'does not send email to the token owner' do
          expect { notification_service }.not_to have_enqueued_email(user, pat.name, mail: "access_token_revoked_email")
        end
      end
    end

    describe '#access_token_rotated' do
      let_it_be(:user) { create(:user) }
      let_it_be(:pat) { create(:personal_access_token, user: user) }

      subject(:notification_service) { notification.access_token_rotated(user, pat.name) }

      it 'sends email to the token owner' do
        expect { notification_service }.to have_enqueued_email(user, pat.name, mail: "access_token_rotated_email")
      end

      context 'when user is not allowed to receive notifications' do
        before do
          user.block!
        end

        it 'does not send email to the token owner' do
          expect { notification_service }.not_to have_enqueued_email(user, pat.name, mail: "access_token_rotated_email")
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
    let(:user) { create(:user) }
    let(:ip) { '127.0.0.1' }
    let(:country) { 'Germany' }
    let(:city) { 'Frankfurt' }
    let(:request_info) { Struct.new(:country, :city).new(country, city) }
    let(:time) { Time.current }

    subject { notification.unknown_sign_in(user, ip, time, request_info) }

    it 'sends email to the user' do
      expect { subject }.to have_enqueued_email(user, ip, time, { country: country, city: city }, mail: 'unknown_sign_in_email')
    end
  end

  describe '#enabled_two_factor' do
    let_it_be(:user) { create(:user) }

    describe 'Passkey' do
      subject { notification.enabled_two_factor(user, :passkey, device_name: 'MacBook Touch ID') }

      it 'sends email to the user' do
        expect { subject }.to have_enqueued_email(user, 'MacBook Touch ID', :passkey, mail: 'enabled_two_factor_webauthn_email')
      end
    end

    describe 'Time-based OTP' do
      subject { notification.enabled_two_factor(user, :otp) }

      it 'sends email to the user' do
        expect { subject }.to have_enqueued_email(user, mail: 'enabled_two_factor_otp_email')
      end
    end

    describe 'WebAuthn' do
      subject { notification.enabled_two_factor(user, :webauthn, device_name: 'MacBook Touch ID') }

      it 'sends email to the user' do
        expect { subject }.to have_enqueued_email(user, 'MacBook Touch ID', mail: 'enabled_two_factor_webauthn_email')
      end
    end
  end

  describe '#disabled_two_factor' do
    let_it_be(:user) { create(:user) }

    describe 'Two Factor' do
      subject { notification.disabled_two_factor(user) }

      it 'sends email to the user' do
        expect { subject }.to have_enqueued_email(user, mail: 'disabled_two_factor_email')
      end
    end

    describe 'Passkey' do
      subject { notification.disabled_two_factor(user, :passkey, device_name: 'MacBook Touch ID') }

      it 'sends email to the user' do
        expect { subject }.to have_enqueued_email(user, 'MacBook Touch ID', :passkey, mail: 'disabled_two_factor_webauthn_email')
      end
    end

    describe 'Time-based OTP' do
      subject { notification.disabled_two_factor(user, :otp) }

      it 'sends email to the user' do
        expect { subject }.to have_enqueued_email(user, mail: 'disabled_two_factor_otp_email')
      end
    end

    describe 'WebAuthn' do
      subject { notification.disabled_two_factor(user, :webauthn, device_name: 'MacBook Touch ID') }

      it 'sends email to the user' do
        expect { subject }.to have_enqueued_email(user, 'MacBook Touch ID', mail: 'disabled_two_factor_webauthn_email')
      end
    end
  end

  describe '#new_email_address_added' do
    let_it_be(:user) { create(:user) }
    let_it_be(:email) { create(:email, user: user) }

    subject { notification.new_email_address_added(user, email) }

    it 'sends email to the user' do
      expect { subject }.to have_enqueued_email(user, email, mail: 'new_email_address_added_email')
    end
  end

  describe 'Notes' do
    describe 'issue note' do
      let_it_be(:project) { create(:project, :private) }
      let_it_be_with_reload(:issue) { create(:issue, project: project, assignees: [assignee]) }
      let_it_be(:mentioned_issue) { create(:issue, assignees: issue.assignees) }
      let_it_be_with_reload(:author) { create(:user) }

      let(:note) { create(:note_on_issue, author: author, noteable: issue, project_id: issue.project_id, note: '@mention referenced, @unsubscribed_mentioned and @outsider also') }

      subject { notification.new_note(note) }

      describe 'issue_email_participants' do
        before do
          allow(Notify).to receive(:service_desk_new_note_email)
                             .with(Integer, Integer, IssueEmailParticipant).and_return(mailer)

          allow(::Gitlab::Email::IncomingEmail).to receive(:enabled?).and_return(true)
          allow(::Gitlab::Email::IncomingEmail).to receive(:supports_wildcard?).and_return(true)
        end

        let_it_be(:project) { create(:project) }
        let_it_be(:support_bot) { create(:support_bot) }
        let(:mailer) { double(deliver_later: true) }
        let(:issue) { create(:issue, project: project, author: support_bot) }
        let(:work_item) { create(:work_item, :ticket, project: project, author: support_bot) }
        let(:noteable) { issue }

        let(:note) { create(:note, noteable: noteable, project: project) }

        subject(:notification_service) { described_class.new }

        shared_examples 'notification with exact metric events' do |number_of_events|
          it 'adds metric event' do
            metric_transaction = double('Gitlab::Metrics::WebTransaction', increment: true, observe: true)
            allow(::Gitlab::Metrics::BackgroundTransaction).to receive(:current).and_return(metric_transaction)
            expect(metric_transaction).to receive(:add_event)
              .with(:service_desk_new_note_email).exactly(number_of_events).times

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

        shared_examples 'about sending service desk emails' do
          it_behaves_like 'no participants are notified'

          context 'when issue email participants exist and note not confidential' do
            let!(:issue_email_participant) { noteable.issue_email_participants.create!(email: 'service.desk@example.com') }

            before do
              noteable.update!(external_author: 'service.desk@example.com')
              project.update!(service_desk_enabled: true)
            end

            it 'sends the email' do
              expect(Notify).to receive(:service_desk_new_note_email)
                .with(noteable.id, note.id, issue_email_participant)

              notification_service.new_note(note)
            end

            it_behaves_like 'notification with exact metric events', 1

            context 'when service desk is disabled' do
              before do
                project.update!(service_desk_enabled: false)
              end

              it_behaves_like 'no participants are notified'
            end

            context 'with multiple external participants' do
              let!(:other_external_participant) { noteable.issue_email_participants.create!(email: 'user@example.com') }

              it 'sends emails' do
                expect(Notify).to receive(:service_desk_new_note_email)
                  .with(noteable.id, note.id, IssueEmailParticipant).twice

                notification_service.new_note(note)
              end

              context 'when note is from an external participant' do
                shared_examples 'only sends one Service Desk notification email' do
                  it 'sends one email' do
                    expect(Notify).not_to receive(:service_desk_new_note_email)
                      .with(noteable.id, note.id, non_recipient)

                    expect(Notify).to receive(:service_desk_new_note_email)
                      .with(noteable.id, note.id, recipient)

                    notification_service.new_note(note)
                  end
                end

                let!(:note) do
                  create(
                    :note_on_issue,
                    author: support_bot,
                    noteable: noteable,
                    project_id: noteable.project_id,
                    note: '@mention referenced, unsubscribed_mentioned and @outsider also'
                  )
                end

                context 'and the note is from the external issue author' do
                  let(:non_recipient) { issue_email_participant }
                  let(:recipient) { other_external_participant }
                  let!(:note_metadata) do
                    create(:note_metadata, note: note, email_participant: issue_email_participant.email)
                  end

                  it_behaves_like 'only sends one Service Desk notification email'
                end

                context 'and the note is from another external participant' do
                  let(:non_recipient) { other_external_participant }
                  let(:recipient) { issue_email_participant }
                  let!(:note_metadata) do
                    create(:note_metadata, note: note, email_participant: other_external_participant.email)
                  end

                  it_behaves_like 'only sends one Service Desk notification email'

                  context 'and the external note auhor email has different format' do
                    let(:non_recipient) { other_external_participant }
                    let(:recipient) { issue_email_participant }
                    let!(:note_metadata) do
                      create(:note_metadata, note: note, email_participant: 'USER@example.com')
                    end

                    it_behaves_like 'only sends one Service Desk notification email'
                  end
                end
              end
            end
          end

          context 'when issue email participants exist and note is confidential' do
            let(:note) { create(:note, noteable: noteable, project: project, confidential: true) }
            let!(:issue_email_participant) { noteable.issue_email_participants.create!(email: 'service.desk@example.com') }

            before do
              noteable.update!(external_author: 'service.desk@example.com')
              project.update!(service_desk_enabled: true)
            end

            it_behaves_like 'no participants are notified'
          end
        end

        include_examples 'about sending service desk emails'

        context 'when noteable is a work item ticket' do
          let(:noteable) { work_item }

          include_examples 'about sending service desk emails'
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
            note: 'i think subscribed_participant should see this'
          )

          update_custom_notification(:new_note, u_guest_custom, resource: project)
          update_custom_notification(:new_note, u_custom_global)
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
            expect_enqueud_email(u_watcher.id, note.id, nil, mail: "note_issue_email")
            expect_enqueud_email(note.noteable.author.id, note.id, nil, mail: "note_issue_email")
            expect_enqueud_email(note.noteable.assignees.first.id, note.id, nil, mail: "note_issue_email")
            expect_enqueud_email(u_custom_global.id, note.id, nil, mail: "note_issue_email")
            expect_enqueud_email(u_mentioned.id, note.id, "mentioned", mail: "note_issue_email")
            expect_enqueud_email(subscriber.id, note.id, "subscribed", mail: "note_issue_email")
            expect_enqueud_email(watcher_and_subscriber.id, note.id, "subscribed", mail: "note_issue_email")
            expect_enqueud_email(subscribed_participant.id, note.id, "subscribed", mail: "note_issue_email")
            expect_enqueud_email(@u_custom_off.id, note.id, nil, mail: "note_issue_email")
            expect_enqueud_email(unsubscribed_mentioned.id, note.id, "mentioned", mail: "note_issue_email")
          end

          it "emails the note author if they've opted into notifications about their activity" do
            note.author.notified_of_own_activity = true

            expect do
              notification.new_note(note)
            end.to enqueue_mail_with(Notify, :note_issue_email, note.author, note, "own_activity")
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
              note.author = u_lazy_participant
              note.save!
            end

            it { expect { subject }.not_to have_enqueued_email(u_lazy_participant.id, note.id, mail: "note_issue_email") }
          end
        end

        context 'in project that belongs to a group' do
          let_it_be(:parent_group) { create(:group) }

          before do
            note.project.namespace_id = group.id
            group.add_member(u_watcher, GroupMember::MAINTAINER)
            group.add_member(u_custom_global, GroupMember::MAINTAINER)
            note.project.save!

            u_watcher.notification_settings_for(note.project).participating!
            u_watcher.notification_settings_for(group).global!
            update_custom_notification(:new_note, u_custom_global)
            reset_delivered_emails!
          end

          shared_examples 'new note notifications' do
            it 'sends notifications' do
              expect do
                notification.new_note(note)
              end.to enqueue_mail_with(Notify, :note_issue_email, note.noteable.author, any_args)
                .and(enqueue_mail_with(Notify, :note_issue_email, note.noteable.assignees.first, any_args))
                .and(enqueue_mail_with(Notify, :note_issue_email, u_mentioned, note, "mentioned"))
                .and(enqueue_mail_with(Notify, :note_issue_email, u_custom_global, note, nil))
                .and(not_enqueue_mail_with(Notify, :note_issue_email, u_guest_custom, any_args))
                .and(not_enqueue_mail_with(Notify, :note_issue_email, u_guest_watcher, any_args))
                .and(not_enqueue_mail_with(Notify, :note_issue_email, u_watcher, any_args))
                .and(not_enqueue_mail_with(Notify, :note_issue_email, note.author, any_args))
                .and(not_enqueue_mail_with(Notify, :note_issue_email, u_participating, any_args))
                .and(not_enqueue_mail_with(Notify, :note_issue_email, u_disabled, any_args))
                .and(not_enqueue_mail_with(Notify, :note_issue_email, u_lazy_participant, any_args))
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

    context 'issue note mention' do
      let_it_be(:issue) { create(:issue, project: project, assignees: [assignee]) }
      let_it_be(:mentioned_issue) { create(:issue, assignees: issue.assignees) }
      let_it_be(:user_to_exclude) { create(:user) }
      let_it_be(:author) { create(:user) }

      let(:user_mentions) do
        other_members = [
          unsubscribed_mentioned,
          u_guest_watcher,
          pg_watcher,
          u_mentioned,
          u_not_mentioned,
          u_disabled,
          pg_disabled
        ]

        (issue.project.team.members + other_members).map(&:to_reference).join(' ')
      end

      let(:note) { create(:note_on_issue, author: author, noteable: issue, project_id: issue.project_id, note: note_content) }

      before_all do
        build_team(project)
        move_to_child_group(project)
        add_users(project)
        add_user_subscriptions(issue)
        project.add_maintainer(author)
      end

      before do
        reset_delivered_emails!
      end

      describe '#new_note' do
        it 'notifies parent group members with mention level' do
          note = create(:note_on_issue, noteable: issue, project_id: issue.project_id, note: "@#{pg_mention.username}")

          expect do
            notification.new_note(note)
          end.to enqueue_mail_with(Notify, :note_issue_email, pg_mention, any_args)
        end

        shared_examples 'correct team members are notified' do
          it 'notifies the team members' do
            expect do
              notification.new_note(note)
            end.to not_enqueue_mail_with(Notify, :note_issue_email, note.author, any_args)
              .and(not_enqueue_mail_with(Notify, :note_issue_email, u_disabled, any_args))
              .and(not_enqueue_mail_with(Notify, :note_issue_email, pg_disabled, any_args))

            expect(note.project.team.members).to include(unsubscribed_mentioned)

            note.project.team.members.each do |member|
              next if member.id == u_disabled.id
              next if member.id == note.author.id

              expect_enqueud_email(member.id, note.id, anything, mail: "note_issue_email")
            end

            expect_enqueud_email(u_guest_watcher.id, note.id, anything, mail: "note_issue_email")
            expect_enqueud_email(note.noteable.author.id, note.id, anything, mail: "note_issue_email")
            expect_enqueud_email(note.noteable.assignees.first.id, note.id, anything, mail: "note_issue_email")
            expect_enqueud_email(pg_watcher.id, note.id, anything, mail: "note_issue_email")
            expect_enqueud_email(u_mentioned.id, note.id, anything, mail: "note_issue_email")
            expect_enqueud_email(u_not_mentioned.id, note.id, anything, mail: "note_issue_email")
          end

          it 'filters out "mentioned in" notes' do
            mentioned_note = SystemNoteService.cross_reference(mentioned_issue, issue, issue.author)

            expect(Notify).not_to receive(:note_issue_email)
            notification.new_note(mentioned_note)
          end

          it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
            let(:notification_target)  { note }
            let(:notification_trigger) { notification.new_note(note) }
          end

          context 'when note is confidential' do
            let(:note) { create(:note_on_issue, author: author, noteable: issue, project_id: issue.project_id, note: note_content, confidential: true) }
            let(:guest) { create(:user) }

            it 'does not notify users that cannot read note' do
              project.add_guest(guest)
              reset_delivered_emails!

              expect do
                notification.new_note(note)
              end.to not_enqueue_mail_with(Notify, :note_issue_email, guest, any_args)
            end
          end
        end

        context 'when `@all` mention is used' do
          before_all do
            # user_to_exclude is in the note's project but is neither mentioned nor participating.
            project.add_maintainer(user_to_exclude)
          end

          let(:note_content) { "@all mentioned" }

          it "does not notify users who are not participating or mentioned" do
            reset_delivered_emails!

            expect do
              notification.new_note(note)
            end.to enqueue_mail_with(Notify, :note_issue_email, note.noteable.author, any_args)
              .and(not_enqueue_mail_with(Notify, :note_issue_email, user_to_exclude, any_args))
          end
        end

        context 'when users are individually mentioned' do
          # `user_mentions` is concatenanting individual user mentions
          # so that the end result is the same as `@all`.
          let(:note_content) { "#{user_mentions} mentioned" }

          it_behaves_like 'correct team members are notified'
        end
      end

      describe '#new_mentions_in_note' do
        let(:note) { create(:note_on_issue, author: author, noteable: issue, project_id: issue.project_id, note: "Hello @#{u_mentioned.to_reference}") }

        it 'sends email to newly mentioned users' do
          expect do
            notification.new_mentions_in_note(note, [u_mentioned], author)
          end.to have_only_enqueued_mail_with_args(Notify, :note_issue_email, [u_mentioned.id, note.id, "mentioned"])
        end

        it 'does not send email when there are no new mentions' do
          expect do
            notification.new_mentions_in_note(note, [], author)
          end.not_to have_enqueued_mail(Notify, :note_issue_email)
        end

        it 'does not send email to users not in the new mentions list' do
          expect do
            notification.new_mentions_in_note(note, [u_mentioned], author)
          end.to not_enqueue_mail_with(Notify, :note_issue_email, u_disabled, any_args)
        end

        it 'filters out "mentioned in" system notes' do
          mentioned_note = SystemNoteService.cross_reference(mentioned_issue, issue, issue.author)

          expect do
            notification.new_mentions_in_note(mentioned_note, [u_mentioned], author)
          end.not_to have_enqueued_mail(Notify, :note_issue_email)
        end

        context 'when the author is blocked' do
          let(:blocked_author) { blocked_user }

          it 'does not send any notification' do
            expect do
              notification.new_mentions_in_note(note, [u_mentioned], blocked_author)
            end.not_to have_enqueued_mail(Notify, :note_issue_email)
          end
        end

        context 'when the author is a ghost' do
          let(:ghost_author) { ghost_user }

          it 'does not send any notification' do
            expect do
              notification.new_mentions_in_note(note, [u_mentioned], ghost_author)
            end.not_to have_enqueued_mail(Notify, :note_issue_email)
          end
        end

        context 'when the note has no noteable_type' do
          it 'returns true without sending notifications' do
            allow(note).to receive(:noteable_type).and_return(nil)

            expect(notification.new_mentions_in_note(note, [u_mentioned], author)).to be(true)
            expect_no_delivery_jobs
          end
        end
      end
    end

    context 'project snippet note' do
      let(:user_mentions) do
        other_members = [
          u_custom_global,
          u_guest_watcher,
          snippet.author, # snippet = note.noteable's author
          author, # note's author
          u_disabled,
          u_mentioned,
          u_not_mentioned
        ]

        (snippet.project.team.members + other_members).map(&:to_reference).join(' ')
      end

      let(:snippet) { create(:project_snippet, project: project, author: create(:user)) }
      let(:author) { create(:user) }
      let(:note) { create(:note_on_project_snippet, author: author, noteable: snippet, project_id: project.id, note: note_content) }

      describe '#new_note' do
        shared_examples 'correct team members are notified' do
          before do
            build_team(project)
            move_to_child_group(project)
            project.add_maintainer(author)

            # make sure these users can read the project snippet!
            project.add_guest(u_guest_watcher)
            project.add_guest(u_guest_custom)
            add_member_for_parent_group(pg_watcher, project)
            reset_delivered_emails!
          end

          it 'notifies the team members' do
            expect do
              notification.new_note(note)
            end.to not_enqueue_mail_with(Notify, :note_snippet_email, note.author, any_args)
              .and(not_enqueue_mail_with(Notify, :note_snippet_email, u_disabled, any_args))

            note.project.team.members.each do |member|
              next if member.id == u_disabled.id
              next if member.id == note.author.id

              expect_enqueud_email(member.id, note.id, anything, mail: "note_snippet_email")
            end

            expect_enqueud_email(u_custom_global.id, note.id, anything, mail: "note_snippet_email")
            expect_enqueud_email(u_guest_watcher.id, note.id, anything, mail: "note_snippet_email")
            expect_enqueud_email(note.noteable.author.id, note.id, anything, mail: "note_snippet_email")
            expect_enqueud_email(u_mentioned.id, note.id, anything, mail: "note_snippet_email")
            expect_enqueud_email(u_not_mentioned.id, note.id, anything, mail: "note_snippet_email")
          end
        end

        context 'when `@all` mention is used' do
          let(:user_to_exclude) { create(:user) }
          let(:note_content) { "@all mentioned" }

          before do
            project.add_maintainer(author)
            project.add_maintainer(user_to_exclude)

            reset_delivered_emails!
          end

          it "does not notify users who are not participating or mentioned" do
            expect do
              notification.new_note(note)
            end.to enqueue_mail_with(Notify, :note_snippet_email, note.noteable.author, any_args)
              .and(not_enqueue_mail_with(Notify, :note_snippet_email, user_to_exclude, any_args))
          end
        end

        context 'when users are individually mentioned' do
          # `user_mentions` is concatenanting individual user mentions
          # so that the end result is the same as `@all`.
          let(:note_content) { "#{user_mentions} mentioned" }

          it_behaves_like 'correct team members are notified'
        end
      end
    end

    context 'personal snippet note' do
      before do
        @u_participant           = create_global_setting_for(create(:user), :participating)
        @u_mentioned_level       = create_global_setting_for(create(:user, username: 'participator'), :mention)
        @u_note_author           = create(:user, username: 'note_author')
        @u_snippet_author        = create(:user, username: 'snippet_author')

        reset_delivered_emails!
      end

      let(:snippet) { create(:personal_snippet, :public, author: @u_snippet_author) }
      let(:note)    { create(:note_on_personal_snippet, noteable: snippet, note: '@mention note', author: @u_note_author) }

      let!(:notes) do
        [
          create(:note_on_personal_snippet, noteable: snippet, note: 'note', author: u_watcher),
          create(:note_on_personal_snippet, noteable: snippet, note: 'note', author: @u_participant),
          create(:note_on_personal_snippet, noteable: snippet, note: 'note', author: u_mentioned),
          create(:note_on_personal_snippet, noteable: snippet, note: 'note', author: u_disabled),
          create(:note_on_personal_snippet, noteable: snippet, note: 'note', author: @u_note_author)
        ]
      end

      describe '#new_note' do
        it 'notifies the participants' do
          expect do
            notification.new_note(note)
          end.to enqueue_mail_with(Notify, :note_snippet_email, u_watcher, any_args)
            .and(enqueue_mail_with(Notify, :note_snippet_email, @u_participant, any_args))
            .and(enqueue_mail_with(Notify, :note_snippet_email, @u_snippet_author, any_args))
            .and(enqueue_mail_with(Notify, :note_snippet_email, u_mentioned, any_args))
            .and(not_enqueue_mail_with(Notify, :note_snippet_email, @u_mentioned_level, any_args))
            .and(not_enqueue_mail_with(Notify, :note_snippet_email, @u_note_author, any_args))
        end
      end
    end

    context 'commit note' do
      let_it_be(:project) { create(:project, :public, :repository) }
      let_it_be(:note) { create(:note_on_commit, project: project) }

      before_all do
        build_team(project)
        move_to_child_group(project)
        update_custom_notification(:new_note, u_guest_custom, resource: project)
        update_custom_notification(:new_note, u_custom_global)
      end

      before do
        reset_delivered_emails!
        allow(note.noteable).to receive(:author).and_return(u_committer)
      end

      describe '#new_note, #perform_enqueued_jobs' do
        it do
          expect do
            notification.new_note(note)
          end.to enqueue_mail_with(Notify, :note_commit_email, u_guest_watcher, any_args)
            .and(enqueue_mail_with(Notify, :note_commit_email, u_custom_global, any_args))
            .and(enqueue_mail_with(Notify, :note_commit_email, u_guest_custom, any_args))
            .and(enqueue_mail_with(Notify, :note_commit_email, u_committer, any_args))
            .and(enqueue_mail_with(Notify, :note_commit_email, u_watcher, any_args))
            .and(enqueue_mail_with(Notify, :note_commit_email, pg_watcher, any_args))
            .and(not_enqueue_mail_with(Notify, :note_commit_email, u_mentioned, any_args))
            .and(not_enqueue_mail_with(Notify, :note_commit_email, note.author, any_args))
            .and(not_enqueue_mail_with(Notify, :note_commit_email, u_participating, any_args))
            .and(not_enqueue_mail_with(Notify, :note_commit_email, u_disabled, any_args))
            .and(not_enqueue_mail_with(Notify, :note_commit_email, u_lazy_participant, any_args))
            .and(not_enqueue_mail_with(Notify, :note_commit_email, pg_disabled, any_args))
        end

        it do
          note.update_attribute(:note, '@mention referenced')

          expect do
            notification.new_note(note)
          end.to enqueue_mail_with(Notify, :note_commit_email, u_guest_watcher, any_args)
            .and(enqueue_mail_with(Notify, :note_commit_email, u_committer, any_args))
            .and(enqueue_mail_with(Notify, :note_commit_email, u_watcher, any_args))
            .and(enqueue_mail_with(Notify, :note_commit_email, u_mentioned, any_args))
            .and(enqueue_mail_with(Notify, :note_commit_email, pg_watcher, any_args))
            .and(not_enqueue_mail_with(Notify, :note_commit_email, note.author, any_args))
            .and(not_enqueue_mail_with(Notify, :note_commit_email, u_participating, any_args))
            .and(not_enqueue_mail_with(Notify, :note_commit_email, u_disabled, any_args))
            .and(not_enqueue_mail_with(Notify, :note_commit_email, u_lazy_participant, any_args))
            .and(not_enqueue_mail_with(Notify, :note_commit_email, pg_disabled, any_args))
        end

        it do
          create_global_setting_for(u_committer, :mention)

          expect do
            notification.new_note(note)
          end.to not_enqueue_mail_with(Notify, :note_commit_email, u_committer, any_args)
        end

        it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
          let(:notification_target)  { note }
          let(:notification_trigger) { notification.new_note(note) }
        end
      end
    end

    context "merge request diff note" do
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
        it "records sent notifications", :deliver_mails_inline do
          # 3 SentNotification are sent: the MR assignee and author, and the u_watcher
          expect(SentNotification).to receive(:record_note).with(note, any_args).exactly(3).times.and_call_original

          notification.new_note(note)

          expect(SentNotification.last(3).map(&:recipient).map(&:id))
            .to contain_exactly(*merge_request.assignees.pluck(:id), merge_request.author.id, u_watcher.id)
          expect(SentNotification.last.in_reply_to_discussion_id).to eq(note.discussion_id)
        end

        it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
          let(:notification_target)  { note }
          let(:notification_trigger) { notification.new_note(note) }
        end
      end
    end

    context 'design diff note' do
      include DesignManagementTestHelpers

      let_it_be(:design) { create(:design, :with_file) }
      let_it_be(:project) { design.project }
      let_it_be(:member_and_mentioned) { create(:user, developer_of: project) }
      let_it_be(:member_and_author_of_second_note) { create(:user, developer_of: project) }
      let_it_be(:member_and_not_mentioned) { create(:user, developer_of: project) }
      let_it_be(:non_member_and_mentioned) { create(:user) }
      let_it_be(:note) do
        create(
          :diff_note_on_design,
          noteable: design,
          note: "Hello #{member_and_mentioned.to_reference}, G'day #{non_member_and_mentioned.to_reference}"
        )
      end

      let_it_be(:note_2) do
        create(:diff_note_on_design, noteable: design, author: member_and_author_of_second_note)
      end

      context 'design management is enabled' do
        before do
          enable_design_management
        end

        it 'sends new note notifications', :aggregate_failures do
          expect do
            notification.new_note(note)
          end.to enqueue_mail_with(Notify, :note_design_email, design.authors.first, any_args)
            .and(enqueue_mail_with(Notify, :note_design_email, member_and_mentioned, any_args))
            .and(enqueue_mail_with(Notify, :note_design_email, member_and_author_of_second_note, any_args))
            .and(not_enqueue_mail_with(Notify, :note_design_email, member_and_not_mentioned, any_args))
            .and(not_enqueue_mail_with(Notify, :note_design_email, non_member_and_mentioned, any_args))
            .and(not_enqueue_mail_with(Notify, :note_design_email, note.author, any_args))
        end
      end

      context 'design management is disabled' do
        before do
          enable_design_management(false)
        end

        it 'does not notify anyone' do
          expect do
            notification.new_note(note)
          end.not_to have_enqueued_mail(Notify, :note_design_email)
        end
      end
    end
  end

  context 'wiki page note' do
    let_it_be(:project) { create(:project, :public, :repository) }
    let_it_be(:wiki_page_meta) { create(:wiki_page_meta, :for_wiki_page, container: project) }
    let_it_be(:note) { create(:note, noteable: wiki_page_meta, project: project) }

    before_all do
      build_team(project)
      move_to_child_group(project)
      update_custom_notification(:new_note, u_guest_custom, resource: project)
      update_custom_notification(:new_note, u_custom_global)
    end

    before do
      reset_delivered_emails!
    end

    describe '#new_note, #perform_enqueued_jobs' do
      it do
        expect do
          notification.new_note(note)
        end.to enqueue_mail_with(Notify, :note_wiki_page_email, u_guest_watcher, any_args)
          .and(enqueue_mail_with(Notify, :note_wiki_page_email, u_custom_global, any_args))
          .and(enqueue_mail_with(Notify, :note_wiki_page_email, u_guest_custom, any_args))
          .and(enqueue_mail_with(Notify, :note_wiki_page_email, u_watcher, any_args))
          .and(enqueue_mail_with(Notify, :note_wiki_page_email, pg_watcher, any_args))
          .and(not_enqueue_mail_with(Notify, :note_wiki_page_email, u_mentioned, any_args))
          .and(not_enqueue_mail_with(Notify, :note_wiki_page_email, note.author, any_args))
          .and(not_enqueue_mail_with(Notify, :note_wiki_page_email, u_participating, any_args))
          .and(not_enqueue_mail_with(Notify, :note_wiki_page_email, u_disabled, any_args))
          .and(not_enqueue_mail_with(Notify, :note_wiki_page_email, u_lazy_participant, any_args))
          .and(not_enqueue_mail_with(Notify, :note_wiki_page_email, pg_disabled, any_args))
      end

      it do
        note.update_attribute(:note, '@mention referenced')

        expect do
          notification.new_note(note)
        end.to enqueue_mail_with(Notify, :note_wiki_page_email, u_guest_watcher, any_args)
          .and(enqueue_mail_with(Notify, :note_wiki_page_email, u_watcher, any_args))
          .and(enqueue_mail_with(Notify, :note_wiki_page_email, u_mentioned, any_args))
          .and(enqueue_mail_with(Notify, :note_wiki_page_email, pg_watcher, any_args))
          .and(not_enqueue_mail_with(Notify, :note_wiki_page_email, note.author, any_args))
          .and(not_enqueue_mail_with(Notify, :note_wiki_page_email, u_participating, any_args))
          .and(not_enqueue_mail_with(Notify, :note_wiki_page_email, u_disabled, any_args))
          .and(not_enqueue_mail_with(Notify, :note_wiki_page_email, u_lazy_participant, any_args))
          .and(not_enqueue_mail_with(Notify, :note_wiki_page_email, pg_disabled, any_args))
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { note }
        let(:notification_trigger) { notification.new_note(note) }
      end
    end
  end

  describe '#send_new_release_notifications' do
    let(:release) { create(:release, project: project, author: current_user) }
    let(:object) { release }
    let(:action) { notification.send_new_release_notifications(release) }
    let(:notification_method) { :new_release_email }

    before_all do
      build_team(project)

      update_custom_notification(:new_release, u_guest_custom, resource: project)
      update_custom_notification(:new_release, u_custom_global)
    end

    context 'when release author is blocked' do
      let(:current_user) { blocked_user }

      include_examples 'is not able to send notifications', check_delivery_jobs_queue: true
    end

    context 'when release author is a ghost' do
      let(:current_user) { ghost_user }

      include_examples 'is not able to send notifications', check_delivery_jobs_queue: true
    end

    context 'when recipients for a new release exist' do
      let(:current_user) { create(:user) }

      it 'notifies the expected users' do
        notification.send_new_release_notifications(release)

        expect_delivery_jobs_count(4)
        expect_enqueud_email(u_watcher.id, release, anything, mail: "new_release_email")
        expect_enqueud_email(u_guest_watcher.id, release, anything, mail: "new_release_email")
        expect_enqueud_email(u_custom_global.id, release, anything, mail: "new_release_email")
        expect_enqueud_email(u_guest_custom.id, release, anything, mail: "new_release_email")
      end
    end
  end

  describe 'Participating project notification settings have priority over group and global settings if available' do
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

          expect do
            notification.new_issue(issue, maintainer)
          end.to not_enqueue_mail_with(Notify, :new_issue_email, user1, any_args)
        end
      end
    end

    context 'watch on group' do
      it 'does not send an email' do
        user1.notification_settings_for(group).update!(level: :watch)

        expect do
          notification.new_issue(issue, maintainer)
        end.to not_enqueue_mail_with(Notify, :new_issue_email, user1, any_args)
      end
    end

    context 'custom on global, global on group' do
      it 'does not send an email' do
        user1.notification_settings_for(nil).update!(level: :custom)

        user1.notification_settings_for(group).update!(level: :global)

        expect do
          notification.new_issue(issue, maintainer)
        end.to not_enqueue_mail_with(Notify, :new_issue_email, user1, any_args)
      end
    end

    context 'watch on global, global on group' do
      it 'does not send an email' do
        user1.notification_settings_for(nil).update!(level: :watch)

        user1.notification_settings_for(group).update!(level: :global)

        expect do
          notification.new_issue(issue, maintainer)
        end.to not_enqueue_mail_with(Notify, :new_issue_email, user1, any_args)
      end
    end
  end

  describe 'Issues and Work Items', :aggregate_failures do
    let(:another_project) { create(:project, :public, namespace: group) }
    let(:issue) { create(:issue, project: project, assignees: [assignee], description: 'cc @participant @unsubscribed_mentioned') }

    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :public, namespace: group) }

    before_all do
      build_team(project)
      move_to_child_group(project)
      add_users(project)
    end

    before do
      project.reload
      add_user_subscriptions(issue)
      reset_delivered_emails!
      update_custom_notification(:new_issue, u_guest_custom, resource: project)
      update_custom_notification(:new_issue, u_custom_global)

      issue.author.notified_of_own_activity = false
    end

    describe '#new_issue' do
      it 'notifies the expected users' do
        expect do
          notification.new_issue(issue, u_disabled)
        end.to enqueue_mail_with(Notify, :new_issue_email, assignee, issue, 'assigned')
          .and(enqueue_mail_with(Notify, :new_issue_email, u_watcher, issue, nil))
          .and(enqueue_mail_with(Notify, :new_issue_email, u_guest_watcher, issue, nil))
          .and(enqueue_mail_with(Notify, :new_issue_email, u_guest_custom, issue, nil))
          .and(enqueue_mail_with(Notify, :new_issue_email, u_custom_global, issue, nil))
          .and(enqueue_mail_with(Notify, :new_issue_email, u_participant_mentioned, issue, 'mentioned'))
          .and(enqueue_mail_with(Notify, :new_issue_email, g_global_watcher.id, issue.id, nil))
          .and(enqueue_mail_with(Notify, :new_issue_email, g_watcher, issue, nil))
          .and(enqueue_mail_with(Notify, :new_issue_email, unsubscribed_mentioned, issue, 'mentioned'))
          .and(enqueue_mail_with(Notify, :new_issue_email, pg_watcher, issue, nil))
          .and(not_enqueue_mail_with(Notify, :new_issue_email, u_mentioned, any_args))
          .and(not_enqueue_mail_with(Notify, :new_issue_email, u_participating, any_args))
          .and(not_enqueue_mail_with(Notify, :new_issue_email, u_disabled, any_args))
          .and(not_enqueue_mail_with(Notify, :new_issue_email, u_lazy_participant, any_args))
          .and(not_enqueue_mail_with(Notify, :new_issue_email, pg_disabled, any_args))
          .and(not_enqueue_mail_with(Notify, :new_issue_email, pg_mention, any_args))
      end

      context 'when user has an only mention notification setting' do
        before do
          create_global_setting_for(issue.assignees.first, :mention)
        end

        it 'does not send assignee notifications' do
          expect do
            notification.new_issue(issue, u_disabled)
          end.to not_enqueue_mail_with(Notify, :new_issue_email, issue.assignees.first, any_args)
        end
      end

      it 'properly prioritizes notification reason' do
        # have assignee be both assigned and mentioned
        issue.update_attribute(:description, "/cc #{assignee.to_reference} #{u_mentioned.to_reference}")

        expect do
          notification.new_issue(issue, u_disabled)
        end.to enqueue_mail_with(Notify, :new_issue_email, assignee, issue, 'assigned')
          .and(enqueue_mail_with(Notify, :new_issue_email, u_mentioned, issue, 'mentioned'))
      end

      it 'adds "assigned" reason for assignees if any' do
        expect do
          notification.new_issue(issue, u_disabled)
        end.to enqueue_mail_with(Notify, :new_issue_email, assignee, issue, 'assigned')
      end

      it "emails any mentioned users with the mention level" do
        issue.description = u_mentioned.to_reference

        expect do
          notification.new_issue(issue, u_disabled)
        end.to enqueue_mail_with(Notify, :new_issue_email, u_mentioned, issue, 'mentioned')
      end

      it "emails the author if they've opted into notifications about their activity" do
        issue.author.notified_of_own_activity = true

        expect do
          notification.new_issue(issue, issue.author)
        end.to enqueue_mail_with(Notify, :new_issue_email, issue.author, issue, 'own_activity')
      end

      it "doesn't email the author if they haven't opted into notifications about their activity" do
        expect do
          notification.new_issue(issue, issue.author)
        end.to not_enqueue_mail_with(Notify, :new_issue_email, issue.author, any_args)
      end

      it "emails subscribers of the issue's labels and adds `subscribed` reason" do
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

        expect do
          notification.new_issue(issue, issue.author)
        end.to enqueue_mail_with(Notify, :new_issue_email, user_1, issue, NotificationReason::SUBSCRIBED)
          .and(enqueue_mail_with(Notify, :new_issue_email, user_2, issue, NotificationReason::SUBSCRIBED))
          .and(enqueue_mail_with(Notify, :new_issue_email, user_4, issue, NotificationReason::SUBSCRIBED))
          .and(not_enqueue_mail_with(Notify, :new_issue_email, user_3, any_args))
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { issue }
        let(:notification_trigger) { notification.new_issue(issue, u_disabled) }
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

          expect do
            notification.new_issue(confidential_issue, issue.author)
          end.to enqueue_mail_with(Notify, :new_issue_email, assignee, confidential_issue, NotificationReason::ASSIGNED)
            .and(enqueue_mail_with(Notify, :new_issue_email, member, confidential_issue, NotificationReason::SUBSCRIBED))
            .and(enqueue_mail_with(Notify, :new_issue_email, admin, confidential_issue, NotificationReason::SUBSCRIBED))
            .and(not_enqueue_mail_with(Notify, :new_issue_email, u_guest_watcher, any_args))
            .and(not_enqueue_mail_with(Notify, :new_issue_email, non_member, any_args))
            .and(not_enqueue_mail_with(Notify, :new_issue_email, author, any_args))
            .and(not_enqueue_mail_with(Notify, :new_issue_email, guest, any_args))
        end
      end

      context 'when the author is not allowed to trigger notifications' do
        let(:object) { issue }
        let(:action) { notification.new_issue(issue, current_user) }
        let(:notification_method) { :new_issue_email }

        context 'because they are blocked' do
          let(:current_user) { blocked_user }

          include_examples 'is not able to send notifications', check_delivery_jobs_queue: true
        end

        context 'because they are a ghost' do
          let(:current_user) { ghost_user }

          include_examples 'is not able to send notifications', check_delivery_jobs_queue: true
        end
      end

      context 'with work item' do
        shared_examples 'notifies user with custom notification settings' do
          it 'notifies user with custom notification settings' do
            expect do
              notification.new_issue(item, u_guest_custom)
            end.to enqueue_mail_with(Notify, :new_issue_email, u_guest_custom, item, nil)
          end
        end

        context 'of type task' do
          let(:item) { create(:work_item, :task, project: project) }

          include_examples 'notifies user with custom notification settings'
        end

        context 'of type ticket' do
          let(:item) { create(:work_item, :ticket, project: project) }

          include_examples 'notifies user with custom notification settings'
        end
      end
    end

    describe '#new_mentions_in_issue' do
      let(:notification_method) { :new_mentions_in_issue }
      let(:mentionable) { issue }
      let(:object) { mentionable }
      let(:action) { send_notifications(u_mentioned, current_user: current_user) }

      it 'sends no emails when no new mentions are present' do
        send_notifications

        expect_no_delivery_jobs
      end

      it 'emails new mentions with a watch level higher than mention' do
        expect do
          send_notifications(u_watcher, u_participant_mentioned, u_custom_global, u_mentioned)
        end.to have_only_enqueued_mail_with_args(
          Notify,
          :new_mention_in_issue_email,
          [u_watcher.id, mentionable.id, any_args],
          [u_participant_mentioned.id, mentionable.id, any_args],
          [u_custom_global.id, mentionable.id, any_args],
          [u_mentioned.id, mentionable.id, any_args]
        )
      end

      it 'does not email new mentions with a watch level equal to or less than mention' do
        send_notifications(u_disabled)

        expect_no_delivery_jobs
      end

      it 'emails new mentions despite being unsubscribed' do
        expect do
          send_notifications(unsubscribed_mentioned)
        end.to have_only_enqueued_mail_with_args(
          Notify,
          :new_mention_in_issue_email,
          [unsubscribed_mentioned.id, mentionable.id, any_args]
        )
      end

      it 'sends the proper notification reason header' do
        expect do
          send_notifications(u_watcher)
        end.to have_only_enqueued_mail_with_args(
          Notify,
          :new_mention_in_issue_email,
          [u_watcher.id, mentionable.id, anything, NotificationReason::MENTIONED]
        )
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { issue }
        let(:notification_trigger) { send_notifications(u_watcher, u_participant_mentioned, u_custom_global, u_mentioned) }
      end

      context 'where current_user is blocked' do
        let(:current_user) { blocked_user }

        include_examples 'is not able to send notifications', check_delivery_jobs_queue: true
      end

      context 'where current_user is a ghost' do
        let(:current_user) { ghost_user }

        include_examples 'is not able to send notifications', check_delivery_jobs_queue: true
      end
    end

    describe '#reassigned_issue' do
      let(:mailer_method) { :reassigned_issue_email }

      before do
        update_custom_notification(:reassign_issue, u_guest_custom, resource: project)
        update_custom_notification(:reassign_issue, u_custom_global)
      end

      it 'emails new assignee' do
        expect do
          notification.reassigned_issue(issue, u_disabled, [assignee])
        end.to enqueue_mail_with(Notify, :reassigned_issue_email, issue.assignees.first, any_args)
          .and(enqueue_mail_with(Notify, :reassigned_issue_email, u_watcher, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_issue_email, u_guest_watcher, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_issue_email, u_guest_custom, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_issue_email, u_custom_global, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_issue_email, u_participant_mentioned, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_issue_email, subscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :reassigned_issue_email, unsubscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :reassigned_issue_email, u_participating, any_args))
          .and(not_enqueue_mail_with(Notify, :reassigned_issue_email, u_disabled, any_args))
          .and(not_enqueue_mail_with(Notify, :reassigned_issue_email, u_lazy_participant, any_args))
      end

      it 'adds "assigned" reason for new assignee' do
        expect do
          notification.reassigned_issue(issue, u_disabled, [assignee])
        end.to enqueue_mail_with(
          Notify,
          :reassigned_issue_email,
          issue.assignees.first,
          anything,
          anything,
          anything,
          NotificationReason::ASSIGNED
        )
      end

      it 'emails previous assignee even if they have the "on mention" notif level' do
        issue.assignees = [u_mentioned]

        expect do
          notification.reassigned_issue(issue, u_disabled, [u_watcher])
        end.to enqueue_mail_with(Notify, :reassigned_issue_email, u_mentioned, any_args)
          .and(enqueue_mail_with(Notify, :reassigned_issue_email, u_watcher, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_issue_email, u_guest_watcher, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_issue_email, u_guest_custom, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_issue_email, u_participant_mentioned, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_issue_email, subscriber, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_issue_email, u_custom_global, any_args))
          .and(not_enqueue_mail_with(Notify, :reassigned_issue_email, unsubscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :reassigned_issue_email, u_participating, any_args))
          .and(not_enqueue_mail_with(Notify, :reassigned_issue_email, u_disabled, any_args))
          .and(not_enqueue_mail_with(Notify, :reassigned_issue_email, u_lazy_participant, any_args))
      end

      it 'emails new assignee even if they have the "on mention" notif level' do
        issue.assignees = [u_mentioned]

        expect(issue.assignees.first).to eq(u_mentioned)
        expect do
          notification.reassigned_issue(issue, u_disabled, [u_mentioned])
        end.to enqueue_mail_with(Notify, :reassigned_issue_email, issue.assignees.first, any_args)
          .and(enqueue_mail_with(Notify, :reassigned_issue_email, u_watcher, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_issue_email, u_guest_watcher, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_issue_email, u_guest_custom, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_issue_email, u_participant_mentioned, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_issue_email, subscriber, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_issue_email, u_custom_global, any_args))
          .and(not_enqueue_mail_with(Notify, :reassigned_issue_email, unsubscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :reassigned_issue_email, u_participating, any_args))
          .and(not_enqueue_mail_with(Notify, :reassigned_issue_email, u_disabled, any_args))
          .and(not_enqueue_mail_with(Notify, :reassigned_issue_email, u_lazy_participant, any_args))
      end

      it 'does not email new assignee if they are the current user' do
        issue.assignees = [u_mentioned]
        notification.reassigned_issue(issue, u_mentioned, [u_mentioned])

        expect(issue.assignees.first).to eq(u_mentioned)
        expect do
          notification.reassigned_issue(issue, u_mentioned, [u_mentioned])
        end.to enqueue_mail_with(Notify, :reassigned_issue_email, u_watcher, any_args)
          .and(enqueue_mail_with(Notify, :reassigned_issue_email, u_guest_watcher, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_issue_email, u_guest_custom, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_issue_email, u_participant_mentioned, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_issue_email, subscriber, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_issue_email, u_custom_global, any_args))
          .and(not_enqueue_mail_with(Notify, :reassigned_issue_email, issue.assignees.first, any_args))
          .and(not_enqueue_mail_with(Notify, :reassigned_issue_email, unsubscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :reassigned_issue_email, u_participating, any_args))
          .and(not_enqueue_mail_with(Notify, :reassigned_issue_email, u_disabled, any_args))
          .and(not_enqueue_mail_with(Notify, :reassigned_issue_email, u_lazy_participant, any_args))
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { issue }
        let(:notification_trigger) { notification.reassigned_issue(issue, u_disabled, [assignee]) }
      end

      it_behaves_like 'participating by confidential note notification' do
        let(:issuable) { issue }
        let(:notification_trigger) { notification.reassigned_issue(issue, u_disabled, [assignee]) }
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { issue }
        let(:notification_trigger) { notification.reassigned_issue(issue, u_disabled, [assignee]) }
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

        expect do
          notification.relabeled_issue(issue, [group_label_2, label_2], subscriber_to_label_2)
        end.to enqueue_mail_with(Notify, :relabeled_issue_email, subscriber_to_label_2, any_args)
      end

      it "doesn't email the current user if they haven't opted into notifications about their activity" do
        expect do
          notification.relabeled_issue(issue, [group_label_2, label_2], subscriber_to_label_2)
        end.to not_enqueue_mail_with(Notify, :relabeled_issue_email, subscriber_to_label_2, any_args)
      end

      it "doesn't send email to anyone but subscribers of the given labels" do
        expect do
          notification.relabeled_issue(issue, [group_label_2, label_2], u_disabled)
        end.to enqueue_mail_with(Notify, :relabeled_issue_email, subscriber_1_to_group_label_2, any_args)
          .and(enqueue_mail_with(Notify, :relabeled_issue_email, subscriber_2_to_group_label_2, any_args))
          .and(enqueue_mail_with(Notify, :relabeled_issue_email, subscriber_to_label_2, any_args))
          .and(not_enqueue_mail_with(Notify, :relabeled_issue_email, subscriber_to_label_1, any_args))
          .and(not_enqueue_mail_with(Notify, :relabeled_issue_email, subscriber_to_group_label_1, any_args))
          .and(not_enqueue_mail_with(Notify, :relabeled_issue_email, subscriber_to_group_label_2_on_another_project, any_args))
          .and(not_enqueue_mail_with(Notify, :relabeled_issue_email, issue.assignees.first, any_args))
          .and(not_enqueue_mail_with(Notify, :relabeled_issue_email, issue.author, any_args))
          .and(not_enqueue_mail_with(Notify, :relabeled_issue_email, u_watcher, any_args))
          .and(not_enqueue_mail_with(Notify, :relabeled_issue_email, u_guest_watcher, any_args))
          .and(not_enqueue_mail_with(Notify, :relabeled_issue_email, u_participant_mentioned, any_args))
          .and(not_enqueue_mail_with(Notify, :relabeled_issue_email, subscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :relabeled_issue_email, watcher_and_subscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :relabeled_issue_email, unsubscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :relabeled_issue_email, u_participating, any_args))
      end

      it "doesn't send multiple email when a user is subscribed to multiple given labels" do
        subscriber_to_both = create(:user) do |user|
          [label_1, label_2].each { |label| label.toggle_subscription(user, project) }
        end

        expect do
          notification.relabeled_issue(issue, [label_1, label_2], u_disabled)
        end.to enqueue_mail_with(Notify, :relabeled_issue_email, subscriber_to_label_1, any_args)
          .and(enqueue_mail_with(Notify, :relabeled_issue_email, subscriber_to_label_2, any_args))
          .and(enqueue_mail_with(Notify, :relabeled_issue_email, subscriber_to_both, any_args))
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { issue }
        let(:notification_trigger) { notification.relabeled_issue(issue, [group_label_2, label_2], u_disabled) }
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

          expect do
            notification.relabeled_issue(confidential_issue, [label_2], u_disabled)
          end.to enqueue_mail_with(Notify, :relabeled_issue_email, author, any_args)
            .and(enqueue_mail_with(Notify, :relabeled_issue_email, assignee, any_args))
            .and(enqueue_mail_with(Notify, :relabeled_issue_email, member, any_args))
            .and(enqueue_mail_with(Notify, :relabeled_issue_email, admin, any_args))
            .and(not_enqueue_mail_with(Notify, :relabeled_issue_email, non_member, any_args))
            .and(not_enqueue_mail_with(Notify, :relabeled_issue_email, guest, any_args))
        end
      end
    end

    describe '#removed_milestone on Issue' do
      let(:mailer_method) { :removed_milestone_issue_email }

      context do
        let(:milestone) { create(:milestone, project: project, issues: [issue]) }
        let!(:subscriber_to_new_milestone) { create(:user) { |u| issue.toggle_subscription(u, project) } }

        it_behaves_like 'altered milestone notification' do
          let(:notification_target)  { issue }
          let(:notification_trigger) { notification.removed_milestone(issue, issue.author) }
        end

        it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
          let(:notification_target)  { issue }
          let(:notification_trigger) { notification.removed_milestone(issue, issue.author) }
        end

        it_behaves_like 'participating by confidential note notification' do
          let(:issuable) { issue }
          let(:notification_trigger) { notification.removed_milestone(issue, issue.author) }
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

          expect do
            notification.removed_milestone(confidential_issue, u_disabled)
          end.to enqueue_mail_with(Notify, :removed_milestone_issue_email, author, any_args)
            .and(enqueue_mail_with(Notify, :removed_milestone_issue_email, assignee, any_args))
            .and(enqueue_mail_with(Notify, :removed_milestone_issue_email, member, any_args))
            .and(enqueue_mail_with(Notify, :removed_milestone_issue_email, admin, any_args))
            .and(not_enqueue_mail_with(Notify, :removed_milestone_issue_email, non_member, any_args))
            .and(not_enqueue_mail_with(Notify, :removed_milestone_issue_email, guest, any_args))
        end
      end
    end

    describe '#changed_milestone on Issue' do
      let(:mailer_method) { :changed_milestone_issue_email }

      context do
        let(:new_milestone) { create(:milestone, project: project, issues: [issue]) }
        let!(:subscriber_to_new_milestone) { create(:user) { |u| issue.toggle_subscription(u, project) } }

        it_behaves_like 'altered milestone notification' do
          let(:notification_target)  { issue }
          let(:notification_trigger) { notification.changed_milestone(issue, new_milestone, issue.author) }
        end

        it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
          let(:notification_target)  { issue }
          let(:notification_trigger) { notification.changed_milestone(issue, new_milestone, issue.author) }
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

          expect do
            notification.changed_milestone(confidential_issue, new_milestone, u_disabled)
          end.to enqueue_mail_with(Notify, :changed_milestone_issue_email, author, any_args)
            .and(enqueue_mail_with(Notify, :changed_milestone_issue_email, assignee, any_args))
            .and(enqueue_mail_with(Notify, :changed_milestone_issue_email, member, any_args))
            .and(enqueue_mail_with(Notify, :changed_milestone_issue_email, admin, any_args))
            .and(not_enqueue_mail_with(Notify, :changed_milestone_issue_email, non_member, any_args))
            .and(not_enqueue_mail_with(Notify, :changed_milestone_issue_email, guest, any_args))
        end
      end
    end

    describe '#close_issue' do
      let(:mailer_method) { :closed_issue_email }

      before do
        update_custom_notification(:close_issue, u_guest_custom, resource: project)
        update_custom_notification(:close_issue, u_custom_global)
      end

      it 'sends email to issue assignee and issue author' do
        expect do
          notification.close_issue(issue, u_disabled)
        end.to enqueue_mail_with(Notify, :closed_issue_email, issue.assignees.first, any_args)
          .and(enqueue_mail_with(Notify, :closed_issue_email, issue.author, any_args))
          .and(enqueue_mail_with(Notify, :closed_issue_email, u_watcher, any_args))
          .and(enqueue_mail_with(Notify, :closed_issue_email, u_guest_watcher, any_args))
          .and(enqueue_mail_with(Notify, :closed_issue_email, u_guest_custom, any_args))
          .and(enqueue_mail_with(Notify, :closed_issue_email, u_custom_global, any_args))
          .and(enqueue_mail_with(Notify, :closed_issue_email, u_participant_mentioned, any_args))
          .and(enqueue_mail_with(Notify, :closed_issue_email, subscriber, any_args))
          .and(enqueue_mail_with(Notify, :closed_issue_email, watcher_and_subscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :closed_issue_email, unsubscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :closed_issue_email, u_participating, any_args))
          .and(not_enqueue_mail_with(Notify, :closed_issue_email, u_disabled, any_args))
          .and(not_enqueue_mail_with(Notify, :closed_issue_email, u_lazy_participant, any_args))
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { issue }
        let(:notification_trigger) { notification.close_issue(issue, u_disabled) }
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { issue }
        let(:notification_trigger) { notification.close_issue(issue, u_disabled) }
      end

      it_behaves_like 'participating by confidential note notification' do
        let(:issuable) { issue }
        let(:notification_trigger) { notification.close_issue(issue, u_disabled) }
      end

      it 'adds "subscribed" reason to subscriber emails', :deliver_mails_inline do
        user_1 = create(:user)
        issue.subscribe(user_1)
        issue.reload

        notification.close_issue(issue, u_disabled)

        email = find_email_for(user_1)
        expect(email).to have_header('X-GitLab-NotificationReason', NotificationReason::SUBSCRIBED)
      end
    end

    describe '#reopen_issue' do
      let(:mailer_method) { :issue_status_changed_email }

      before do
        update_custom_notification(:reopen_issue, u_guest_custom, resource: project)
        update_custom_notification(:reopen_issue, u_custom_global)
      end

      it 'sends email to issue notification recipients' do
        expect do
          notification.reopen_issue(issue, u_disabled)
        end.to enqueue_mail_with(Notify, :issue_status_changed_email, issue.assignees.first, any_args)
          .and(enqueue_mail_with(Notify, :issue_status_changed_email, issue.author, any_args))
          .and(enqueue_mail_with(Notify, :issue_status_changed_email, u_watcher, any_args))
          .and(enqueue_mail_with(Notify, :issue_status_changed_email, u_guest_watcher, any_args))
          .and(enqueue_mail_with(Notify, :issue_status_changed_email, u_guest_custom, any_args))
          .and(enqueue_mail_with(Notify, :issue_status_changed_email, u_custom_global, any_args))
          .and(enqueue_mail_with(Notify, :issue_status_changed_email, u_participant_mentioned, any_args))
          .and(enqueue_mail_with(Notify, :issue_status_changed_email, subscriber, any_args))
          .and(enqueue_mail_with(Notify, :issue_status_changed_email, watcher_and_subscriber, any_args))
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { issue }
        let(:notification_trigger) { notification.reopen_issue(issue, u_disabled) }
      end

      it_behaves_like 'participating by confidential note notification' do
        let(:issuable) { issue }
        let(:notification_trigger) { notification.reopen_issue(issue, u_disabled) }
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { issue }
        let(:notification_trigger) { notification.reopen_issue(issue, u_disabled) }
      end
    end

    describe '#issue_moved' do
      let_it_be(:new_issue) { create(:issue) }

      let(:mailer_method) { :issue_moved_email }

      it 'sends email to issue notification recipients' do
        expect do
          notification.issue_moved(issue, new_issue, u_disabled)
        end.to enqueue_mail_with(Notify, mailer_method, issue.assignees.first, any_args)
          .and(enqueue_mail_with(Notify, mailer_method, issue.author, any_args))
          .and(enqueue_mail_with(Notify, mailer_method, u_watcher, any_args))
          .and(enqueue_mail_with(Notify, mailer_method, u_guest_watcher, any_args))
          .and(enqueue_mail_with(Notify, mailer_method, u_participant_mentioned, any_args))
          .and(enqueue_mail_with(Notify, mailer_method, subscriber, any_args))
          .and(enqueue_mail_with(Notify, mailer_method, watcher_and_subscriber, any_args))
          .and(not_enqueue_mail_with(Notify, mailer_method, unsubscriber, any_args))
          .and(not_enqueue_mail_with(Notify, mailer_method, u_participating, any_args))
          .and(not_enqueue_mail_with(Notify, mailer_method, u_disabled, any_args))
          .and(not_enqueue_mail_with(Notify, mailer_method, u_lazy_participant, any_args))
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { issue }
        let(:notification_trigger) { notification.issue_moved(issue, new_issue, u_disabled) }
      end

      it_behaves_like 'participating by confidential note notification' do
        let(:issuable) { issue }
        let(:notification_trigger) { notification.issue_moved(issue, new_issue, u_disabled) }
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { issue }
        let(:notification_trigger) { notification.issue_moved(issue, new_issue, u_disabled) }
      end
    end

    describe '#issue_cloned' do
      let_it_be(:new_issue) { create(:issue) }

      let(:mailer_method) { :issue_cloned_email }

      it 'sends email to issue notification recipients' do
        expect do
          notification.issue_cloned(issue, new_issue, u_disabled)
        end.to enqueue_mail_with(Notify, mailer_method, issue.assignees.first, any_args)
          .and(enqueue_mail_with(Notify, mailer_method, issue.author, any_args))
          .and(enqueue_mail_with(Notify, mailer_method, u_watcher, any_args))
          .and(enqueue_mail_with(Notify, mailer_method, u_guest_watcher, any_args))
          .and(enqueue_mail_with(Notify, mailer_method, u_participant_mentioned, any_args))
          .and(enqueue_mail_with(Notify, mailer_method, subscriber, any_args))
          .and(enqueue_mail_with(Notify, mailer_method, watcher_and_subscriber, any_args))
          .and(not_enqueue_mail_with(Notify, mailer_method, unsubscriber, any_args))
          .and(not_enqueue_mail_with(Notify, mailer_method, u_participating, any_args))
          .and(not_enqueue_mail_with(Notify, mailer_method, u_disabled, any_args))
          .and(not_enqueue_mail_with(Notify, mailer_method, u_lazy_participant, any_args))
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { issue }
        let(:notification_trigger) { notification.issue_cloned(issue, new_issue, u_disabled) }
      end

      it_behaves_like 'participating by confidential note notification' do
        let(:issuable) { issue }
        let(:notification_trigger) { notification.issue_cloned(issue, new_issue, u_disabled) }
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { issue }
        let(:notification_trigger) { notification.issue_cloned(issue, new_issue, u_disabled) }
      end
    end

    describe '#issue_due' do
      let(:mailer_method) { :issue_due_email }

      before do
        issue.update!(due_date: Date.today)

        update_custom_notification(:issue_due, u_guest_custom, resource: project)
        update_custom_notification(:issue_due, u_custom_global)
      end

      it 'sends email to issue notification recipients, excluding watchers' do
        expect do
          notification.issue_due(issue)
        end.to enqueue_mail_with(Notify, :issue_due_email, issue.assignees.first, any_args)
          .and(enqueue_mail_with(Notify, :issue_due_email, issue.author, any_args))
          .and(enqueue_mail_with(Notify, :issue_due_email, u_guest_custom, any_args))
          .and(enqueue_mail_with(Notify, :issue_due_email, u_custom_global, any_args))
          .and(enqueue_mail_with(Notify, :issue_due_email, u_participant_mentioned, any_args))
          .and(enqueue_mail_with(Notify, :issue_due_email, subscriber, any_args))
          .and(enqueue_mail_with(Notify, :issue_due_email, watcher_and_subscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :issue_due_email, u_watcher, any_args))
          .and(not_enqueue_mail_with(Notify, :issue_due_email, u_guest_watcher, any_args))
          .and(not_enqueue_mail_with(Notify, :issue_due_email, unsubscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :issue_due_email, u_participating, any_args))
          .and(not_enqueue_mail_with(Notify, :issue_due_email, u_disabled, any_args))
          .and(not_enqueue_mail_with(Notify, :issue_due_email, u_lazy_participant, any_args))
      end

      it 'sends the email from the author', :deliver_mails_inline do
        notification.issue_due(issue)
        email = find_email_for(subscriber)

        expect(email.header[:from].display_names).to eq(["#{issue.author.name} (@#{issue.author.username})"])
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { issue }
        let(:notification_trigger) { notification.issue_due(issue) }
      end

      it_behaves_like 'participating by confidential note notification' do
        let(:issuable) { issue }
        let(:notification_trigger) { notification.issue_due(issue) }
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { issue }
        let(:notification_trigger) { notification.issue_due(issue) }
      end
    end
  end

  describe 'Merge Requests' do
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
      update_custom_notification(:new_merge_request, u_guest_custom, resource: project)
      update_custom_notification(:new_merge_request, u_custom_global)
      reset_delivered_emails!
    end

    describe '#new_merge_request' do
      let(:mailer_method) { :new_merge_request_email }

      it do
        expect do
          notification.new_merge_request(merge_request, u_disabled)
        end.to enqueue_mail_with(Notify, :new_merge_request_email, assignee, any_args)
          .and(enqueue_mail_with(Notify, :new_merge_request_email, u_watcher, any_args))
          .and(enqueue_mail_with(Notify, :new_merge_request_email, watcher_and_subscriber, any_args))
          .and(enqueue_mail_with(Notify, :new_merge_request_email, u_participant_mentioned, any_args))
          .and(enqueue_mail_with(Notify, :new_merge_request_email, u_guest_watcher, any_args))
          .and(enqueue_mail_with(Notify, :new_merge_request_email, u_guest_custom, any_args))
          .and(enqueue_mail_with(Notify, :new_merge_request_email, u_custom_global, any_args))
          .and(not_enqueue_mail_with(Notify, :new_merge_request_email, u_participating, any_args))
          .and(not_enqueue_mail_with(Notify, :new_merge_request_email, u_disabled, any_args))
          .and(not_enqueue_mail_with(Notify, :new_merge_request_email, u_lazy_participant, any_args))
      end

      it 'adds "assigned" reason for assignee, if any', :deliver_mails_inline do
        notification.new_merge_request(merge_request, u_disabled)

        merge_request.assignees.each do |assignee|
          email = find_email_for(assignee)

          expect(email).to have_header('X-GitLab-NotificationReason', NotificationReason::ASSIGNED)
        end
      end

      it "emails any mentioned users with the mention level" do
        merge_request.description = u_mentioned.to_reference

        expect do
          notification.new_merge_request(merge_request, u_disabled)
        end.to enqueue_mail_with(Notify, :new_merge_request_email, u_mentioned, any_args)
      end

      it "emails the author if they've opted into notifications about their activity", :deliver_mails_inline do
        merge_request.author.notified_of_own_activity = true

        notification.new_merge_request(merge_request, merge_request.author)

        should_email(merge_request.author)

        email = find_email_for(merge_request.author)
        expect(email).to have_header('X-GitLab-NotificationReason', NotificationReason::OWN_ACTIVITY)
      end

      it "doesn't email the author if they haven't opted into notifications about their activity" do
        expect do
          notification.new_merge_request(merge_request, merge_request.author)
        end.to not_enqueue_mail_with(Notify, :new_merge_request_email, merge_request.author, any_args)
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

        expect do
          notification.new_merge_request(merge_request, u_disabled)
        end.to enqueue_mail_with(Notify, :new_merge_request_email, user_1, any_args)
          .and(enqueue_mail_with(Notify, :new_merge_request_email, user_2, any_args))
          .and(not_enqueue_mail_with(Notify, :new_merge_request_email, user_3, any_args))
          .and(enqueue_mail_with(Notify, :new_merge_request_email, user_4, any_args))
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.new_merge_request(merge_request, u_disabled) }
      end

      describe 'Approvals' do
        let(:notification_target)  { merge_request }
        let(:maintainer) { create(:user) }

        describe '#approve_mr' do
          it 'notifies the author, subscribers, and assigned users' do
            expect do
              notification.approve_mr(merge_request, maintainer)
            end.to enqueue_mail_with(Notify, :approved_merge_request_email, assignee, any_args)
              .and(enqueue_mail_with(Notify, :approved_merge_request_email, merge_request.author, any_args))
              .and(enqueue_mail_with(Notify, :approved_merge_request_email, u_watcher, any_args))
              .and(enqueue_mail_with(Notify, :approved_merge_request_email, u_participant_mentioned, any_args))
              .and(enqueue_mail_with(Notify, :approved_merge_request_email, subscribed_participant, any_args))
              .and(enqueue_mail_with(Notify, :approved_merge_request_email, subscriber, any_args))
              .and(enqueue_mail_with(Notify, :approved_merge_request_email, watcher_and_subscriber, any_args))
              .and(enqueue_mail_with(Notify, :approved_merge_request_email, u_guest_watcher, any_args))
              .and(not_enqueue_mail_with(Notify, :approved_merge_request_email, unsubscriber, any_args))
              .and(not_enqueue_mail_with(Notify, :approved_merge_request_email, u_participating, any_args))
              .and(not_enqueue_mail_with(Notify, :approved_merge_request_email, u_disabled, any_args))
              .and(not_enqueue_mail_with(Notify, :approved_merge_request_email, u_lazy_participant, any_args))
          end

          it "emails the approver with own_activity reason if they've opted into notifications about their activity", :deliver_mails_inline do
            merge_request.author.notified_of_own_activity = true

            notification.approve_mr(merge_request, merge_request.author)

            should_email(merge_request.author)
            email = find_email_for(merge_request.author)
            expect(email).to have_header('X-GitLab-NotificationReason', NotificationReason::OWN_ACTIVITY)
          end
        end

        describe '#unapprove_mr' do
          it 'notifies the author, subscribers, and assigned users' do
            expect do
              notification.unapprove_mr(merge_request, maintainer)
            end.to enqueue_mail_with(Notify, :unapproved_merge_request_email, assignee, any_args)
              .and(enqueue_mail_with(Notify, :unapproved_merge_request_email, merge_request.author, any_args))
              .and(enqueue_mail_with(Notify, :unapproved_merge_request_email, u_watcher, any_args))
              .and(enqueue_mail_with(Notify, :unapproved_merge_request_email, u_participant_mentioned, any_args))
              .and(enqueue_mail_with(Notify, :unapproved_merge_request_email, subscribed_participant, any_args))
              .and(enqueue_mail_with(Notify, :unapproved_merge_request_email, subscriber, any_args))
              .and(enqueue_mail_with(Notify, :unapproved_merge_request_email, watcher_and_subscriber, any_args))
              .and(enqueue_mail_with(Notify, :unapproved_merge_request_email, u_guest_watcher, any_args))
              .and(not_enqueue_mail_with(Notify, :unapproved_merge_request_email, unsubscriber, any_args))
              .and(not_enqueue_mail_with(Notify, :unapproved_merge_request_email, u_participating, any_args))
              .and(not_enqueue_mail_with(Notify, :unapproved_merge_request_email, u_disabled, any_args))
              .and(not_enqueue_mail_with(Notify, :unapproved_merge_request_email, u_lazy_participant, any_args))
          end

          it "emails the unapprover with own_activity reason if they've opted into notifications about their activity", :deliver_mails_inline do
            merge_request.author.notified_of_own_activity = true

            notification.unapprove_mr(merge_request, merge_request.author)

            should_email(merge_request.author)
            email = find_email_for(merge_request.author)
            expect(email).to have_header('X-GitLab-NotificationReason', NotificationReason::OWN_ACTIVITY)
          end
        end
      end

      context 'participating' do
        it_behaves_like 'participating by assignee notification' do
          let(:participant) { create(:user, username: 'user-participant') }
          let(:issuable) { merge_request }
          let(:notification_trigger) { notification.new_merge_request(merge_request, u_disabled) }
        end

        it_behaves_like 'participating by note notification' do
          let(:participant) { create(:user, username: 'user-participant') }
          let(:issuable) { merge_request }
          let(:notification_trigger) { notification.new_merge_request(merge_request, u_disabled) }
        end

        context 'by author' do
          let(:participant) { create(:user, username: 'user-participant') }

          before do
            merge_request.author = participant
            merge_request.save!
          end

          it do
            expect do
              notification.new_merge_request(merge_request, u_disabled)
            end.to not_enqueue_mail_with(Notify, :new_merge_request_email, participant, any_args)
          end
        end
      end

      context 'when the author is not allowed to trigger notifications' do
        let(:current_user) { nil }
        let(:notification_method) { :new_merge_request_email }
        let(:object) { merge_request }
        let(:action) { notification.new_merge_request(merge_request, current_user) }

        context 'because they are blocked' do
          let(:current_user) { blocked_user }

          it_behaves_like 'is not able to send notifications', check_delivery_jobs_queue: true
        end

        context 'because they are a ghost' do
          let(:current_user) { ghost_user }

          it_behaves_like 'is not able to send notifications', check_delivery_jobs_queue: true
        end
      end
    end

    describe '#new_mentions_in_merge_request' do
      let(:notification_method) { :new_mentions_in_merge_request }
      let(:mentionable) { merge_request }
      let(:object) { mentionable }
      let(:action) { send_notifications(u_mentioned, current_user: current_user) }

      context 'new mentions', :deliver_mails_inline do
        include_examples 'notifications for new mentions'
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { send_notifications(u_watcher, u_participant_mentioned, u_custom_global, u_mentioned) }
      end

      context 'where current_user is blocked' do
        let(:current_user) { blocked_user }

        include_examples 'is not able to send notifications', check_delivery_jobs_queue: true
      end

      context 'where current_user is a ghost' do
        let(:current_user) { ghost_user }

        include_examples 'is not able to send notifications', check_delivery_jobs_queue: true
      end
    end

    describe '#reassigned_merge_request' do
      let(:mailer_method) { :reassigned_merge_request_email }
      let(:current_user) { create(:user) }

      before do
        update_custom_notification(:reassign_merge_request, u_guest_custom, resource: project)
        update_custom_notification(:reassign_merge_request, u_custom_global)
      end

      it do
        expect do
          notification.reassigned_merge_request(merge_request, current_user, [assignee])
        end.to enqueue_mail_with(Notify, :reassigned_merge_request_email, assignee, any_args)
          .and(enqueue_mail_with(Notify, :reassigned_merge_request_email, merge_request.author, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_merge_request_email, u_watcher, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_merge_request_email, u_participant_mentioned, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_merge_request_email, subscriber, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_merge_request_email, watcher_and_subscriber, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_merge_request_email, u_guest_watcher, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_merge_request_email, u_guest_custom, any_args))
          .and(enqueue_mail_with(Notify, :reassigned_merge_request_email, u_custom_global, any_args))
          .and(not_enqueue_mail_with(Notify, :reassigned_merge_request_email, unsubscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :reassigned_merge_request_email, u_participating, any_args))
          .and(not_enqueue_mail_with(Notify, :reassigned_merge_request_email, u_disabled, any_args))
          .and(not_enqueue_mail_with(Notify, :reassigned_merge_request_email, u_lazy_participant, any_args))
      end

      it 'adds "assigned" reason for new assignee', :deliver_mails_inline do
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

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.reassigned_merge_request(merge_request, current_user, [assignee]) }
      end
    end

    describe '#changed_reviewer_of_merge_request' do
      let(:merge_request) { create(:merge_request, author: author, source_project: project, reviewers: [reviewer], description: 'cc @participant') }
      let(:mailer_method) { :changed_reviewer_of_merge_request_email }

      let_it_be(:current_user) { create(:user) }
      let_it_be(:reviewer) { create(:user) }

      before do
        update_custom_notification(:change_reviewer_merge_request, u_guest_custom, resource: project)
        update_custom_notification(:change_reviewer_merge_request, u_custom_global)
      end

      it 'sends emails to relevant users only', :aggregate_failures do
        expect do
          notification.changed_reviewer_of_merge_request(merge_request, current_user, [reviewer])
        end.to enqueue_mail_with(Notify, :changed_reviewer_of_merge_request_email, reviewer, any_args)
          .and(enqueue_mail_with(Notify, :changed_reviewer_of_merge_request_email, merge_request.author, any_args))
          .and(enqueue_mail_with(Notify, :changed_reviewer_of_merge_request_email, u_watcher, any_args))
          .and(enqueue_mail_with(Notify, :changed_reviewer_of_merge_request_email, u_participant_mentioned, any_args))
          .and(enqueue_mail_with(Notify, :changed_reviewer_of_merge_request_email, subscriber, any_args))
          .and(enqueue_mail_with(Notify, :changed_reviewer_of_merge_request_email, watcher_and_subscriber, any_args))
          .and(enqueue_mail_with(Notify, :changed_reviewer_of_merge_request_email, u_guest_watcher, any_args))
          .and(enqueue_mail_with(Notify, :changed_reviewer_of_merge_request_email, u_guest_custom, any_args))
          .and(enqueue_mail_with(Notify, :changed_reviewer_of_merge_request_email, u_custom_global, any_args))
          .and(not_enqueue_mail_with(Notify, :changed_reviewer_of_merge_request_email, unsubscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :changed_reviewer_of_merge_request_email, u_participating, any_args))
          .and(not_enqueue_mail_with(Notify, :changed_reviewer_of_merge_request_email, u_disabled, any_args))
          .and(not_enqueue_mail_with(Notify, :changed_reviewer_of_merge_request_email, u_lazy_participant, any_args))
      end

      it 'adds "review requested" reason for new reviewer', :deliver_mails_inline do
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

        it_behaves_like 'participating by reviewer notification'
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { merge_request }
        let(:notification_trigger) { notification.changed_reviewer_of_merge_request(merge_request, current_user, [reviewer]) }
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.changed_reviewer_of_merge_request(merge_request, current_user, [reviewer]) }
      end
    end

    describe '#change_in_merge_request_draft_status' do
      let(:merge_request) { create(:merge_request, author: author, source_project: project) }
      let(:mailer_method) { :change_in_merge_request_draft_status_email }

      let_it_be(:current_user) { create(:user) }

      it 'sends emails to relevant users only', :aggregate_failures do
        expect do
          notification.change_in_merge_request_draft_status(merge_request, current_user)
        end.to enqueue_mail_with(Notify, :change_in_merge_request_draft_status_email, merge_request.author, any_args)
          .and(enqueue_mail_with(Notify, :change_in_merge_request_draft_status_email, u_watcher, any_args))
          .and(enqueue_mail_with(Notify, :change_in_merge_request_draft_status_email, subscriber, any_args))
          .and(enqueue_mail_with(Notify, :change_in_merge_request_draft_status_email, watcher_and_subscriber, any_args))
          .and(enqueue_mail_with(Notify, :change_in_merge_request_draft_status_email, u_guest_watcher, any_args))
          .and(not_enqueue_mail_with(Notify, :change_in_merge_request_draft_status_email, u_participant_mentioned, any_args))
          .and(not_enqueue_mail_with(Notify, :change_in_merge_request_draft_status_email, u_guest_custom, any_args))
          .and(not_enqueue_mail_with(Notify, :change_in_merge_request_draft_status_email, u_custom_global, any_args))
          .and(not_enqueue_mail_with(Notify, :change_in_merge_request_draft_status_email, unsubscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :change_in_merge_request_draft_status_email, u_participating, any_args))
          .and(not_enqueue_mail_with(Notify, :change_in_merge_request_draft_status_email, u_disabled, any_args))
          .and(not_enqueue_mail_with(Notify, :change_in_merge_request_draft_status_email, u_lazy_participant, any_args))
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { merge_request }
        let(:notification_trigger) { notification.change_in_merge_request_draft_status(merge_request, u_disabled) }
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.change_in_merge_request_draft_status(merge_request, u_disabled) }
      end
    end

    describe '#push_to_merge_request_with_data' do
      let(:new_commits_data) do
        [
          { short_id: 'a1b2c3d', title: 'First commit' },
          { short_id: 'a1b2c32', title: 'Second commit' }
        ]
      end

      let(:existing_commits_data) do
        [
          { short_id: '01d1131', title: 'Old first commit' },
          { short_id: '01d9939', title: 'Old last commit' }
        ]
      end

      before do
        update_custom_notification(:push_to_merge_request, u_guest_custom, resource: project)
        update_custom_notification(:push_to_merge_request, u_custom_global)
        allow(::Notify).to receive(:push_to_merge_request_email).and_call_original
      end

      it do
        expect do
          notification.push_to_merge_request_with_data(
            merge_request,
            merge_request.author,
            new_commits_data: new_commits_data,
            total_new_commits_count: 2,
            existing_commits_data: existing_commits_data,
            total_existing_commits_count: 50
          )
        end.to enqueue_mail_with(Notify, :push_to_merge_request_email, assignee, any_args)
          .and(enqueue_mail_with(Notify, :push_to_merge_request_email, u_guest_custom, any_args))
          .and(enqueue_mail_with(Notify, :push_to_merge_request_email, u_custom_global, any_args))
          .and(enqueue_mail_with(Notify, :push_to_merge_request_email, u_participant_mentioned, any_args))
          .and(enqueue_mail_with(Notify, :push_to_merge_request_email, subscriber, any_args))
          .and(enqueue_mail_with(Notify, :push_to_merge_request_email, watcher_and_subscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :push_to_merge_request_email, u_watcher, any_args))
          .and(not_enqueue_mail_with(Notify, :push_to_merge_request_email, u_guest_watcher, any_args))
          .and(not_enqueue_mail_with(Notify, :push_to_merge_request_email, unsubscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :push_to_merge_request_email, u_participating, any_args))
          .and(not_enqueue_mail_with(Notify, :push_to_merge_request_email, u_disabled, any_args))
          .and(not_enqueue_mail_with(Notify, :push_to_merge_request_email, u_lazy_participant, any_args))
      end

      it 'sends emails to the correct recipients with pre-computed commit data' do
        notification.push_to_merge_request_with_data(
          merge_request,
          merge_request.author,
          new_commits_data: new_commits_data,
          total_new_commits_count: 2,
          existing_commits_data: existing_commits_data,
          total_existing_commits_count: 50
        )

        expect(Notify).to have_received(:push_to_merge_request_email).at_least(:once).with(
          subscriber.id, merge_request.id, merge_request.author.id, "subscribed",
          new_commits: new_commits_data, total_new_commits_count: 2,
          existing_commits: existing_commits_data, total_existing_commits_count: 50
        )
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) do
          notification.push_to_merge_request_with_data(
            merge_request,
            u_disabled,
            new_commits_data: new_commits_data,
            total_new_commits_count: 2,
            existing_commits_data: existing_commits_data,
            total_existing_commits_count: 50
          )
        end
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
        expect do
          notification.relabeled_merge_request(merge_request, [group_label_2, label_2], u_disabled)
        end.to enqueue_mail_with(Notify, :relabeled_merge_request_email, subscriber_1_to_group_label_2, any_args)
          .and(enqueue_mail_with(Notify, :relabeled_merge_request_email, subscriber_2_to_group_label_2, any_args))
          .and(enqueue_mail_with(Notify, :relabeled_merge_request_email, subscriber_to_label_2, any_args))
          .and(not_enqueue_mail_with(Notify, :relabeled_merge_request_email, subscriber_to_label_1, any_args))
          .and(not_enqueue_mail_with(Notify, :relabeled_merge_request_email, subscriber_to_group_label_1, any_args))
          .and(not_enqueue_mail_with(Notify, :relabeled_merge_request_email, subscriber_to_group_label_2_on_another_project, any_args))
          .and(not_enqueue_mail_with(Notify, :relabeled_merge_request_email, assignee, any_args))
          .and(not_enqueue_mail_with(Notify, :relabeled_merge_request_email, merge_request.author, any_args))
          .and(not_enqueue_mail_with(Notify, :relabeled_merge_request_email, u_watcher, any_args))
          .and(not_enqueue_mail_with(Notify, :relabeled_merge_request_email, u_participant_mentioned, any_args))
          .and(not_enqueue_mail_with(Notify, :relabeled_merge_request_email, subscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :relabeled_merge_request_email, watcher_and_subscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :relabeled_merge_request_email, unsubscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :relabeled_merge_request_email, u_participating, any_args))
          .and(not_enqueue_mail_with(Notify, :relabeled_merge_request_email, u_lazy_participant, any_args))
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.relabeled_merge_request(merge_request, [group_label_2, label_2], u_disabled) }
      end
    end

    describe '#removed_milestone on MergeRequest' do
      let(:mailer_method) { :removed_milestone_merge_request_email }
      let(:milestone) { create(:milestone, project: project, merge_requests: [merge_request]) }
      let!(:subscriber_to_new_milestone) { create(:user) { |u| merge_request.toggle_subscription(u, project) } }

      it_behaves_like 'altered milestone notification' do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.removed_milestone(merge_request, merge_request.author) }
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.removed_milestone(merge_request, merge_request.author) }
      end
    end

    describe '#changed_milestone on MergeRequest' do
      let(:mailer_method) { :changed_milestone_merge_request_email }
      let(:new_milestone) { create(:milestone, project: project, merge_requests: [merge_request]) }
      let!(:subscriber_to_new_milestone) { create(:user) { |u| merge_request.toggle_subscription(u, project) } }

      it_behaves_like 'altered milestone notification' do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.changed_milestone(merge_request, new_milestone, merge_request.author) }
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.changed_milestone(merge_request, new_milestone, merge_request.author) }
      end
    end

    describe '#merge_request_unmergeable' do
      it "sends email to merge request author" do
        expect do
          notification.merge_request_unmergeable(merge_request)
        end.to enqueue_mail_with(Notify, :merge_request_unmergeable_email, merge_request.author, any_args)
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
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
          expect do
            notification.merge_request_unmergeable(merge_request)
          end.to enqueue_mail_with(Notify, :merge_request_unmergeable_email, merge_request.author, any_args)
            .and(enqueue_mail_with(Notify, :merge_request_unmergeable_email, merge_request.merge_user, any_args))
        end
      end
    end

    describe '#closed_merge_request' do
      let(:mailer_method) { :closed_merge_request_email }

      before do
        update_custom_notification(:close_merge_request, u_guest_custom, resource: project)
        update_custom_notification(:close_merge_request, u_custom_global)
      end

      it do
        expect do
          notification.close_mr(merge_request, u_disabled)
        end.to enqueue_mail_with(Notify, :closed_merge_request_email, assignee, any_args)
          .and(enqueue_mail_with(Notify, :closed_merge_request_email, u_watcher, any_args))
          .and(enqueue_mail_with(Notify, :closed_merge_request_email, u_guest_watcher, any_args))
          .and(enqueue_mail_with(Notify, :closed_merge_request_email, u_guest_custom, any_args))
          .and(enqueue_mail_with(Notify, :closed_merge_request_email, u_custom_global, any_args))
          .and(enqueue_mail_with(Notify, :closed_merge_request_email, u_participant_mentioned, any_args))
          .and(enqueue_mail_with(Notify, :closed_merge_request_email, subscriber, any_args))
          .and(enqueue_mail_with(Notify, :closed_merge_request_email, watcher_and_subscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :closed_merge_request_email, unsubscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :closed_merge_request_email, u_participating, any_args))
          .and(not_enqueue_mail_with(Notify, :closed_merge_request_email, u_disabled, any_args))
          .and(not_enqueue_mail_with(Notify, :closed_merge_request_email, u_lazy_participant, any_args))
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { merge_request }
        let(:notification_trigger) { notification.close_mr(merge_request, u_disabled) }
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.close_mr(merge_request, u_disabled) }
      end
    end

    describe '#merged_merge_request' do
      let(:mailer_method) { :merged_merge_request_email }

      before do
        update_custom_notification(:merge_merge_request, u_guest_custom, resource: project)
        update_custom_notification(:merge_merge_request, u_custom_global)
      end

      it do
        expect do
          notification.merge_mr(merge_request, u_disabled)
        end.to enqueue_mail_with(Notify, :merged_merge_request_email, assignee, any_args)
          .and(enqueue_mail_with(Notify, :merged_merge_request_email, u_watcher, any_args))
          .and(enqueue_mail_with(Notify, :merged_merge_request_email, u_guest_watcher, any_args))
          .and(enqueue_mail_with(Notify, :merged_merge_request_email, u_guest_custom, any_args))
          .and(enqueue_mail_with(Notify, :merged_merge_request_email, u_custom_global, any_args))
          .and(enqueue_mail_with(Notify, :merged_merge_request_email, u_participant_mentioned, any_args))
          .and(enqueue_mail_with(Notify, :merged_merge_request_email, subscriber, any_args))
          .and(enqueue_mail_with(Notify, :merged_merge_request_email, watcher_and_subscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :merged_merge_request_email, unsubscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :merged_merge_request_email, u_participating, any_args))
          .and(not_enqueue_mail_with(Notify, :merged_merge_request_email, u_disabled, any_args))
          .and(not_enqueue_mail_with(Notify, :merged_merge_request_email, u_lazy_participant, any_args))
      end

      it "notifies the merger when the pipeline succeeds is true" do
        merge_request.merge_when_pipeline_succeeds = true

        expect do
          notification.merge_mr(merge_request, u_watcher)
        end.to enqueue_mail_with(Notify, :merged_merge_request_email, u_watcher, any_args)
      end

      it "does not notify the merger when the pipeline succeeds is false" do
        merge_request.merge_when_pipeline_succeeds = false

        expect do
          notification.merge_mr(merge_request, u_watcher)
        end.to not_enqueue_mail_with(Notify, :merged_merge_request_email, u_watcher, any_args)
      end

      it "notifies the merger when the pipeline succeeds is false but they've opted into notifications about their activity" do
        merge_request.merge_when_pipeline_succeeds = false
        author.notified_of_own_activity = true

        expect do
          notification.merge_mr(merge_request, author)
        end.to enqueue_mail_with(Notify, :merged_merge_request_email, author, any_args)
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { merge_request }
        let(:notification_trigger) { notification.merge_mr(merge_request, u_disabled) }
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.merge_mr(merge_request, u_disabled) }
      end
    end

    describe '#reopen_merge_request' do
      let(:mailer_method) { :merge_request_status_email }

      before do
        update_custom_notification(:reopen_merge_request, u_guest_custom, resource: project)
        update_custom_notification(:reopen_merge_request, u_custom_global)
      end

      it do
        expect do
          notification.reopen_mr(merge_request, u_disabled)
        end.to enqueue_mail_with(Notify, :merge_request_status_email, assignee, any_args)
          .and(enqueue_mail_with(Notify, :merge_request_status_email, u_watcher, any_args))
          .and(enqueue_mail_with(Notify, :merge_request_status_email, u_participant_mentioned, any_args))
          .and(enqueue_mail_with(Notify, :merge_request_status_email, subscriber, any_args))
          .and(enqueue_mail_with(Notify, :merge_request_status_email, watcher_and_subscriber, any_args))
          .and(enqueue_mail_with(Notify, :merge_request_status_email, u_guest_watcher, any_args))
          .and(enqueue_mail_with(Notify, :merge_request_status_email, u_guest_custom, any_args))
          .and(enqueue_mail_with(Notify, :merge_request_status_email, u_custom_global, any_args))
          .and(not_enqueue_mail_with(Notify, :merge_request_status_email, unsubscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :merge_request_status_email, u_participating, any_args))
          .and(not_enqueue_mail_with(Notify, :merge_request_status_email, u_disabled, any_args))
          .and(not_enqueue_mail_with(Notify, :merge_request_status_email, u_lazy_participant, any_args))
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { merge_request }
        let(:notification_trigger) { notification.reopen_mr(merge_request, u_disabled) }
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.reopen_mr(merge_request, u_disabled) }
      end
    end

    describe "#resolve_all_discussions" do
      let(:mailer_method) { :resolved_all_discussions_email }

      it do
        expect do
          notification.resolve_all_discussions(merge_request, u_disabled)
        end.to enqueue_mail_with(Notify, :resolved_all_discussions_email, assignee, any_args)
          .and(enqueue_mail_with(Notify, :resolved_all_discussions_email, u_watcher, any_args))
          .and(enqueue_mail_with(Notify, :resolved_all_discussions_email, u_participant_mentioned, any_args))
          .and(enqueue_mail_with(Notify, :resolved_all_discussions_email, subscriber, any_args))
          .and(enqueue_mail_with(Notify, :resolved_all_discussions_email, watcher_and_subscriber, any_args))
          .and(enqueue_mail_with(Notify, :resolved_all_discussions_email, u_guest_watcher, any_args))
          .and(not_enqueue_mail_with(Notify, :resolved_all_discussions_email, unsubscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :resolved_all_discussions_email, u_participating, any_args))
          .and(not_enqueue_mail_with(Notify, :resolved_all_discussions_email, u_disabled, any_args))
          .and(not_enqueue_mail_with(Notify, :resolved_all_discussions_email, u_lazy_participant, any_args))
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { merge_request }
        let(:notification_trigger) { notification.resolve_all_discussions(merge_request, u_disabled) }
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.resolve_all_discussions(merge_request, u_disabled) }
      end
    end

    describe '#merge_when_pipeline_succeeds' do
      let(:mailer_method) { :merge_when_pipeline_succeeds_email }

      before do
        update_custom_notification(:merge_when_pipeline_succeeds, u_guest_custom, resource: project)
        update_custom_notification(:merge_when_pipeline_succeeds, u_custom_global)
      end

      it 'send notification that merge will happen when pipeline succeeds' do
        expect do
          notification.merge_when_pipeline_succeeds(merge_request, assignee)
        end.to enqueue_mail_with(Notify, :merge_when_pipeline_succeeds_email, merge_request.author, any_args)
          .and(enqueue_mail_with(Notify, :merge_when_pipeline_succeeds_email, u_watcher, any_args))
          .and(enqueue_mail_with(Notify, :merge_when_pipeline_succeeds_email, subscriber, any_args))
          .and(enqueue_mail_with(Notify, :merge_when_pipeline_succeeds_email, u_guest_custom, any_args))
          .and(enqueue_mail_with(Notify, :merge_when_pipeline_succeeds_email, u_custom_global, any_args))
          .and(not_enqueue_mail_with(Notify, :merge_when_pipeline_succeeds_email, unsubscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :merge_when_pipeline_succeeds_email, u_disabled, any_args))
      end

      it 'does not send notification if the custom event is disabled' do
        update_custom_notification(:merge_when_pipeline_succeeds, u_guest_custom, resource: project, value: false)
        update_custom_notification(:merge_when_pipeline_succeeds, u_custom_global, resource: nil, value: false)

        expect do
          notification.merge_when_pipeline_succeeds(merge_request, assignee)
        end.to not_enqueue_mail_with(Notify, :merge_when_pipeline_succeeds_email, u_guest_custom, any_args)
          .and(not_enqueue_mail_with(Notify, :merge_when_pipeline_succeeds_email, u_custom_global, any_args))
      end

      it 'sends notification to participants even if the custom event is disabled' do
        update_custom_notification(:merge_when_pipeline_succeeds, merge_request.author, resource: project, value: false)
        update_custom_notification(:merge_when_pipeline_succeeds, u_watcher, resource: project, value: false)
        update_custom_notification(:merge_when_pipeline_succeeds, subscriber, resource: project, value: false)

        expect do
          notification.merge_when_pipeline_succeeds(merge_request, assignee)
        end.to enqueue_mail_with(Notify, :merge_when_pipeline_succeeds_email, merge_request.author, any_args)
          .and(enqueue_mail_with(Notify, :merge_when_pipeline_succeeds_email, u_watcher, any_args))
          .and(enqueue_mail_with(Notify, :merge_when_pipeline_succeeds_email, subscriber, any_args))
      end

      it_behaves_like 'participating notifications' do
        let(:participant) { create(:user, username: 'user-participant') }
        let(:issuable) { merge_request }
        let(:notification_trigger) { notification.merge_when_pipeline_succeeds(merge_request, u_disabled) }
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.merge_when_pipeline_succeeds(merge_request, u_disabled) }
      end
    end

    describe '#review_requested_of_merge_request' do
      let(:merge_request) { create(:merge_request, author: author, source_project: project, reviewers: [reviewer]) }
      let(:mailer) { double }

      let_it_be(:current_user) { create(:user) }
      let_it_be(:reviewer) { create(:user) }

      it 'sends email to reviewer', :aggregate_failures do
        expect do
          notification.review_requested_of_merge_request(merge_request, current_user, reviewer)
        end.to enqueue_mail_with(Notify, :request_review_merge_request_email, reviewer, any_args)
          .and(not_enqueue_mail_with(Notify, :request_review_merge_request_email, merge_request.author, any_args))
          .and(not_enqueue_mail_with(Notify, :request_review_merge_request_email, u_watcher, any_args))
          .and(not_enqueue_mail_with(Notify, :request_review_merge_request_email, u_participant_mentioned, any_args))
          .and(not_enqueue_mail_with(Notify, :request_review_merge_request_email, subscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :request_review_merge_request_email, watcher_and_subscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :request_review_merge_request_email, u_guest_watcher, any_args))
          .and(not_enqueue_mail_with(Notify, :request_review_merge_request_email, u_guest_custom, any_args))
          .and(not_enqueue_mail_with(Notify, :request_review_merge_request_email, u_custom_global, any_args))
          .and(not_enqueue_mail_with(Notify, :request_review_merge_request_email, unsubscriber, any_args))
          .and(not_enqueue_mail_with(Notify, :request_review_merge_request_email, u_participating, any_args))
          .and(not_enqueue_mail_with(Notify, :request_review_merge_request_email, u_disabled, any_args))
          .and(not_enqueue_mail_with(Notify, :request_review_merge_request_email, u_lazy_participant, any_args))
      end

      it 'deliver email immediately' do
        allow(Notify).to receive(:request_review_merge_request_email)
                           .with(Integer, Integer, Integer, String).and_return(mailer)
        expect(mailer).to receive(:deliver_later).with({})

        notification.review_requested_of_merge_request(merge_request, current_user, reviewer)
      end

      it 'adds "review requested" reason for new reviewer', :deliver_mails_inline do
        notification.review_requested_of_merge_request(merge_request, current_user, reviewer)

        merge_request.reviewers.each do |reviewer|
          email = find_email_for(reviewer)

          expect(email).to have_header('X-GitLab-NotificationReason', NotificationReason::REVIEW_REQUESTED)
        end
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { merge_request }
        let(:notification_trigger) { notification.review_requested_of_merge_request(merge_request, current_user, reviewer) }
      end
    end
  end

  describe 'Projects' do
    before_all do
      build_team(project)
      reset_delivered_emails!
    end

    describe '#group_was_transferred' do
      let(:group) { create(:group) }
      let(:owner) { create(:user) }

      before do
        group.add_owner(owner)
        reset_delivered_emails!
      end

      it 'sends email to group owners and maintainers' do
        expect do
          notification.group_was_transferred(group, 'old-path')
        end.to enqueue_mail_with(Notify, :group_was_transferred_email, group, owner, any_args)
      end

      context 'when group emails are disabled' do
        before do
          allow(group).to receive(:emails_disabled?).and_return(true)
        end

        it 'does not send any emails' do
          expect do
            notification.group_was_transferred(group, 'old-path')
          end.not_to have_enqueued_mail(Notify, :group_was_transferred_email)
        end
      end

      context 'when user has moved_project notification disabled' do
        before do
          owner.notification_settings_for(nil).update!(level: :custom, moved_project: false)
          reset_delivered_emails!
        end

        it 'does not send email' do
          expect do
            notification.group_was_transferred(group, 'old-path')
          end.to not_enqueue_mail_with(Notify, :group_was_transferred_email, group, owner, any_args)
        end
      end

      context 'when group has no direct members but has a parent' do
        let(:parent_group) { create(:group) }
        let(:parent_owner) { create(:user) }
        let(:child_group) { create(:group, parent: parent_group) }

        before do
          parent_group.add_owner(parent_owner)
          reset_delivered_emails!
        end

        it 'falls back to parent group members' do
          expect do
            notification.group_was_transferred(child_group, 'old-path')
          end.to enqueue_mail_with(Notify, :group_was_transferred_email, child_group, parent_owner, any_args)
        end
      end

      context 'when group has no members and no parent' do
        let(:empty_group) { create(:group) }

        it 'does not send any emails' do
          notification.group_was_transferred(empty_group, 'old-path')

          expect_no_delivery_jobs
        end
      end
    end

    describe '#project_was_moved' do
      context 'when notifications are disabled' do
        before do
          u_custom_global.global_notification_setting.update!(moved_project: false)
        end

        it 'does not send a notification' do
          expect do
            notification.project_was_moved(project, "gitlab/gitlab")
          end.to not_enqueue_mail_with(Notify, :project_was_moved_email, project, u_custom_global, any_args)
        end
      end

      context 'with users at both project and group level' do
        let(:maintainer) { create(:user) }
        let(:developer) { create(:user) }
        let(:group_owner) { create(:user) }
        let(:group_maintainer) { create(:user) }
        let(:group_developer) { create(:user) }
        let(:invited_user) { create(:user) }

        let!(:group) do
          create(:group, :public) do |group|
            project.group = group
            project.save!

            group.add_owner(group_owner)
            group.add_maintainer(group_maintainer)
            group.add_developer(group_developer)
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
          expect do
            notification.project_was_moved(project, "gitlab/gitlab")
          end.to enqueue_mail_with(Notify, :project_was_moved_email, project, u_watcher, any_args)
            .and(enqueue_mail_with(Notify, :project_was_moved_email, project, u_participating, any_args))
            .and(enqueue_mail_with(Notify, :project_was_moved_email, project, u_lazy_participant, any_args))
            .and(enqueue_mail_with(Notify, :project_was_moved_email, project, u_custom_global, any_args))
            .and(not_enqueue_mail_with(Notify, :project_was_moved_email, project, u_guest_watcher, any_args))
            .and(not_enqueue_mail_with(Notify, :project_was_moved_email, project, u_guest_custom, any_args))
            .and(not_enqueue_mail_with(Notify, :project_was_moved_email, project, u_disabled, any_args))
            .and(enqueue_mail_with(Notify, :project_was_moved_email, project, maintainer, any_args))
            .and(enqueue_mail_with(Notify, :project_was_moved_email, project, group_owner, any_args))
            .and(enqueue_mail_with(Notify, :project_was_moved_email, project, group_maintainer, any_args))
            .and(not_enqueue_mail_with(Notify, :project_was_moved_email, project, group_developer, any_args))
            .and(not_enqueue_mail_with(Notify, :project_was_moved_email, project, developer, any_args))
            .and(not_enqueue_mail_with(Notify, :project_was_moved_email, project, blocked_user, any_args))
        end
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { project }
        let(:notification_trigger) { notification.project_was_moved(project, "gitlab/gitlab") }
      end

      context 'users not having access to the new location' do
        it 'does not send email' do
          old_user = create(:user)
          ProjectAuthorization.create!(project: project, user: old_user, access_level: Gitlab::Access::GUEST)

          move_to_child_group(project)
          reset_delivered_emails!

          expect do
            notification.project_was_moved(project, "gitlab/gitlab")
          end.to enqueue_mail_with(Notify, :project_was_moved_email, project, g_watcher, any_args)
            .and(enqueue_mail_with(Notify, :project_was_moved_email, project, g_global_watcher, any_args))
            .and(enqueue_mail_with(Notify, :project_was_moved_email, project, project.creator, any_args))
            .and(not_enqueue_mail_with(Notify, :project_was_moved_email, project, old_user, any_args))
        end
      end
    end

    context 'user with notifications disabled' do
      describe '#project_exported' do
        it do
          notification.project_exported(project, u_disabled)

          expect_no_delivery_jobs
        end
      end

      describe '#project_not_exported' do
        it do
          notification.project_not_exported(project, u_disabled, ['error'])

          expect_no_delivery_jobs
        end
      end
    end

    context 'user with notifications enabled' do
      describe '#project_exported' do
        it do
          expect do
            notification.project_exported(project, u_participating)
          end.to enqueue_mail_with(Notify, :project_was_exported_email, u_participating, project)
        end

        it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
          let(:notification_target)  { project }
          let(:notification_trigger) { notification.project_exported(project, u_participating) }
        end
      end

      describe '#project_not_exported' do
        it do
          expect do
            notification.project_not_exported(project, u_participating, ['error'])
          end.to enqueue_mail_with(Notify, :project_was_not_exported_email, u_participating, project, any_args)
        end

        it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
          let(:notification_target)  { project }
          let(:notification_trigger) { notification.project_not_exported(project, u_participating, ['error']) }
        end
      end
    end
  end

  describe '#new_instance_access_request' do
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

      expect_delivery_jobs_count(10)
      ten_most_recently_active_instance_admins.each do |admin|
        expect_enqueud_email(user, admin, mail: "instance_access_request_email")
      end
    end
  end

  describe '#user_admin_rejection' do
    let_it_be(:user) { create(:user, :blocked_pending_approval) }

    before do
      reset_delivered_emails!
    end

    it 'sends the user a rejection email' do
      expect do
        notification.user_admin_rejection(user.name, user.email)
      end.to enqueue_mail_with(Notify, :user_admin_rejection_email, user.name, user.email)
    end
  end

  describe '#user_deactivated' do
    let_it_be(:user) { create(:user) }

    it 'sends the user an email' do
      expect do
        notification.user_deactivated(user.name, user.notification_email_or_default)
      end.to enqueue_mail_with(Notify, :user_deactivated_email, user.name, user.notification_email_or_default)
    end
  end

  describe 'GroupMember' do
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
          expect do
            group.request_access(added_user)
          end.to enqueue_mail_with(Members::AccessRequestedMailer, :email, any_args)

          expect(ActionMailer::MailDeliveryJob).to have_been_enqueued.once
        end

        it_behaves_like 'group emails are disabled', check_delivery_jobs_queue: true do
          let(:notification_target)  { group }
          let(:notification_trigger) { group.request_access(added_user) }

          before do
            group.update_attribute(:emails_enabled, false)
          end
        end
      end

      it_behaves_like 'sends access request notification to a max of ten, most recently active group owners' do
        let(:group) { create(:group, :public) }
        let(:notification_trigger) { group.request_access(added_user) }
      end
    end
  end

  describe 'ProjectMember' do
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
            expect do
              project.request_access(added_user)
            end.to have_enqueued_mail(Members::AccessRequestedMailer, :email).at_least(:once)
          end

          it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
            let(:notification_target)  { project }
            let(:notification_trigger) { project.request_access(added_user) }

            before do
              project.project_setting.update_attribute(:emails_enabled, false)
            end
          end
        end

        it_behaves_like 'sends access request notification to a max of ten, most recently active project maintainers' do
          let(:notification_trigger) { project.request_access(added_user) }
        end
      end

      context 'for a project in a group' do
        let(:group_owner) { create(:user) }
        let(:group) { create(:group, owners: group_owner) }

        context 'when the project has no maintainers' do
          context 'when the group has at least one owner' do
            let!(:project) { create(:project, :public, namespace: group) }

            before do
              reset_delivered_emails!
            end

            context 'recipients' do
              it 'sends notifications to the group owners' do
                expect do
                  project.request_access(added_user)
                end.to enqueue_mail_with(Members::AccessRequestedMailer, :email, any_args)

                expect(ActionMailer::MailDeliveryJob).to have_been_enqueued.once
              end
            end

            it_behaves_like 'sends access request notification to a max of ten, most recently active group owners' do
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

                expect_no_delivery_jobs
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
              expect do
                project.request_access(added_user)
              end.to enqueue_mail_with(Members::AccessRequestedMailer, :email, any_args)

              expect(ActionMailer::MailDeliveryJob).to have_been_enqueued.once
            end
          end

          it_behaves_like 'sends access request notification to a max of ten, most recently active project maintainers' do
            let(:project) { create(:project, :public, namespace: group) }
            let(:notification_trigger) { project.request_access(added_user) }
          end
        end
      end
    end
  end

  context 'guest user in private project' do
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

      reset_delivered_emails!
    end

    it 'filters out guests when new note is created' do
      expect do
        notification.new_note(note)
      end.to not_enqueue_mail_with(Notify, :note_merge_request_email, guest, any_args)
        .and(enqueue_mail_with(Notify, :note_merge_request_email, assignee, any_args))
    end

    it 'filters out guests when new merge request is created' do
      expect do
        notification.new_merge_request(merge_request1, developer)
      end.to not_enqueue_mail_with(Notify, :new_merge_request_email, guest, any_args)
        .and(enqueue_mail_with(Notify, :new_merge_request_email, assignee, any_args))
    end

    it 'filters out guests when merge request is closed' do
      expect do
        notification.close_mr(merge_request, developer)
      end.to not_enqueue_mail_with(Notify, :closed_merge_request_email, guest, any_args)
        .and(enqueue_mail_with(Notify, :closed_merge_request_email, assignee, any_args))
    end

    it 'filters out guests when merge request is reopened' do
      expect do
        notification.reopen_mr(merge_request, developer)
      end.to not_enqueue_mail_with(Notify, :merge_request_status_email, guest, any_args)
        .and(enqueue_mail_with(Notify, :merge_request_status_email, assignee, any_args))
    end

    it 'filters out guests when merge request is merged' do
      expect do
        notification.merge_mr(merge_request, developer)
      end.to not_enqueue_mail_with(Notify, :merged_merge_request_email, guest, any_args)
        .and(enqueue_mail_with(Notify, :merged_merge_request_email, assignee, any_args))
    end
  end

  describe 'Pipelines' do
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
        create(
          :ci_pipeline, status,
          project: project,
          user: user,
          ref: 'refs/heads/master',
          sha: commit.id,
          before_sha: '00000000'
        )
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
          it 'notifies nobody' do
            pipeline = create_pipeline(u_member, :success)
            notification.pipeline_finished(pipeline)
            expect_no_delivery_jobs
          end
        end

        context 'when the creator has watch set' do
          it 'notifies nobody' do
            pipeline = create_pipeline(u_watcher, :success)
            notification.pipeline_finished(pipeline)
            expect_no_delivery_jobs
          end
        end

        context 'when the creator has custom notifications, but without any set' do
          it 'notifies nobody' do
            pipeline = create_pipeline(u_custom_notification_unset, :success)
            notification.pipeline_finished(pipeline)
            expect_no_delivery_jobs
          end
        end

        context 'when the creator has custom notifications disabled' do
          it 'notifies nobody' do
            pipeline = create_pipeline(u_custom_notification_disabled, :success)
            notification.pipeline_finished(pipeline)
            expect_no_delivery_jobs
          end
        end

        context 'when the creator has custom notifications enabled' do
          let(:pipeline) { create_pipeline(u_custom_notification_enabled, :success) }

          it 'emails only the creator' do
            expect do
              notification.pipeline_finished(pipeline)
            end.to have_only_enqueued_mail_with_args(Notify, :pipeline_success_email, [a_kind_of(Ci::Pipeline), u_custom_notification_enabled.email])
          end

          it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
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
              expect do
                notification.pipeline_finished(pipeline)
              end.to have_enqueued_mail(Notify, :pipeline_success_email).with(a_kind_of(Ci::Pipeline), group_notification_email)
            end
          end
        end
      end

      context 'with a failed pipeline' do
        context 'when the creator has no custom notification set' do
          let(:pipeline) { create_pipeline(u_member, :failed) }

          it 'emails only the creator' do
            expect do
              notification.pipeline_finished(pipeline)
            end.to have_only_enqueued_mail_with_args(Notify, :pipeline_failed_email, [a_kind_of(Ci::Pipeline), u_member.email])
          end

          it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
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
              expect do
                notification.pipeline_finished(pipeline)
              end.to have_enqueued_mail(Notify, :pipeline_failed_email).with(a_kind_of(Ci::Pipeline), group_notification_email)
            end
          end
        end

        context 'when the creator has watch set' do
          it 'emails only the creator' do
            pipeline = create_pipeline(u_watcher, :failed)
            expect do
              notification.pipeline_finished(pipeline)
            end.to have_only_enqueued_mail_with_args(Notify, :pipeline_failed_email, [a_kind_of(Ci::Pipeline), u_watcher.email])
          end
        end

        context 'when the creator has custom notifications, but without any set' do
          it 'emails only the creator' do
            pipeline = create_pipeline(u_custom_notification_unset, :failed)
            expect do
              notification.pipeline_finished(pipeline)
            end.to have_only_enqueued_mail_with_args(Notify, :pipeline_failed_email, [a_kind_of(Ci::Pipeline), u_custom_notification_unset.email])
          end
        end

        context 'when the creator has custom notifications disabled' do
          it 'notifies nobody' do
            pipeline = create_pipeline(u_custom_notification_disabled, :failed)
            notification.pipeline_finished(pipeline)
            expect_no_delivery_jobs
          end
        end

        context 'when the creator has custom notifications set' do
          it 'emails only the creator' do
            pipeline = create_pipeline(u_custom_notification_enabled, :failed)
            expect do
              notification.pipeline_finished(pipeline)
            end.to have_only_enqueued_mail_with_args(Notify, :pipeline_failed_email, [a_kind_of(Ci::Pipeline), u_custom_notification_enabled.email])
          end
        end

        context 'when the creator has no read_build access' do
          it 'does not send emails', :sidekiq_inline do
            pipeline = create_pipeline(u_member, :failed)
            project.update!(public_builds: false)
            project.team.truncate
            notification.pipeline_finished(pipeline)
            expect_no_delivery_jobs
          end
        end
      end

      context 'with a fixed pipeline' do
        let(:ref_status) { 'fixed' }

        context 'when the creator has no custom notification set' do
          let(:pipeline) { create_pipeline(u_member, :success) }

          it 'emails only the creator' do
            expect do
              notification.pipeline_finished(pipeline, ref_status: ref_status)
            end.to have_only_enqueued_mail_with_args(Notify, :pipeline_fixed_email, [a_kind_of(Ci::Pipeline), u_member.email])
          end

          it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
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
              expect do
                notification.pipeline_finished(pipeline, ref_status: ref_status)
              end.to have_enqueued_mail(Notify, :pipeline_fixed_email).with(a_kind_of(Ci::Pipeline), group_notification_email)
            end
          end
        end

        context 'when the creator has watch set' do
          it 'emails only the creator' do
            pipeline = create_pipeline(u_watcher, :success)
            expect do
              notification.pipeline_finished(pipeline, ref_status: ref_status)
            end.to have_only_enqueued_mail_with_args(Notify, :pipeline_fixed_email, [a_kind_of(Ci::Pipeline), u_watcher.email])
          end
        end

        context 'when the creator has custom notifications, but without any set' do
          it 'emails only the creator' do
            pipeline = create_pipeline(u_custom_notification_unset, :success)
            expect do
              notification.pipeline_finished(pipeline, ref_status: ref_status)
            end.to have_only_enqueued_mail_with_args(Notify, :pipeline_fixed_email, [a_kind_of(Ci::Pipeline), u_custom_notification_unset.email])
          end
        end

        context 'when the creator has custom notifications disabled' do
          it 'notifies nobody' do
            pipeline = create_pipeline(u_custom_notification_disabled, :success)
            notification.pipeline_finished(pipeline, ref_status: ref_status)
            expect_no_delivery_jobs
          end
        end

        context 'when the creator has custom notifications set' do
          it 'emails only the creator' do
            pipeline = create_pipeline(u_custom_notification_enabled, :success)
            expect do
              notification.pipeline_finished(pipeline, ref_status: ref_status)
            end.to have_only_enqueued_mail_with_args(Notify, :pipeline_fixed_email, [a_kind_of(Ci::Pipeline), u_custom_notification_enabled.email])
          end
        end
      end
    end
  end

  describe 'Pages domains' do
    let_it_be(:project, reload: true) { create(:project) }
    let_it_be(:domain, reload: true) { create(:pages_domain, project: project) }
    let_it_be(:u_blocked) { blocked_user }
    let_it_be(:u_silence) { create_user_with_notification(:disabled, 'silent', project) }
    let_it_be(:u_owner) { project.first_owner }
    let_it_be(:u_maintainer1) { create(:user) }
    let_it_be(:u_maintainer2) { create(:user) }
    let_it_be(:u_developer) { create(:user) }

    before do
      project.add_maintainer(u_blocked)
      project.add_maintainer(u_silence)
      project.add_maintainer(u_maintainer1)
      project.add_maintainer(u_maintainer2)
      project.add_developer(u_developer)
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

        it 'emails current watching maintainers and owners' do
          expect do
            notify!
          end.to have_only_enqueued_mail_with_args(
            Notify,
            :"#{sym}_email",
            [domain, u_maintainer1],
            [domain, u_maintainer2],
            [domain, u_owner]
          )
        end

        it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
          let(:notification_target)  { domain }
          let(:notification_trigger) { notify! }
        end

        it 'emails nobody if the project is missing' do
          domain.project = nil

          expect do
            notify!
          end.not_to have_enqueued_email(Notify, :"#{sym}_email")
        end
      end
    end
  end

  context 'Auto DevOps notifications' do
    describe '#autodevops_disabled' do
      let(:owner) { create(:user) }
      let(:namespace) { create(:namespace, owner: owner) }
      let(:project) { create(:project, :repository, :auto_devops, namespace: namespace) }
      let(:pipeline_user) { create(:user) }
      let(:pipeline) { create(:ci_pipeline, :failed, project: project, user: pipeline_user) }

      it 'emails project owner and user that triggered the pipeline' do
        project.add_developer(pipeline_user)

        expect do
          notification.autodevops_disabled(pipeline, [owner.email, pipeline_user.email])
        end.to have_enqueued_mail(Notify, :autodevops_disabled_email).with(a_kind_of(Ci::Pipeline), owner.email)
          .and(have_enqueued_mail(Notify, :autodevops_disabled_email).with(a_kind_of(Ci::Pipeline), pipeline_user.email))
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { project }
        let(:notification_trigger) { notification.autodevops_disabled(pipeline, [owner.email, pipeline_user.email]) }
      end
    end
  end

  describe 'Repository rewrite history' do
    let(:user) { create(:user) }

    describe '#repository_rewrite_history_success' do
      it 'emails the specified user only' do
        expect do
          notification.repository_rewrite_history_success(project, user)
        end.to enqueue_mail_with(Notify, :repository_rewrite_history_success_email, project, user)
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { project }
        let(:notification_trigger) { notification.repository_rewrite_history_success(project, user) }
      end
    end

    describe '#repository_rewrite_history_failure' do
      it 'emails the specified user only' do
        expect do
          notification.repository_rewrite_history_failure(project, user, 'Some error')
        end.to enqueue_mail_with(Notify, :repository_rewrite_history_failure_email, project, user, any_args)
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { project }
        let(:notification_trigger) { notification.repository_rewrite_history_failure(project, user, 'Some error') }
      end
    end
  end

  describe 'Repository cleanup' do
    let(:user) { create(:user) }

    describe '#repository_cleanup_success' do
      it 'emails the specified user only' do
        expect do
          notification.repository_cleanup_success(project, user)
        end.to enqueue_mail_with(Notify, :repository_cleanup_success_email, project, user)
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { project }
        let(:notification_trigger) { notification.repository_cleanup_success(project, user) }
      end
    end

    describe '#repository_cleanup_failure' do
      it 'emails the specified user only' do
        expect do
          notification.repository_cleanup_failure(project, user, 'Some error')
        end.to enqueue_mail_with(Notify, :repository_cleanup_failure_email, project, user, any_args)
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { project }
        let(:notification_trigger) { notification.repository_cleanup_failure(project, user, 'Some error') }
      end
    end
  end

  context 'Remote mirror notifications' do
    describe '#remote_mirror_update_failed' do
      let(:remote_mirror) { create(:remote_mirror, project: project) }
      let(:u_blocked) { blocked_user }
      let(:u_silence) { create_user_with_notification(:disabled, 'silent-maintainer', project) }
      let(:u_owner)   { project.first_owner }
      let(:u_maintainer1) { create(:user) }
      let(:u_maintainer2) { create(:user) }
      let(:u_developer) { create(:user) }

      before do
        project.add_maintainer(u_blocked)
        project.add_maintainer(u_silence)
        project.add_maintainer(u_maintainer1)
        project.add_maintainer(u_maintainer2)
        project.add_developer(u_developer)

        reset_delivered_emails!
      end

      it 'emails current watching maintainers and owners' do
        expect do
          notification.remote_mirror_update_failed(remote_mirror)
        end.to have_only_enqueued_mail_with_args(
          Notify,
          :remote_mirror_update_failed_email,
          [remote_mirror.id, u_maintainer1.id],
          [remote_mirror.id, u_maintainer2.id],
          [remote_mirror.id, u_owner.id]
        )
      end

      it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
        let(:notification_target)  { project }
        let(:notification_trigger) { notification.remote_mirror_update_failed(remote_mirror) }
      end
    end
  end

  context 'with external authorization service and a specified project' do
    let(:issue) { create(:issue) }
    let(:project) { issue.project }
    let(:note) { create(:note, noteable: issue, project: project) }
    let(:member) { create(:user) }

    subject { described_class.new }

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

      it 'checks external auth and sends an email if successful' do
        expect(::Gitlab::ExternalAuthorization).to receive(:access_allowed?).at_least(:once).with(anything, "default_label", any_args).and_return(true)
        expect(Notify).to receive(:new_issue_email).at_least(:once).with(member.id, issue.id, nil).and_call_original

        subject.new_issue(issue, member)
      end

      it 'checks external auth and does not send an email if denied' do
        expect(::Gitlab::ExternalAuthorization).to receive(:access_allowed?).at_least(:once).with(anything, "default_label", any_args).and_return(false)
        expect(Notify).not_to receive(:new_issue_email)

        subject.new_issue(issue, member)
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
      expect(Notify).to receive(:prometheus_alert_fired_email).with(project, project.first_owner, alert).and_call_original
      expect(Notify).not_to receive(:prometheus_alert_fired_email).with(project, developer, alert)

      subject.prometheus_alerts_fired(project, [alert])
    end

    it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
      let(:notification_target)  { project }
      let(:notification_trigger) { subject.prometheus_alerts_fired(project, [alert]) }
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

      create(
        :diff_note_on_merge_request,
        project: project,
        noteable: merge_request,
        author: reviewer,
        review: review,
        note: "cc @mention"
      )
    end

    it 'sends emails' do
      expect(Notify).not_to receive(:new_review_email).with(review.author.id, review.id)
      expect(Notify).not_to receive(:new_review_email).with(unsubscriber.id, review.id)
      merge_request.assignee_ids.each do |assignee_id|
        expect(Notify).to receive(:new_review_email).with(assignee_id, review.id).and_call_original
      end
      expect(Notify).to receive(:new_review_email).with(merge_request.author.id, review.id).and_call_original
      expect(Notify).to receive(:new_review_email).with(u_watcher.id, review.id).and_call_original
      expect(Notify).to receive(:new_review_email).with(u_mentioned.id, review.id).and_call_original
      expect(Notify).to receive(:new_review_email).with(subscriber.id, review.id).and_call_original
      expect(Notify).to receive(:new_review_email).with(watcher_and_subscriber.id, review.id).and_call_original
      expect(Notify).to receive(:new_review_email).with(subscribed_participant.id, review.id).and_call_original

      subject.new_review(review)
    end

    it_behaves_like 'project emails are disabled', check_delivery_jobs_queue: true do
      let(:notification_target)  { review }
      let(:notification_trigger) { subject.new_review(review) }
    end
  end

  describe '#inactive_project_deletion_warning' do
    let_it_be(:deletion_date) { Date.current }
    let_it_be(:project) { create(:project) }
    let_it_be(:maintainer) { create(:user) }
    let_it_be(:developer) { create(:user) }

    before do
      project.add_maintainer(maintainer)
    end

    subject { notification.inactive_project_deletion_warning(project, deletion_date) }

    it "sends email to project owners and maintainers" do
      expect { subject }.to have_enqueued_email(
        project,
        maintainer,
        deletion_date,
        mail: "inactive_project_deletion_warning_email"
      )
      expect { subject }.not_to have_enqueued_email(
        project,
        developer,
        deletion_date,
        mail: "inactive_project_deletion_warning_email"
      )
    end
  end

  describe 'project scheduled for deletion' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }

    context 'when project emails are disabled' do
      before do
        allow(project).to receive(:emails_disabled?).and_return(true)
      end

      it 'does not send any emails' do
        expect(Notify).not_to receive(:project_scheduled_for_deletion)

        subject.project_scheduled_for_deletion(project)
      end
    end

    context 'when project emails are enabled' do
      before do
        allow(project).to receive(:emails_disabled?).and_return(false)
      end

      context 'when user is owner' do
        it 'sends email' do
          expect(Notify).to receive(:project_scheduled_for_deletion).with(project.first_owner.id, project.id).and_call_original

          subject.project_scheduled_for_deletion(project)
        end

        context 'when owner is blocked' do
          it 'does not send email' do
            project.owner.block!

            expect(Notify).not_to receive(:project_scheduled_for_deletion)

            subject.project_scheduled_for_deletion(project)
          end
        end
      end

      context 'when project has multiple owners' do
        it 'sends email to all owners' do
          project.add_owner(user)

          expect(Notify).to receive(:project_scheduled_for_deletion).with(project.first_owner.id, project.id).and_call_original
          expect(Notify).to receive(:project_scheduled_for_deletion).with(user.id, project.id).and_call_original

          subject.project_scheduled_for_deletion(project)
        end
      end

      context 'when project has no direct owners but belongs to a group with owners' do
        let_it_be(:group) { create(:group) }
        let_it_be(:project) { create(:project, group: group) }
        let_it_be(:group_owner) { create(:user) }

        before do
          group.add_owner(group_owner)
          # Ensure project has no direct owners
          project.members.owners.delete_all if project.members.owners.any?
        end

        it 'sends email to group owners' do
          expect(Notify).to receive(:project_scheduled_for_deletion).with(group_owner.id, project.id).and_call_original

          subject.project_scheduled_for_deletion(project)
        end
      end
    end
  end

  describe 'group scheduled for deletion' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }

    context 'when group emails are disabled' do
      before do
        allow(group).to receive(:emails_disabled?).and_return(true)
      end

      it 'does not send any emails' do
        expect(Notify).not_to receive(:group_scheduled_for_deletion)

        subject.group_scheduled_for_deletion(group)
      end
    end

    context 'when group emails are enabled' do
      before do
        allow(group).to receive(:emails_disabled?).and_return(false)
      end

      context 'when user is owner' do
        it 'sends email' do
          group.add_owner(user)

          expect(Notify).to receive(:group_scheduled_for_deletion).with(user.id, group.id).and_call_original

          subject.group_scheduled_for_deletion(group)
        end

        context 'when owner is blocked' do
          it 'does not send email' do
            group.add_owner(user)
            user.block!

            expect(Notify).not_to receive(:group_scheduled_for_deletion)

            subject.group_scheduled_for_deletion(group)
          end
        end
      end

      context 'when group has multiple owners' do
        let_it_be(:another_user) { create(:user) }

        it 'sends email to all owners' do
          group.add_owner(user)
          group.add_owner(another_user)

          expect(Notify).to receive(:group_scheduled_for_deletion).with(user.id, group.id).and_call_original
          expect(Notify).to receive(:group_scheduled_for_deletion).with(another_user.id, group.id).and_call_original

          subject.group_scheduled_for_deletion(group)
        end
      end
    end
  end

  def build_team(project)
    create_notification_setting(u_guest_watcher, project, :watch)
    create_notification_setting(u_guest_custom, project, :custom)

    project.add_maintainer(u_watcher)
    project.add_maintainer(u_participating)
    project.add_maintainer(u_participant_mentioned)
    project.add_maintainer(u_disabled)
    project.add_maintainer(u_mentioned)
    project.add_maintainer(u_committer)
    project.add_maintainer(u_not_mentioned)
    project.add_maintainer(u_lazy_participant)
    project.add_maintainer(u_custom_global)
  end

  def move_to_child_group(project)
    project.update!(namespace_id: child_group.id)
  end

  def add_member_for_parent_group(user, project)
    project.reload

    project.group.parent.add_maintainer(user)
  end

  def add_users(project)
    project.add_maintainer(subscribed_participant)
    project.add_maintainer(subscriber)
    project.add_maintainer(unsubscriber)
    project.add_maintainer(watcher_and_subscriber)
    project.add_maintainer(unsubscribed_mentioned)
  end

  def add_user_subscriptions(issuable)
    issuable.subscriptions.create!(user: unsubscribed_mentioned, project: project, subscribed: false)
    issuable.subscriptions.create!(user: subscriber, project: project, subscribed: true)
    issuable.subscriptions.create!(user: subscribed_participant, project: project, subscribed: true)
    issuable.subscriptions.create!(user: unsubscriber, project: project, subscribed: false)
    # Make the watcher a subscriber to detect dupes
    issuable.subscriptions.create!(user: watcher_and_subscriber, project: project, subscribed: true)
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
