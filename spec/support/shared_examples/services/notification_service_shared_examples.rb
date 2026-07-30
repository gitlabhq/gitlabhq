# frozen_string_literal: true

RSpec.shared_examples 'project emails are disabled' do |check_delivery_jobs_queue: false|
  let(:target_project) { notification_target.is_a?(Project) ? notification_target : notification_target.project }

  before do
    reset_delivered_emails!
    allow(target_project.project_setting).to receive(:emails_enabled?).and_return(false)
  end

  it 'sends no emails with project emails disabled' do
    notification_trigger

    if check_delivery_jobs_queue
      # Only check enqueued jobs, not delivered emails
      expect_no_delivery_jobs
    else
      # Deprecated: Check actual delivered emails
      should_not_email_anyone
    end
  end
end

RSpec.shared_examples 'group emails are disabled' do |check_delivery_jobs_queue: false|
  let(:target_group) { notification_target.is_a?(Group) ? notification_target : notification_target.project.group }

  before do
    reset_delivered_emails!
    allow(target_group).to receive(:emails_enabled?).and_return(false)
  end

  it 'sends no emails with group emails disabled' do
    notification_trigger

    if check_delivery_jobs_queue
      expect_no_delivery_jobs
    else
      should_not_email_anyone
    end
  end
end

RSpec.shared_examples 'sends access request notification limited to the most recently active group owners' do
  let_it_be(:owners) { create_list(:user, 3, :with_sign_ins) }

  before do
    owners.each do |owner|
      group.add_owner(owner)
    end

    reset_delivered_emails!
    stub_const('Member::ACCESS_REQUEST_APPROVERS_TO_BE_NOTIFIED_LIMIT', 2)
  end

  it 'sends limited notifications' do
    most_recently_active_group_owners = owners.sort_by(&:last_sign_in_at).last(2)

    expect do
      notification_trigger
    end.to have_only_enqueued_mail_with_args(
      Members::AccessRequestedMailer,
      :email,
      *most_recently_active_group_owners.map { |user| hash_including(params: hash_including(recipient: user)) }
    )
  end
end

RSpec.shared_examples 'sends access request notification limited to the most recently active project maintainers' do
  let_it_be(:maintainers) { create_list(:user, 3, :with_sign_ins) }

  before do
    maintainers.each do |maintainer|
      project.add_maintainer(maintainer)
    end

    reset_delivered_emails!
    stub_const('Member::ACCESS_REQUEST_APPROVERS_TO_BE_NOTIFIED_LIMIT', 2)
  end

  it 'sends limited notifications' do
    most_recently_active_project_maintainers = maintainers.sort_by(&:last_sign_in_at).last(2)

    expect do
      notification_trigger
    end.to have_only_enqueued_mail_with_args(
      Members::AccessRequestedMailer,
      :email,
      *most_recently_active_project_maintainers.map do |user|
        hash_including(params: hash_including(recipient: user))
      end
    )
  end
end
