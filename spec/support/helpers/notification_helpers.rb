module NotificationHelpers
  extend self

  def send_notifications(*new_mentions)
    mentionable.description = new_mentions.map(&:to_reference).join(' ')

    notification.send(notification_method, mentionable, new_mentions, @u_disabled)
  end

  def create_global_setting_for(user, level)
    setting = user.global_notification_setting
    setting.level = level
    setting.save

    user
  end

  def create_user_with_notification(level, username, resource = project)
    user = create(:user, username: username)
    setting = user.notification_settings_for(resource)
    setting.level = level
    setting.save

    user
  end

  # Create custom notifications
  # When resource is nil it means global notification
  def update_custom_notification(event, user, resource: nil, value: true)
    setting = user.notification_settings_for(resource)
    setting.update!(event => value)
  end
end
