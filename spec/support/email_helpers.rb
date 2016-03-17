module EmailHelpers
  def sent_to_user?(user)
    ActionMailer::Base.deliveries.map(&:to).flatten.count(user.email) == 1
  end

  def should_email(user)
    expect(sent_to_user?(user)).to be_truthy
  end

  def should_not_email(user)
    expect(sent_to_user?(user)).to be_falsey
  end
end
