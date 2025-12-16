# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::AccessGrantedMailer, feature_category: :groups_and_projects do
  include EmailSpec::Matchers
  using RSpec::Parameterized::TableSyntax

  describe '#email' do
    let(:recipient) { build(:user) }
    let(:group) { build(:group) }
    let(:group_member) { build(:group_member, source: group, user: recipient) }

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

    context 'when member is a group member' do
      it 'contains all the useful information' do
        is_expected.to have_subject "Access to the #{group.human_name} #{group.model_name.singular} was granted"
        is_expected.to have_body_text group.name
        is_expected.to have_body_text group.web_url
        is_expected.to have_body_text group_member.present.human_access
        is_expected.to have_body_text polymorphic_url([group], leave: 1)
      end

      context 'when organizations feature is enabled' do
        let(:organization) { build(:organization) }
        let(:group) { build(:group, organization: organization) }

        before do
          stub_feature_flags(ui_for_organizations: true)
        end

        it 'includes organization information' do
          is_expected.to have_body_text organization.name
          is_expected.to have_body_text organization.web_url
        end
      end
    end

    context 'when member is a project member' do
      let(:project) { build(:project) }
      let(:project_member) { build(:project_member, source: project, user: recipient) }

      subject(:email) do
        described_class.with(member: project_member, member_source_type: project_member.real_source_type).email
      end

      it 'contains all the useful information' do
        is_expected.to have_subject "Access to the #{project.human_name} #{project.model_name.singular} was granted"
        is_expected.to have_body_text project.name
        is_expected.to have_body_text project.web_url
        is_expected.to have_body_text project_member.present.human_access
        is_expected.to have_body_text polymorphic_url([project], leave: 1)
      end

      context 'when organizations feature is enabled' do
        let(:organization) { build(:organization) }
        let(:project) { build(:project, organization: organization) }

        before do
          stub_feature_flags(ui_for_organizations: true)
        end

        it 'includes organization information' do
          is_expected.to have_body_text organization.name
          is_expected.to have_body_text organization.web_url
        end
      end
    end

    context 'when member is nil' do
      let(:group_member) { nil }

      it_behaves_like 'no email is sent'
    end
  end
end
