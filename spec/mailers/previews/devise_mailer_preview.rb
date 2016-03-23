class DeviseMailerPreview < ActionMailer::Preview
  def confirmation_instructions_for_signup
    user = User.new(email: 'signup@example.com')
    DeviseMailer.confirmation_instructions(user, 'faketoken', {})
  end

  def confirmation_instructions_for_new_email
    user = User.last
    DeviseMailer.confirmation_instructions(user, 'faketoken', {})
  end
end
