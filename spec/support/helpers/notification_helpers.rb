# frozen_string_literal: true

module NotificationHelpers
  extend self

  def send_notifications(*new_mentions, current_user: @u_disabled)
    mentionable.description = new_mentions.map(&:to_reference).join(' ')

    notification.send(notification_method, mentionable, new_mentions, current_user)
  end

  def create_global_setting_for(user, level)
    setting = user.global_notification_setting
    setting.level = level
    setting.save!

    user
  end

  def create_user_with_notification(level, username, resource = project)
    user = create(:user, username: username)
    create_notification_setting(user, resource, level)

    user
  end

  def create_notification_setting(user, resource, level)
    setting = user.notification_settings_for(resource)
    setting.level = level
    setting.save!
  end

  # Create custom notifications
  # When resource is nil it means global notification
  def update_custom_notification(event, user, resource: nil, value: true)
    setting = user.notification_settings_for(resource)
    setting.update!(event => value)
  end

  def expect_delivery_jobs_count(count)
    expect(ActionMailer::MailDeliveryJob).to have_been_enqueued.exactly(count).times
  end

  def expect_no_delivery_jobs
    expect(ActionMailer::MailDeliveryJob).not_to have_been_enqueued
  end

  def expect_any_delivery_jobs
    expect(ActionMailer::MailDeliveryJob).to have_been_enqueued.at_least(:once)
  end

  def have_enqueued_email(*args, mailer: "Notify", mail: "", delivery: "deliver_now")
    have_enqueued_job(ActionMailer::MailDeliveryJob).with(mailer, mail, delivery, args: args)
  end

  def expect_enqueud_email(*args, mailer: "Notify", mail: "", delivery: "deliver_now")
    expect(ActionMailer::MailDeliveryJob).to have_been_enqueued.with(mailer, mail, delivery, args: args)
  end

  def expect_not_enqueud_email(*args, mailer: "Notify", mail: "")
    expect(ActionMailer::MailDeliveryJob).not_to have_been_enqueued.with(mailer, mail, args: any_args)
  end
end
