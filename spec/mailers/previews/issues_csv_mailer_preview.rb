class IssuesCsvMailerPreview < ActionMailer::Preview
  def issues_csv_export
    user = OpenStruct.new(notification_email: 'a@example.com')
    project = OpenStruct.new(name: 'Judolint')

    Notify.issues_csv_email(user, project, "Dummy,Csv\n0,1")
  end
end
