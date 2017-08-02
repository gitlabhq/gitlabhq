require 'spec_helper'

describe NotificationRecipientService do
  set(:user) { create(:user) }
  set(:project) { create(:empty_project, :public) }
  set(:issue) { create(:issue, project: project) }

  set(:watcher) do
    watcher = create(:user)
    setting = watcher.notification_settings_for(project)
    setting.level = :watch
    setting.save

    watcher
  end

  subject { described_class.new(project) }

  describe '#build_recipients' do
    it 'does not modify the participants of the target' do
      expect { subject.build_recipients(issue, user, action: :new_issue) }
        .not_to change { issue.participants(user) }
    end
  end

  describe '#build_new_note_recipients' do
    set(:note) { create(:note_on_issue, noteable: issue, project: project) }

    it 'does not modify the participants of the target' do
      expect { subject.build_new_note_recipients(note) }
        .not_to change { note.noteable.participants(note.author) }
    end
  end
end
