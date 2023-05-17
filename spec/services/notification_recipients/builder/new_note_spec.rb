# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotificationRecipients::Builder::NewNote, feature_category: :team_planning do
  describe '#notification_recipients' do
    let_it_be(:group)   { create(:group, :public) }
    let_it_be(:project) { create(:project, :public, group: group) }
    let_it_be(:issue) { create(:issue, project: project) }

    let_it_be(:other_user)              { create(:user) }
    let_it_be(:participant)             { create(:user) }
    let_it_be(:non_member_participant)  { create(:user) }
    let_it_be(:group_watcher)           { create(:user) }
    let_it_be(:project_watcher)         { create(:user) }
    let_it_be(:guest_project_watcher)   { create(:user) }
    let_it_be(:subscriber)              { create(:user) }
    let_it_be(:unsubscribed_user)       { create(:user) }
    let_it_be(:non_member_subscriber)   { create(:user) }

    let_it_be(:notification_setting_project_w) { create(:notification_setting, source: project, user: project_watcher, level: 2) }
    let_it_be(:notification_setting_guest_w) { create(:notification_setting, source: project, user: guest_project_watcher, level: 2) }
    let_it_be(:notification_setting_group_w) { create(:notification_setting, source: group, user: group_watcher, level: 2) }
    let_it_be(:subscriptions) do
      [
        create(:subscription, project: project, user: subscriber, subscribable: issue, subscribed: true),
        create(:subscription, project: project, user: unsubscribed_user, subscribable: issue, subscribed: false),
        create(:subscription, project: project, user: non_member_subscriber, subscribable: issue, subscribed: true)
      ]
    end

    subject { described_class.new(note) }

    before do
      project.add_developer(participant)
      project.add_developer(project_watcher)
      project.add_guest(guest_project_watcher)
      project.add_developer(subscriber)
      group.add_developer(group_watcher)

      expect(issue).to receive(:participants).and_return([participant, non_member_participant])
    end

    context 'for public notes' do
      let_it_be(:note) { create(:note, noteable: issue, project: project) }

      it 'adds all participants, watchers and subscribers' do
        expect(subject.notification_recipients.map(&:user)).to contain_exactly(
          participant, non_member_participant, project_watcher, group_watcher, guest_project_watcher, subscriber, non_member_subscriber
        )
      end
    end

    context 'for confidential notes' do
      let_it_be(:note) { create(:note, :confidential, noteable: issue, project: project) }

      it 'adds all participants, watchers and subscribers that are project memebrs' do
        expect(subject.notification_recipients.map(&:user)).to contain_exactly(
          participant, project_watcher, group_watcher, subscriber
        )
      end
    end
  end
end
