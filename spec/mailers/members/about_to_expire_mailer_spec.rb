# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::AboutToExpireMailer, feature_category: :groups_and_projects do
  include EmailSpec::Matchers
  using RSpec::Parameterized::TableSyntax

  describe '#email' do
    let(:recipient) { build(:recipient) }
    let(:group) { build(:group) }
    let(:group_member) { build(:group_member, source: group, user: recipient, expires_at: 7.days.from_now) }
    let(:project) { build(:project, :public, group: group) }
    let(:project_member) { build(:project_member, source: project, user: recipient, expires_at: 7.days.from_now) }
    let(:notifiable) { true }

    before do
      allow(member).to receive(:notifiable?).with(:mention).and_return(notifiable)
    end

    subject(:email) { described_class.with(member: member).email }

    where(:member, :source, :type) do
      ref(:group_member)   | ref(:group)   | 'group'
      ref(:project_member) | ref(:project) | 'project'
    end

    with_them do
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

      it 'contains all the useful information', :aggregate_failures do
        is_expected.to deliver_to member.user.email
        is_expected.to have_subject "Your membership will expire in 7 days"
        is_expected.to have_body_text "#{type} will expire in 7 days."
        is_expected.to have_body_text public_send(:"#{type}_url", source)
        is_expected.to have_body_text public_send(:"#{type}_#{type}_members_url", source)
      end

      context 'with no expiry on membership' do
        before do
          group_member.expires_at = nil
          project_member.expires_at = nil
        end

        it_behaves_like 'no email is sent'
      end

      context 'with expired membership' do
        before do
          group_member.expires_at = Date.current
          project_member.expires_at = Date.current
        end

        it_behaves_like 'no email is sent'
      end

      context 'when the recipient is not notifiable' do
        let(:notifiable) { false }

        it_behaves_like 'no email is sent'
      end
    end
  end
end
