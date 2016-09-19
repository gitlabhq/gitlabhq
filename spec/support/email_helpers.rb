module EmailHelpers
  def sent_to_user?(user, recipients = nil)
    recipients ||= ActionMailer::Base.deliveries.flat_map(&:to)

    recipients.count(user.email) == 1
  end

  def reset_delivered_emails!
    ActionMailer::Base.deliveries.clear
  end

  def should_only_email(*users)
    recipients = ActionMailer::Base.deliveries.flat_map(&:to)

    users.each { |user| should_email(user, recipients) }

    expect(recipients.count).to eq(users.count)
  end

  def should_email(user, recipients = nil)
    expect(sent_to_user?(user, recipients)).to be_truthy
  end

  def should_not_email(user, recipients = nil)
    expect(sent_to_user?(user, recipients)).to be_falsey
  end

  def should_email_no_one
    expect(ActionMailer::Base.deliveries).to be_empty
  end
end
