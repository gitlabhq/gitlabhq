# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotificationRecipients::Builder::Default do
  describe '#build!' do
    let_it_be(:group)   { create(:group, :public) }
    let_it_be(:project) { create(:project, :public, group: group).tap { |p| p.add_developer(project_watcher) } }
    let_it_be(:issue)   { create(:issue, project: project) }

    let_it_be(:current_user)    { create(:user) }
    let_it_be(:other_user)      { create(:user) }
    let_it_be(:participant)     { create(:user) }
    let_it_be(:group_watcher)   { create(:user) }
    let_it_be(:project_watcher) { create(:user) }

    let_it_be(:notification_setting_project_w) { create(:notification_setting, source: project, user: project_watcher, level: 2) }
    let_it_be(:notification_setting_group_w) { create(:notification_setting, source: group, user: group_watcher, level: 2) }

    subject { described_class.new(issue, current_user, action: :new).tap { |s| s.build! } }

    context 'participants and project watchers' do
      before do
        expect(issue).to receive(:participants).and_return([participant, current_user])
      end

      it 'adds all participants and watchers' do
        expect(subject.recipients.map(&:user)).to include(participant, project_watcher, group_watcher)
        expect(subject.recipients.map(&:user)).not_to include(other_user)
      end
    end

    context 'subscribers' do
      it 'adds all subscribers' do
        subscriber = create(:user)
        non_subscriber = create(:user)
        create(:subscription, project: project, user: subscriber, subscribable: issue, subscribed: true)
        create(:subscription, project: project, user: non_subscriber, subscribable: issue, subscribed: false)

        expect(subject.recipients.map(&:user)).to include(subscriber)
      end
    end
  end
end
