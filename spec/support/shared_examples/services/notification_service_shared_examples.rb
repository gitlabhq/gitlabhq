# frozen_string_literal: true

# Note that we actually update the attribute on the target_project/group, rather than
# using `allow`.  This is because there are some specs where, based on how the notification
# is done, using an `allow` doesn't change the correct object.
RSpec.shared_examples 'project emails are disabled' do |check_delivery_jobs_queue: false|
  let(:target_project) { notification_target.is_a?(Project) ? notification_target : notification_target.project }

  before do
    reset_delivered_emails!
    target_project.clear_memoization(:emails_disabled)
  end

  it 'sends no emails with project emails disabled' do
    target_project.update_attribute(:emails_disabled, true)

    notification_trigger

    if check_delivery_jobs_queue
      # Only check enqueud jobs, not delivered emails
      expect_no_delivery_jobs
    else
      # Deprecated: Check actual delivered emails
      should_not_email_anyone
    end
  end

  it 'sends emails to someone' do
    target_project.update_attribute(:emails_disabled, false)

    notification_trigger

    if check_delivery_jobs_queue
      # Only check enqueud jobs, not delivered emails
      expect_any_delivery_jobs
    else
      # Deprecated: Check actual delivered emails
      should_email_anyone
    end
  end
end

RSpec.shared_examples 'group emails are disabled' do
  let(:target_group) { notification_target.is_a?(Group) ? notification_target : notification_target.project.group }

  before do
    reset_delivered_emails!
    target_group.clear_memoization(:emails_disabled_memoized)
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

RSpec.shared_examples 'sends notification only to a maximum of ten, most recently active group owners' do
  let(:owners) { create_list(:user, 12, :with_sign_ins) }

  before do
    owners.each do |owner|
      group.add_owner(owner)
    end

    reset_delivered_emails!
  end

  context 'limit notification emails' do
    it 'sends notification only to a maximum of ten, most recently active group owners' do
      ten_most_recently_active_group_owners = owners.sort_by(&:last_sign_in_at).last(10)

      notification_trigger

      should_only_email(*ten_most_recently_active_group_owners)
    end
  end
end

RSpec.shared_examples 'sends notification only to a maximum of ten, most recently active project maintainers' do
  let(:maintainers) { create_list(:user, 12, :with_sign_ins) }

  before do
    maintainers.each do |maintainer|
      project.add_maintainer(maintainer)
    end

    reset_delivered_emails!
  end

  context 'limit notification emails' do
    it 'sends notification only to a maximum of ten, most recently active project maintainers' do
      ten_most_recently_active_project_maintainers = maintainers.sort_by(&:last_sign_in_at).last(10)

      notification_trigger

      should_only_email(*ten_most_recently_active_project_maintainers)
    end
  end
end
