# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::InviteDeclinedMailer, feature_category: :groups_and_projects do
  include EmailSpec::Helpers
  include EmailSpec::Matchers

  describe '#email' do
    let(:group) { build(:group) }
    let(:invited_user) { build(:user) }
    let(:recipient) { build(:user, owner_of: group) }
    let(:notifiable) { true }
    let(:member) do
      build(
        :group_member,
        :developer,
        source: group,
        invite_email: 'group_toto@example.com',
        user: invited_user,
        created_by: recipient
      )
    end

    before do
      allow(member).to receive(:notifiable?).with(:subscription).and_return(notifiable)
    end

    subject(:email) { described_class.with(member: member).email }

    context 'for standard concerns' do
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
        is_expected.to have_subject 'Invitation declined'
        is_expected.to have_body_text group.name
        is_expected.to have_body_text group.web_url
        is_expected.to have_body_text member.invite_email
      end

      context 'when member does not exist' do
        let(:member) { nil }

        it 'logs and does not send an email' do
          expect(email.message).to be_a_kind_of(ActionMailer::Base::NullMail)
        end
      end

      context 'when member does not have a created_by' do
        let(:recipient) { nil }

        it 'does not send an email' do
          expect(email.message).to be_a_kind_of(ActionMailer::Base::NullMail)
        end
      end

      context 'when there is an email subject suffix' do
        before do
          stub_config_setting(email_subject_suffix: '_email_suffix_')
        end

        it { is_expected.to have_subject 'Invitation declined | _email_suffix_' }
      end
    end

    context 'for group invitation' do
      it 'has expected specific text' do
        is_expected.to have_body_text(/has .*declined.* your invitation to join the .* group./)
      end
    end

    context 'for project invitation' do
      let(:member) do
        build(
          :project_member,
          :developer,
          source: build(:project),
          invite_email: 'project_toto@example.com',
          user: invited_user,
          created_by: build(:user)
        )
      end

      it 'has expected specific text' do
        is_expected.to have_body_text(/has .*declined.* your invitation to join the .* project./)
      end
    end
  end
end
