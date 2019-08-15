# frozen_string_literal: true

# Note that we actually update the attribute on the target_project/group, rather than
# using `allow`.  This is because there are some specs where, based on how the notification
# is done, using an `allow` doesn't change the correct object.
shared_examples 'project emails are disabled' do
  let(:target_project) { notification_target.is_a?(Project) ? notification_target : notification_target.project }

  before do
    reset_delivered_emails!
    target_project.clear_memoization(:emails_disabled)
  end

  it 'sends no emails with project emails disabled' do
    target_project.update_attribute(:emails_disabled, true)

    notification_trigger

    should_not_email_anyone
  end

  it 'sends emails to someone' do
    target_project.update_attribute(:emails_disabled, false)

    notification_trigger

    should_email_anyone
  end
end

shared_examples 'group emails are disabled' do
  let(:target_group) { notification_target.is_a?(Group) ? notification_target : notification_target.project.group }

  before do
    reset_delivered_emails!
    target_group.clear_memoization(:emails_disabled)
  end

  it 'sends no emails with group emails disabled' do
    target_group.update_attribute(:emails_disabled, true)

    notification_trigger

    should_not_email_anyone
  end

  it 'sends emails to someone' do
    target_group.update_attribute(:emails_disabled, false)

    notification_trigger

    should_email_anyone
  end
end
