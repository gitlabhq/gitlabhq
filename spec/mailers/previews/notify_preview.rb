class NotifyPreview < ActionMailer::Preview
  def note_merge_request_email_for_individual_note
    note_email(:note_merge_request_email) do
      note = <<-MD.strip_heredoc
        This is an individual note on a merge request :smiley:

        In this notification email, we expect to see:

        - The note contents (that's what you're looking at)
        - A link to view this note on Gitlab
        - An explanation for why the user is receiving this notification
      MD

      create_note(noteable_type: 'merge_request', noteable_id: merge_request.id, note: note)
    end
  end

  def note_merge_request_email_for_discussion
    note_email(:note_merge_request_email) do
      note = <<-MD.strip_heredoc
        This is a new discussion on a merge request :smiley:

        In this notification email, we expect to see:

        - A line saying who started this discussion
        - The note contents (that's what you're looking at)
        - A link to view this discussion on Gitlab
        - An explanation for why the user is receiving this notification
      MD

      create_note(noteable_type: 'merge_request', noteable_id: merge_request.id, type: 'DiscussionNote', note: note)
    end
  end

  def note_merge_request_email_for_diff_discussion
    note_email(:note_merge_request_email) do
      note = <<-MD.strip_heredoc
        This is a new discussion on a merge request :smiley:

        In this notification email, we expect to see:

        - A line saying who started this discussion and on what file
        - The diff
        - The note contents (that's what you're looking at)
        - A link to view this discussion on Gitlab
        - An explanation for why the user is receiving this notification
      MD

      position = Gitlab::Diff::Position.new(
        old_path: "files/ruby/popen.rb",
        new_path: "files/ruby/popen.rb",
        old_line: nil,
        new_line: 14,
        diff_refs: merge_request.diff_refs
      )

      create_note(noteable_type: 'merge_request', noteable_id: merge_request.id, type: 'DiffNote', position: position, note: note)
    end
  end

  def closed_issue_email
    Notify.closed_issue_email(user.id, issue.id, user.id).message
  end

  def issue_status_changed_email
    Notify.issue_status_changed_email(user.id, issue.id, 'closed', user.id).message
  end

  def closed_merge_request_email
    Notify.closed_merge_request_email(user.id, issue.id, user.id).message
  end

  def merge_request_status_email
    Notify.merge_request_status_email(user.id, merge_request.id, 'closed', user.id).message
  end

  def merged_merge_request_email
    Notify.merged_merge_request_email(user.id, merge_request.id, user.id).message
  end

  def member_access_denied_email
    Notify.member_access_denied_email('project', project.id, user.id).message
  end

  def member_access_granted_email
    Notify.member_access_granted_email('project', user.id).message
  end

  def member_access_requested_email
    Notify.member_access_requested_email('group', user.id, 'some@example.com').message
  end

  def member_invite_accepted_email
    Notify.member_invite_accepted_email('project', user.id).message
  end

  def member_invite_declined_email
    Notify.member_invite_declined_email(
      'project',
      project.id,
      'invite@example.com',
      user.id
    ).message
  end

  def member_invited_email
    Notify.member_invited_email('project', user.id, '1234').message
  end

  def pages_domain_enabled_email
    cleanup do
      pages_domain = PagesDomain.new(domain: 'my.example.com', project: project, verified_at: Time.now, enabled_until: 1.week.from_now)

      Notify.pages_domain_enabled_email(pages_domain, user).message
    end
  end

  def pipeline_success_email
    Notify.pipeline_success_email(pipeline, pipeline.user.try(:email))
  end

  def pipeline_failed_email
    Notify.pipeline_failed_email(pipeline, pipeline.user.try(:email))
  end

  # EE-specific start
  def add_merge_request_approver_email
    Notify.add_merge_request_approver_email(user.id, merge_request.id, user.id).message
  end

  def issues_csv_email
    Notify.issues_csv_email(user, project, '1997,Ford,E350', { truncated: false, rows_expected: 3, rows_written: 3 }).message
  end

  def approved_merge_request_email
    Notify.approved_merge_request_email(user.id, merge_request.id, approver.id).message
  end

  def unapproved_merge_request_email
    Notify.unapproved_merge_request_email(user.id, merge_request.id, approver.id).message
  end

  def mirror_was_hard_failed_email
    Notify.mirror_was_hard_failed_email(project.id, user.id).message
  end

  def project_mirror_user_changed_email
    Notify.project_mirror_user_changed_email(user.id, 'deleted_user_name', project.id).message
  end

  def send_admin_notification
    Notify.send_admin_notification(user.id, 'Email subject from admin', 'Email body from admin').message
  end

  def send_unsubscribed_notification
    Notify.send_unsubscribed_notification(user.id).message
  end

  def service_desk_new_note_email
    cleanup do
      note = create_note(noteable_type: 'Issue', noteable_id: issue.id, note: 'Issue note content')

      Notify.service_desk_new_note_email(issue.id, note.id).message
    end
  end

  def service_desk_thank_you_email
    Notify.service_desk_thank_you_email(issue.id).message
  end
  # EE-specific end

  private

  def project
    @project ||= Project.find_by_full_path('gitlab-org/gitlab-test')
  end

  def issue
    @merge_request ||= project.issues.first
  end

  def merge_request
    @merge_request ||= project.merge_requests.first
  end

  def pipeline
    @pipeline = Ci::Pipeline.last
  end

  def user
    @user ||= User.last
  end

  def create_note(params)
    Notes::CreateService.new(project, user, params).execute
  end

  def note_email(method)
    cleanup do
      note = yield

      Notify.public_send(method, user.id, note)
    end
  end

  def cleanup
    email = nil

    ActiveRecord::Base.transaction do
      email = yield
      raise ActiveRecord::Rollback
    end

    email
  end

  # EE-specific start
  def approver
    @user ||= User.first
  end
  # EE-specific end
end
