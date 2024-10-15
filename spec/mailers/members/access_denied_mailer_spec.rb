# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::AccessDeniedMailer, feature_category: :groups_and_projects do
  include EmailSpec::Matchers
  using RSpec::Parameterized::TableSyntax

  describe '#email' do
    let(:recipient) { build(:recipient) }
    let(:group) { build(:group) }
    let(:group_member) { build(:group_member, source: group, user: recipient) }
    let(:project) { build(:project, :public, group: group) }
    let(:project_member) { build(:project_member, source: project, user: recipient) }
    let(:notifiable) { true }

    before do
      allow(member).to receive(:notifiable?).with(:subscription).and_return(notifiable)
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
        is_expected.to have_subject "Access to the #{source.full_name} #{type} was denied"
        is_expected.to have_body_text source.full_name
        is_expected.to have_body_text source.web_url
      end

      context 'when user can not read source' do
        before do
          source.visibility_level = Gitlab::VisibilityLevel::PRIVATE
        end

        it 'hides source name from subject and body', :aggregate_failures do
          is_expected.to have_subject "Access to the Hidden #{type} was denied"
          is_expected.to have_body_text "Hidden #{type}"
          is_expected.not_to have_body_text source.full_name
          is_expected.not_to have_body_text source.web_url
        end
      end

      context 'when the recipient is not notifiable' do
        let(:notifiable) { false }

        it_behaves_like 'no email is sent'
      end
    end
  end
end
