# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteMirrorNotificationWorker, :mailer, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository, :remote_mirror) }
  let_it_be(:mirror) { project.remote_mirrors.first }

  describe '#perform' do
    it 'calls NotificationService#remote_mirror_update_failed when the mirror exists' do
      mirror.update_column(:last_error, "There was a problem fetching")

      expect(NotificationService).to receive_message_chain(:new, :remote_mirror_update_failed)

      subject.perform(mirror.id)

      expect(mirror.reload.error_notification_sent?).to be_truthy
    end

    it 'does nothing when the mirror has no errors' do
      expect(NotificationService).not_to receive(:new)

      subject.perform(mirror.id)
    end

    it 'does nothing when the mirror does not exist' do
      expect(NotificationService).not_to receive(:new)

      subject.perform(non_existing_record_id)
    end

    it 'does nothing when a notification has already been sent' do
      mirror.update_columns(
        last_error: "There was a problem fetching",
        error_notification_sent: true
      )

      expect(NotificationService).not_to receive(:new)

      subject.perform(mirror.id)
    end
  end
end
