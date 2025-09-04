# frozen_string_literal: true

module SentNotificationHelpers
  def create_sent_notification(*args, **kwargs)
    new_record = create(:sent_notification, *args, **kwargs)

    PartitionedSentNotification.find_by(id: new_record.id)
  end
end
