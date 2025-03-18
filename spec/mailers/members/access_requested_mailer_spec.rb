# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::AccessRequestedMailer, feature_category: :groups_and_projects do
  include EmailSpec::Matchers
  using RSpec::Parameterized::TableSyntax

  describe '#email' do
    let(:recipient) { build(:recipient) }
    let(:group) { build(:group) }
    let(:group_member) { build(:group_member, source: group) }
    let(:group_members_url) { group_group_members_url(group) }
    let(:project) { build(:project, :public, group: group) }
    let(:project_member) { build(:project_member, source: project) }
    let(:project_members_url) { project_project_members_url(project) }

    subject(:email) { described_class.with(member: member, recipient: recipient).email }

    where(:member, :source, :type, :body_email_link) do
      ref(:group_member)   | ref(:group)   | 'group'   | ref(:group_members_url)
      ref(:project_member) | ref(:project) | 'project' | ref(:project_members_url)
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
        to_emails = email.header[:to].addrs.map(&:address)
        expect(to_emails).to eq([recipient.notification_email_or_default])

        is_expected.to have_subject "Request to join the #{source.full_name} #{type}"
        is_expected.to have_body_text source.full_name
        is_expected.to have_body_text source.web_url
        is_expected.to have_body_text member.human_access
        is_expected.to have_link(href: body_email_link)
      end
    end

    context 'when member does not exist' do
      let(:member) { nil }

      it 'logs and does not send an email' do
        expect(Gitlab::AppLogger).to receive(:info).with('Tried to send an access requested for an invalid member.')

        expect(email.message).to be_a_kind_of(ActionMailer::Base::NullMail)
      end
    end
  end
end
