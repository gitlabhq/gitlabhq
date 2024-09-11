# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::InviteMailer, feature_category: :groups_and_projects do
  include EmailSpec::Helpers
  include EmailSpec::Matchers
  using RSpec::Parameterized::TableSyntax

  describe '#initial_email' do
    let(:group) { build(:group, description: nil) }
    let(:owner) { build(:user, owner_of: group) }

    subject(:invite_email) { described_class.initial_email(group_member, group_member.invite_token) }

    context 'for standard concerns' do
      let(:group_member) { invite_to_group(group, inviter: owner) }

      it_behaves_like 'an email sent from GitLab' do
        let(:gitlab_sender_display_name) { Gitlab.config.gitlab.email_display_name }
        let(:gitlab_sender) { Gitlab.config.gitlab.email_from }
        let(:gitlab_sender_reply_to) { Gitlab.config.gitlab.email_reply_to }
      end

      it_behaves_like 'it should show Gmail Actions Join now link'
      it_behaves_like "a user cannot unsubscribe through footer link"
      it_behaves_like 'appearance header and footer enabled'
      it_behaves_like 'appearance header and footer not enabled'
      it_behaves_like 'does not render a manage notifications link'

      it 'contains all the standard information', :aggregate_failures do
        is_expected.to have_body_text group_member.human_access
        is_expected.to have_body_text 'default role'
        is_expected.to have_body_text group_member.invite_token
        is_expected.to have_body_text 'Join now'
        is_expected
          .to have_body_text(invite_url(group_member.invite_token, invite_type: described_class::INITIAL_INVITE))
      end

      it 'shows the description from the invited source' do
        description = '_description_ '
        group = build(:group, description: description)
        group_member = invite_to_group(group, inviter: owner)

        result = described_class.initial_email(group_member, group_member.invite_token)

        expect(result).to have_body_text description
      end

      it 'truncates long descriptions' do
        description = '_description_ ' * 30
        group = build(:group, description: description)
        group_member = invite_to_group(group, inviter: owner)

        result = described_class.initial_email(group_member, group_member.invite_token)

        expect(result).not_to have_body_text description
      end

      context 'when member does not exist' do
        subject(:invite_email) { described_class.initial_email(nil, nil) }

        it 'does not send an email' do
          expect(invite_email.message).to be_a_kind_of(ActionMailer::Base::NullMail)
        end
      end

      context 'when there is an email subject suffix' do
        before do
          stub_config_setting(email_subject_suffix: '_email_suffix_')
        end

        it { is_expected.to have_subject "#{owner.name} invited you to join GitLab | _email_suffix_" }
      end

      context 'when invite email sent is tracked', :snowplow do
        it 'tracks the sent invite' do
          invite_email.deliver_now

          expect_snowplow_event(
            category: 'Members::InviteMailer',
            action: 'invite_email_sent',
            label: 'invite_email'
          )
        end
      end

      context 'when mailgun events are enabled' do
        before do
          stub_application_setting(mailgun_events_enabled: true)
        end

        it 'has custom headers' do
          mailgun_variables = { ::Members::Mailgun::INVITE_EMAIL_TOKEN_KEY => group_member.invite_token }
          aggregate_failures do
            expect(invite_email).to have_header('X-Mailgun-Tag', ::Members::Mailgun::INVITE_EMAIL_TAG)
            expect(invite_email).to have_header('X-Mailgun-Variables', mailgun_variables.to_json)
          end
        end
      end

      context 'when mailgun events are not enabled' do
        before do
          stub_application_setting(mailgun_events_enabled: false)
        end

        it 'has custom headers' do
          mailgun_variables = { ::Members::Mailgun::INVITE_EMAIL_TOKEN_KEY => group_member.invite_token }
          aggregate_failures do
            expect(invite_email).not_to have_header('X-Mailgun-Tag', ::Members::Mailgun::INVITE_EMAIL_TAG)
            expect(invite_email).not_to have_header('X-Mailgun-Variables', mailgun_variables.to_json)
          end
        end
      end
    end

    context 'for group invitation' do
      let(:group_member) { invite_to_group(group, inviter: owner) }

      it 'has all needed content', :aggregate_failures do
        is_expected.to have_body_text group.name
        is_expected.to have_body_text group_member.human_access
        is_expected.to have_body_text group_member.invite_token
        is_expected.to have_content('Group details')
        is_expected.to have_content("What's it about?")
        is_expected.to have_body_text(/Groups assemble/)
      end

      context 'when there is an inviter' do
        it 'contains inviter information' do
          is_expected.to have_subject "#{owner.name} invited you to join GitLab"
        end
      end

      context 'when there is no inviter' do
        let(:group_member) { invite_to_group(group, inviter: nil) }

        it 'does not contain inviter information' do
          is_expected.to have_subject "Invitation to join the #{group.name} group"
        end
      end
    end

    context 'for project invitation' do
      let(:project) { build(:project) }
      let(:maintainer) { build(:user, maintainer_of: project) }
      let(:project_member) { invite_to_project(project, inviter: maintainer) }

      subject(:invite_email) do
        described_class.initial_email(project_member, project_member.invite_token)
      end

      it 'has all needed content', :aggregate_failures do
        is_expected.to have_body_text project.full_name
        is_expected.to have_content("#{maintainer.name} invited you to join the")
        is_expected.to have_content('Project details')
        is_expected.to have_content("What's it about?")
        is_expected.to have_body_text(/Projects are/)
      end

      context 'when there is an inviter' do
        it 'contains inviter information' do
          is_expected.to have_subject "#{maintainer.name} invited you to join GitLab"
        end
      end

      context 'when there is no inviter' do
        let(:project_member) { invite_to_project(project, inviter: nil) }

        it 'does not contain inviter information' do
          is_expected.to have_subject "Invitation to join the #{project.full_name} project"
        end
      end

      def invite_to_project(project, inviter:, user: nil)
        build(
          :project_member,
          :developer,
          source: project,
          invite_token: '1234',
          invite_email: 'project_toto@example.com',
          user: user,
          created_by: inviter
        )
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
        created_by: inviter
      )
    end
  end
end
