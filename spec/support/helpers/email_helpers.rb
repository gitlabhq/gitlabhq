# frozen_string_literal: true

module EmailHelpers
  def sent_to_user(user, recipients: email_recipients)
    recipients.count { |to| to == user.notification_email_or_default }
  end

  def reset_delivered_emails!
    # We shouldn't actually send the emails, but we keep the following line for
    # back-compatibility until we only check the mailer jobs enqueued in Sidekiq
    ActionMailer::Base.deliveries.clear
    # We should only check that the mailer jobs are enqueued in Sidekiq, hence
    # clearing the background jobs queue
    ActiveJob::Base.queue_adapter.enqueued_jobs.clear
  end

  def expect_only_one_email_to_be_sent(subject:, to:)
    count_of_sent_emails = ActionMailer::Base.deliveries.count
    expect(count_of_sent_emails).to eq(1), "Expected only one email to be sent, but #{count_of_sent_emails} emails were sent instead"

    return unless count_of_sent_emails == 1

    message = ActionMailer::Base.deliveries.first

    expect(message.subject).to eq(subject), "Expected '#{subject}' email to be sent, but '#{message.subject}' email was sent instead"
    expect(message.to).to match_array(to), "Expected the email to be sent to #{to}, but it was sent to #{message.to} instead"
  end

  def should_only_email(*users, kind: :to)
    recipients = email_recipients(kind: kind)

    users.each { |user| should_email(user, recipients: recipients) }

    expect(recipients.count).to eq(users.count)
  end

  def should_email(user, times: 1, recipients: email_recipients)
    amount = sent_to_user(user, recipients: recipients)
    failed_message = -> { "User #{user.username} (#{user.id}): email test failed (expected #{times}, got #{amount})" }
    expect(amount).to eq(times), failed_message
  end

  def should_not_email(user, recipients: email_recipients)
    should_email(user, times: 0, recipients: recipients)
  end

  def should_not_email_anyone
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  def should_email_anyone
    expect(ActionMailer::Base.deliveries).not_to be_empty
  end

  def email_recipients(kind: :to)
    ActionMailer::Base.deliveries.flat_map(&kind)
  end

  def find_email_for(user_or_email)
    to = user_or_email.is_a?(User) ? user_or_email.notification_email_or_default : user_or_email
    ActionMailer::Base.deliveries.find { |d| d.to.include?(to) }
  end

  def have_referable_subject(referable, include_project: true, reply: false)
    prefix = if include_project && referable.project
               "#{referable.project.name} | "
             elsif referable.is_a?(Issue) && referable.group_level?
               "#{referable.namespace.name} | "
             else
               ""
             end.freeze

    prefix = "Re: #{prefix}" if reply

    suffix = "#{referable.title} (#{referable.to_reference})"

    have_subject [prefix, suffix].compact.join
  end

  def enqueue_mail_with(mailer_class, mail_method_name, *args)
    args.map! { |arg| arg.is_a?(ActiveRecord::Base) ? arg.id : arg }
    have_enqueued_mail(mailer_class, mail_method_name).with(*args)
  end

  def not_enqueue_mail_with(mailer_class, mail_method_name, *args)
    args.map! { |arg| arg.is_a?(ActiveRecord::Base) ? arg.id : arg }

    matcher = have_enqueued_mail(mailer_class, mail_method_name).with(*args)
    description = proc { 'email has not been enqueued' }

    RSpec::Matchers::AliasedNegatedMatcher.new(matcher, description)
  end

  def have_only_enqueued_mail_with_args(mailer_class, mailer_method, *args)
    raise ArgumentError, 'You must provide at least one array of mailer arguments' if args.empty?

    count_expectation = have_enqueued_mail(mailer_class, mailer_method).exactly(args.size).times

    args.inject(count_expectation) do |composed_expectation, arguments|
      composed_expectation.and(have_enqueued_mail(mailer_class, mailer_method).with(*arguments))
    end
  end

  def expect_sender(user, sender_email: nil)
    sender = subject.header[:from].addrs[0]
    expect(sender.display_name).to eq("#{user.name} (@#{user.username})")
    expect(sender.address).to eq(sender_email.presence || gitlab_sender)
  end

  def expect_service_desk_custom_email_delivery_options(service_desk_setting)
    expect(subject.delivery_method).to be_a Mail::SMTP
    expect(service_desk_setting.custom_email_credential).to be_present

    credential = service_desk_setting.custom_email_credential

    expect(subject.delivery_method.settings).to include(
      address: credential.smtp_address,
      port: credential.smtp_port,
      user_name: credential.smtp_username,
      password: credential.smtp_password,
      domain: service_desk_setting.custom_email.split('@').last,
      authentication: credential.smtp_authentication
    )
  end
end
