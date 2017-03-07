class IssuesCsvMailerPreview < ActionMailer::Preview
  def issues_csv_export
    user = OpenStruct.new(notification_email: 'a@example.com')
    project = Project.unscoped.first

    Notify.issues_csv_email(user, project, "Dummy,Csv\n0,1", export_status)
  end

  private

  def export_status
    {
      truncated: [true, false].sample,
      rows_written: 632,
      rows_expected: 891
    }
  end
end
