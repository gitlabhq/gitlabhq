# frozen_string_literal: true

RSpec.shared_context 'gitlab email notification' do
  let_it_be(:group, reload: true) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project, reload: true) { create(:project, :repository, name: 'a-known-name', group: group) }
  let_it_be(:recipient, reload: true) { create(:user, email: 'recipient@example.com') }
  let(:gitlab_sender_display_name) { Gitlab.config.gitlab.email_display_name }
  let(:gitlab_sender) { Gitlab.config.gitlab.email_from }
  let(:gitlab_sender_reply_to) { Gitlab.config.gitlab.email_reply_to }
  let(:new_user_address) { 'newguy@example.com' }

  before do
    email = recipient.emails.create!(email: "notifications@example.com")
    recipient.update_attribute(:notification_email, email.email)
    stub_incoming_email_setting(enabled: true, address: "reply+%{key}@#{Gitlab.config.gitlab.host}")
  end
end

RSpec.shared_context 'reply-by-email is enabled with incoming address without %{key}' do
  before do
    stub_incoming_email_setting(enabled: true, address: "reply@#{Gitlab.config.gitlab.host}")
  end
end
