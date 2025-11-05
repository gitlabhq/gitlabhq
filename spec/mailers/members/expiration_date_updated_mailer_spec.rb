# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::ExpirationDateUpdatedMailer, feature_category: :groups_and_projects do
  include EmailSpec::Matchers
  using RSpec::Parameterized::TableSyntax

  describe '#email' do
    let(:recipient) { build(:user) }
    let(:group) { build(:group) }
    let(:group_member) { build(:group_member, source: group, user: recipient, expires_at: 1.day.from_now) }
    let(:notifiable) { true }

    before do
      allow(group_member).to receive(:notifiable?).with(:mention).and_return(notifiable)
    end

    subject(:email) do
      described_class.with(member: group_member, member_source_type: group_member&.real_source_type).email
    end

    it_behaves_like 'an email sent from GitLab' do
      let(:gitlab_sender_display_name) { Gitlab.config.gitlab.email_display_name }
      let(:gitlab_sender) { Gitlab.config.gitlab.email_from }
      let(:gitlab_sender_reply_to) { Gitlab.config.gitlab.email_reply_to }
    end

    it_behaves_like 'an email sent to a user'
    it_behaves_like 'it should not have Gmail Actions links'
    it_behaves_like 'a user cannot unsubscribe through footer link'
    it_behaves_like 'appearance header and footer enabled'
    it_behaves_like 'appearance header and footer not enabled'

    context 'when expiration date is changed' do
      context 'when expiration date is one day away' do
        it 'contains all the useful information' do
          is_expected.to have_subject 'Group membership expiration date changed'
          is_expected.to have_body_text group_member.user.name
          is_expected.to have_body_text group.name
          is_expected.to have_body_text group.web_url
          is_expected.to have_body_text group_group_members_url(group, search: group_member.user.username)
          is_expected.to have_body_text 'day.'
          is_expected.not_to have_body_text 'days.'
        end
      end

      context 'when expiration date is more than one day away' do
        before do
          group_member.expires_at = 20.days.from_now
        end

        it 'contains all the useful information' do
          is_expected.to have_subject 'Group membership expiration date changed'
          is_expected.to have_body_text group_member.user.name
          is_expected.to have_body_text group.name
          is_expected.to have_body_text group.web_url
          is_expected.to have_body_text group_group_members_url(group, search: group_member.user.username)
          is_expected.to have_body_text 'days.'
          is_expected.not_to have_body_text 'day.'
        end
      end

      context 'when a group member is newly given an expiration date' do
        let(:new_recipient) { build(:user) }
        let(:new_group_member) { build(:group_member, source: group, user: new_recipient) }

        subject(:email) do
          described_class.with(member: new_group_member, member_source_type: new_group_member.real_source_type).email
        end

        before do
          allow(new_group_member).to receive(:notifiable?).with(:mention).and_return(true)
          new_group_member.expires_at = 5.days.from_now
        end

        it 'contains all the useful information' do
          is_expected.to have_subject 'Group membership expiration date changed'
          is_expected.to have_body_text new_group_member.user.name
          is_expected.to have_body_text group.name
          is_expected.to have_body_text group.web_url
          is_expected.to have_body_text group_group_members_url(group, search: new_group_member.user.username)
          is_expected.to have_body_text 'days.'
          is_expected.not_to have_body_text 'day.'
        end
      end
    end

    context 'when expiration date is removed' do
      before do
        group_member.expires_at = nil
      end

      it 'contains all the useful information' do
        is_expected.to have_subject 'Group membership expiration date removed'
        is_expected.to have_body_text group_member.user.name
        is_expected.to have_body_text group.name
      end
    end

    context 'when member is nil' do
      let(:group_member) { nil }

      it_behaves_like 'no email is sent'
    end

    context 'when member is a project member' do
      let(:project) { build(:project) }
      let(:project_member) { build(:project_member, source: project, user: recipient, expires_at: 1.day.from_now) }

      subject(:email) do
        described_class.with(member: project_member, member_source_type: project_member.real_source_type).email
      end

      it_behaves_like 'no email is sent'
    end

    context 'when member is not notifiable' do
      let(:notifiable) { false }

      it_behaves_like 'no email is sent'
    end
  end
end
