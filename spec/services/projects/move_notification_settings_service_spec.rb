require 'spec_helper'

describe Projects::MoveNotificationSettingsService do
  let(:user) { create(:user) }
  let(:project_with_notifications) { create(:project, namespace: user.namespace) }
  let(:target_project) { create(:project, namespace: user.namespace) }

  subject { described_class.new(target_project, user) }

  describe '#execute' do
    context 'with notification settings' do
      before do
        create_list(:notification_setting, 2, source: project_with_notifications)
      end

      it 'moves the user\'s notification settings from one project to another' do
        expect(project_with_notifications.notification_settings.count).to eq 3
        expect(target_project.notification_settings.count).to eq 1

        subject.execute(project_with_notifications)

        expect(project_with_notifications.notification_settings.count).to eq 0
        expect(target_project.notification_settings.count).to eq 3
      end

      it 'rollbacks changes if transaction fails' do
        allow(subject).to receive(:success).and_raise(StandardError)

        expect { subject.execute(project_with_notifications) }.to raise_error(StandardError)

        expect(project_with_notifications.notification_settings.count).to eq 3
        expect(target_project.notification_settings.count).to eq 1
      end
    end

    it 'does not move existent notification settings in the current project' do
      expect(project_with_notifications.notification_settings.count).to eq 1
      expect(target_project.notification_settings.count).to eq 1
      expect(user.notification_settings.count).to eq 2

      subject.execute(project_with_notifications)

      expect(user.notification_settings.count).to eq 1
    end

    context 'when remove_remaining_elements is false' do
      let(:options) { { remove_remaining_elements: false } }

      it 'does not remove remaining notification settings' do
        subject.execute(project_with_notifications, options)

        expect(project_with_notifications.notification_settings.count).not_to eq 0
      end
    end
  end
end
