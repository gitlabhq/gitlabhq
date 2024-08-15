# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::InviteReminderMailer, feature_category: :groups_and_projects do
  include EmailSpec::Matchers

  describe '#email' do
    let(:group) { build(:group, id: non_existing_record_id) }
    let(:inviter) { build(:user) }
    let(:group_member) { invite_to_group(group, inviter: inviter) }
    let(:reminder_index) { 0 }
    let(:gitlab_sender_display_name) { Gitlab.config.gitlab.email_display_name }
    let(:gitlab_sender) { Gitlab.config.gitlab.email_from }
    let(:gitlab_sender_reply_to) { Gitlab.config.gitlab.email_reply_to }

    subject(:email) { described_class.email(group_member, group_member.invite_token, reminder_index) }

    context 'for first reminder email' do
      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like 'a user cannot unsubscribe through footer link'

      it 'contains all the useful information' do
        is_expected.to have_subject "#{inviter.name}'s invitation to GitLab is pending"
        is_expected.to have_body_text group.human_name
        is_expected.to have_body_text group_member.human_access.downcase
        is_expected.to have_body_text invite_url(group_member.invite_token)
        is_expected.to have_body_text decline_invite_url(group_member.invite_token)
      end
    end

    context 'for second reminder email' do
      let(:reminder_index) { 1 }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like 'a user cannot unsubscribe through footer link'

      it 'contains all the useful information' do
        is_expected.to have_subject "#{inviter.name} is waiting for you to join GitLab"
        is_expected.to have_body_text group.human_name
        is_expected.to have_body_text group_member.human_access.downcase
        is_expected.to have_body_text invite_url(group_member.invite_token)
        is_expected.to have_body_text decline_invite_url(group_member.invite_token)
      end
    end

    context 'for last reminder email' do
      let(:reminder_index) { 2 }

      it_behaves_like 'an email sent from GitLab'
      it_behaves_like 'it should not have Gmail Actions links'
      it_behaves_like 'a user cannot unsubscribe through footer link'

      it 'contains all the useful information' do
        is_expected.to have_subject "#{inviter.name} is still waiting for you to join GitLab"
        is_expected.to have_body_text group.human_name
        is_expected.to have_body_text group_member.human_access.downcase
        is_expected.to have_body_text invite_url(group_member.invite_token)
        is_expected.to have_body_text decline_invite_url(group_member.invite_token)
      end
    end

    context 'without a reminder' do
      context 'when member does not exist' do
        let(:group_member) { build(:group_member, id: nil, invite_token: nil) }

        it_behaves_like 'no email is sent'
      end

      context 'when member is not created by a user' do
        let(:inviter) { nil }

        it_behaves_like 'no email is sent'
      end

      context 'when member is a known user' do
        let(:group_member) { invite_to_group(group, inviter: inviter, user: build(:user, id: non_existing_record_id)) }

        it_behaves_like 'no email is sent'
      end
    end

    def invite_to_group(group, inviter:, user: nil)
      build(
        :group_member,
        :developer,
        source: group,
        invite_token: '1234',
        invite_email: 'group_toto@example.com',
        user: user,
        created_by: inviter,
        created_at: Time.current
      )
    end
  end
end
