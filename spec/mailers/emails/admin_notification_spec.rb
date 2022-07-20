# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::AdminNotification do
  include EmailSpec::Matchers
  include_context 'gitlab email notification'

  it 'adds email methods to Notify' do
    subject.instance_methods.each do |email_method|
      expect(Notify).to be_respond_to(email_method)
    end
  end

  describe 'user_auto_banned_email' do
    let_it_be(:admin) { create(:user) }
    let_it_be(:user) { create(:user) }

    let(:max_project_downloads) { 5 }
    let(:time_period) { 600 }
    let(:group) { nil }

    subject do
      Notify.user_auto_banned_email(
        admin.id, user.id,
        max_project_downloads: max_project_downloads,
        within_seconds: time_period,
        group: group
      )
    end

    it_behaves_like 'an email sent from GitLab'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'

    it 'is sent to the administrator' do
      is_expected.to deliver_to admin.email
    end

    it 'has the correct subject' do
      is_expected.to have_subject "We've detected unusual activity"
    end

    it 'includes the name of the user' do
      is_expected.to have_body_text user.name
    end

    it 'includes the scope of the ban' do
      is_expected.to have_body_text "banned from your GitLab instance"
    end

    it 'includes the reason' do
      is_expected.to have_body_text "due to them downloading more than 5 project repositories within 10 minutes"
    end

    it 'includes a link to unban the user' do
      is_expected.to have_body_text admin_users_url(filter: 'banned')
    end

    it 'includes a link to change the settings' do
      is_expected.to have_body_text network_admin_application_settings_url(anchor: 'js-ip-limits-settings')
    end

    it 'includes the email reason' do
      is_expected.to have_body_text %r{You're receiving this email because of your account on <a .*>localhost<\/a>}
    end

    context 'when scoped to a group' do
      let(:group) { create(:group) }

      it 'includes the scope of the ban' do
        is_expected.to have_body_text "banned from your group (#{group.name})"
      end
    end
  end
end
