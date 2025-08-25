# frozen_string_literal: true

module SentNotificationHelpers
  def create_sent_notification(*args, **kwargs)
    new_record = create(:sent_notification, *args, **kwargs)

    if Feature.enabled?(:sent_notifications_partitioned_reply_key, :instance)
      PartitionedSentNotification.find_by(id: new_record.id)
    else
      new_record
    end
  end
end
