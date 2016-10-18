module EmailHelpers
  def sent_to_user?(user, recipients = email_recipients)
    recipients.include?(user.email)
  end

  def reset_delivered_emails!
    ActionMailer::Base.deliveries.clear
  end

  def should_only_email(*users, kind: :to)
    recipients = email_recipients(kind: kind)

    users.each { |user| should_email(user, recipients) }

    expect(recipients.count).to eq(users.count)
  end

  def should_email(user, recipients = email_recipients)
    expect(sent_to_user?(user, recipients)).to be_truthy
  end

  def should_not_email(user, recipients = email_recipients)
    expect(sent_to_user?(user, recipients)).to be_falsey
  end

  def should_not_email_anyone
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  def email_recipients(kind: :to)
    ActionMailer::Base.deliveries.flat_map(&kind)
  end
end
