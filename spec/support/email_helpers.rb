module EmailHelpers
  def sent_to_user?(user)
    ActionMailer::Base.deliveries.map(&:to).flatten.count(user.email) == 1
  end

  def reset_delivered_emails!
    ActionMailer::Base.deliveries.clear
  end

  def should_only_email(*users)
    users.each {|user| should_email(user) }
    recipients = ActionMailer::Base.deliveries.flat_map(&:to)
    expect(recipients.count).to eq(users.count)
  end

  def should_email(user)
    expect(sent_to_user?(user)).to be_truthy
  end

  def should_not_email(user)
    expect(sent_to_user?(user)).to be_falsey
  end
end
