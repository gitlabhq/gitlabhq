module EmailHelpers
  def sent_to_user(user, recipients: email_recipients)
    recipients.count { |to| to == user.notification_email }
  end

  def reset_delivered_emails!
    ActionMailer::Base.deliveries.clear
  end

  def should_only_email(*users, kind: :to)
    recipients = email_recipients(kind: kind)

    users.each { |user| should_email(user, recipients: recipients) }

    expect(recipients.count).to eq(users.count)
  end

  def should_email(user, times: 1, recipients: email_recipients)
    expect(sent_to_user(user, recipients: recipients)).to eq(times)
  end

  def should_not_email(user, recipients: email_recipients)
    should_email(user, times: 0, recipients: recipients)
  end

  def should_not_email_anyone
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  def email_recipients(kind: :to)
    ActionMailer::Base.deliveries.flat_map(&kind)
  end

  def find_email_for(user)
    ActionMailer::Base.deliveries.find { |d| d.to.include?(user.notification_email) }
  end
end
