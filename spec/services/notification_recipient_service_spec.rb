require 'spec_helper'

describe NotificationRecipientService do
  describe 'build_recipients' do
    it 'due_date' do
      # These folks are being filtered out because they can't receive notifications
      # notification_recipient.rb#85
      user = create(:user)
      assignee = create(:user)
      issue = create(:issue, :opened, due_date: Date.today, author: user, assignees: [assignee])

      recipients = described_class.build_recipients(
        issue,
        issue.author,
        action: "due_date",
        skip_current_user: false
      )

      expect(recipients).to match_array([user, assignee])
    end
  end
end
