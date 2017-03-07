class IssuesCsvMailerPreview < ActionMailer::Preview
  def issues_csv_export
    user = OpenStruct.new(notification_email: 'a@example.com')
    project = Project.unscoped.first
    issues_count = 891

    Notify.issues_csv_email(user, project, "Dummy,Csv\n0,1", issues_count, [true, false].sample)
  end
end
