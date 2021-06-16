# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotificationRecipients::Builder::Default do
  describe '#build!' do
    let_it_be(:group)   { create(:group, :public) }
    let_it_be(:project) { create(:project, :public, group: group).tap { |p| p.add_developer(project_watcher) } }
    let_it_be(:target)  { create(:issue, project: project) }

    let_it_be(:current_user)    { create(:user) }
    let_it_be(:other_user)      { create(:user) }
    let_it_be(:participant)     { create(:user) }
    let_it_be(:group_watcher)   { create(:user) }
    let_it_be(:project_watcher) { create(:user) }

    let_it_be(:notification_setting_project_w) { create(:notification_setting, source: project, user: project_watcher, level: 2) }
    let_it_be(:notification_setting_group_w) { create(:notification_setting, source: group, user: group_watcher, level: 2) }

    subject { described_class.new(target, current_user, action: :new).tap { |s| s.build! } }

    context 'participants and project watchers' do
      before do
        expect(target).to receive(:participants).and_return([participant, current_user])
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
        create(:subscription, project: project, user: subscriber, subscribable: target, subscribed: true)
        create(:subscription, project: project, user: non_subscriber, subscribable: target, subscribed: false)

        expect(subject.recipients.map(&:user)).to include(subscriber)
      end
    end

    context 'custom notifications' do
      shared_examples 'custom notification recipients' do
        let_it_be(:custom_notification_user) { create(:user) }
        let_it_be(:another_group)   { create(:group) }
        let_it_be(:another_project) { create(:project, namespace: another_group) }

        context 'with project custom notification setting' do
          before do
            create(:notification_setting, source: project, user: custom_notification_user, level: :custom)
          end

          it 'adds the user to the recipients' do
            expect(subject.recipients.map(&:user)).to include(custom_notification_user)
          end
        end

        context 'with the project custom notification setting in another project' do
          before do
            create(:notification_setting, source: another_project, user: custom_notification_user, level: :custom)
          end

          it 'does not add the user to the recipients' do
            expect(subject.recipients.map(&:user)).not_to include(custom_notification_user)
          end
        end

        context 'with group custom notification setting' do
          before do
            create(:notification_setting, source: group, user: custom_notification_user, level: :custom)
          end

          it 'adds the user to the recipients' do
            expect(subject.recipients.map(&:user)).to include(custom_notification_user)
          end
        end

        context 'with the group custom notification setting in another group' do
          before do
            create(:notification_setting, source: another_group, user: custom_notification_user, level: :custom)
          end

          it 'does not add the user to the recipients' do
            expect(subject.recipients.map(&:user)).not_to include(custom_notification_user)
          end
        end

        context 'with project global custom notification setting' do
          before do
            create(:notification_setting, source: project, user: custom_notification_user, level: :global)
          end

          context 'with global custom notification setting' do
            before do
              create(:notification_setting, source: nil, user: custom_notification_user, level: :custom)
            end

            it 'adds the user to the recipients' do
              expect(subject.recipients.map(&:user)).to include(custom_notification_user)
            end
          end

          context 'without global custom notification setting' do
            it 'does not add the user to the recipients' do
              expect(subject.recipients.map(&:user)).not_to include(custom_notification_user)
            end
          end
        end

        context 'with group global custom notification setting' do
          before do
            create(:notification_setting, source: group, user: custom_notification_user, level: :global)
          end

          context 'with global custom notification setting' do
            before do
              create(:notification_setting, source: nil, user: custom_notification_user, level: :custom)
            end

            it 'adds the user to the recipients' do
              expect(subject.recipients.map(&:user)).to include(custom_notification_user)
            end
          end

          context 'without global custom notification setting' do
            it 'does not add the user to the recipients' do
              expect(subject.recipients.map(&:user)).not_to include(custom_notification_user)
            end
          end
        end

        context 'with group custom notification setting in deeply nested parent group' do
          let(:grand_parent_group) { create(:group, :public) }
          let(:parent_group) { create(:group, :public, parent: grand_parent_group) }
          let(:group) { create(:group, :public, parent: parent_group) }
          let(:project) { create(:project, :public, group: group).tap { |p| p.add_developer(project_watcher) } }
          let(:target) { create(:issue, project: project) }

          before do
            create(:notification_setting, source: grand_parent_group, user: custom_notification_user, level: :custom)
          end

          it 'adds the user to the recipients' do
            expect(subject.recipients.map(&:user)).to include(custom_notification_user)
          end
        end

        context 'without a project or group' do
          let(:target) { create(:snippet) }

          before do
            create(:notification_setting, source: nil, user: custom_notification_user, level: :custom)
          end

          it 'does not add the user to the recipients' do
            expect(subject.recipients.map(&:user)).not_to include(custom_notification_user)
          end
        end
      end

      it_behaves_like 'custom notification recipients'
    end
  end
end
