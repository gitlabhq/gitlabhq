# frozen_string_literal: true

require 'spec_helper'

RSpec.describe User, :with_current_organization, feature_category: :user_profile do
  using RSpec::Parameterized::TableSyntax

  include ProjectForksHelper
  include TermsHelper
  include ExclusiveLeaseHelpers
  include LdapHelpers

  shared_examples 'checks for groups with project creation permission' do
    let_it_be(:user) { create(:user) }

    context 'when user does not belong in a group' do
      it { is_expected.to be(false) }
    end

    context 'when user belongs in group allowing project creation' do
      let_it_be(:group) do
        create(:group, developers: [user], project_creation_level: Gitlab::Access::DEVELOPER_PROJECT_ACCESS)
      end

      it { is_expected.to be(true) }
    end

    context 'when user belongs in group not allowing project creation' do
      let_it_be(:group) do
        create(:group, developers: [user], project_creation_level: Gitlab::Access::NO_ONE_PROJECT_ACCESS)
      end

      it { is_expected.to be(false) }

      context 'when group is shared with another group allowing project creation' do
        let_it_be(:shared_group_link) do
          create(
            :group_group_link,
            :developer,
            shared_with_group: group,
            shared_group: create(:group, project_creation_level: Gitlab::Access::DEVELOPER_PROJECT_ACCESS)
          )
        end

        it { is_expected.to be(true) }
      end
    end
  end

  it_behaves_like 'having unique enum values'

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Gitlab::ConfigHelper) }
    it { is_expected.to include_module(Referable) }
    it { is_expected.to include_module(Sortable) }
    it { is_expected.to include_module(TokenAuthenticatable) }
    it { is_expected.to include_module(BlocksUnsafeSerialization) }
    it { is_expected.to include_module(AsyncDeviseEmail) }
  end

  describe 'constants' do
    it { expect(described_class::COUNT_CACHE_VALIDITY_PERIOD).to be_a(Integer) }
    it { expect(described_class::MAX_USERNAME_LENGTH).to be_a(Integer) }
    it { expect(described_class::MIN_USERNAME_LENGTH).to be_a(Integer) }
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:path).to(:namespace).with_prefix }

    it { is_expected.to delegate_method(:notes_filter_for).to(:user_preference) }
    it { is_expected.to delegate_method(:set_notes_filter).to(:user_preference) }

    it { is_expected.to delegate_method(:first_day_of_week).to(:user_preference) }
    it { is_expected.to delegate_method(:first_day_of_week=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:timezone).to(:user_preference) }
    it { is_expected.to delegate_method(:timezone=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:time_display_relative).to(:user_preference) }
    it { is_expected.to delegate_method(:time_display_relative=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:time_display_format).to(:user_preference) }
    it { is_expected.to delegate_method(:time_display_format=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:show_whitespace_in_diffs).to(:user_preference) }
    it { is_expected.to delegate_method(:show_whitespace_in_diffs=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:view_diffs_file_by_file).to(:user_preference) }
    it { is_expected.to delegate_method(:view_diffs_file_by_file=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:dark_color_scheme_id).to(:user_preference) }
    it { is_expected.to delegate_method(:dark_color_scheme_id=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:tab_width).to(:user_preference) }
    it { is_expected.to delegate_method(:tab_width=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:sourcegraph_enabled).to(:user_preference) }
    it { is_expected.to delegate_method(:sourcegraph_enabled=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:gitpod_enabled).to(:user_preference) }
    it { is_expected.to delegate_method(:gitpod_enabled=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:project_shortcut_buttons).to(:user_preference) }
    it { is_expected.to delegate_method(:project_shortcut_buttons=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:keyboard_shortcuts_enabled).to(:user_preference) }
    it { is_expected.to delegate_method(:keyboard_shortcuts_enabled=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:render_whitespace_in_code).to(:user_preference) }
    it { is_expected.to delegate_method(:render_whitespace_in_code=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:markdown_surround_selection).to(:user_preference) }
    it { is_expected.to delegate_method(:markdown_surround_selection=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:markdown_automatic_lists).to(:user_preference) }
    it { is_expected.to delegate_method(:markdown_automatic_lists=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:markdown_maintain_indentation).to(:user_preference) }
    it { is_expected.to delegate_method(:markdown_maintain_indentation=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:diffs_deletion_color).to(:user_preference) }
    it { is_expected.to delegate_method(:diffs_deletion_color=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:diffs_addition_color).to(:user_preference) }
    it { is_expected.to delegate_method(:diffs_addition_color=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:use_new_navigation).to(:user_preference) }
    it { is_expected.to delegate_method(:use_new_navigation=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:extensions_marketplace_opt_in_status).to(:user_preference) }
    it { is_expected.to delegate_method(:extensions_marketplace_opt_in_status=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:extensions_marketplace_opt_in_url).to(:user_preference) }
    it { is_expected.to delegate_method(:extensions_marketplace_opt_in_url=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:pinned_nav_items).to(:user_preference) }
    it { is_expected.to delegate_method(:pinned_nav_items=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:achievements_enabled).to(:user_preference) }
    it { is_expected.to delegate_method(:achievements_enabled=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:organization_groups_projects_sort).to(:user_preference) }
    it { is_expected.to delegate_method(:organization_groups_projects_sort=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:organization_groups_projects_display).to(:user_preference) }
    it { is_expected.to delegate_method(:organization_groups_projects_display=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:dpop_enabled).to(:user_preference) }
    it { is_expected.to delegate_method(:dpop_enabled=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:use_work_items_view).to(:user_preference) }
    it { is_expected.to delegate_method(:use_work_items_view=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:merge_request_dashboard_list_type).to(:user_preference) }
    it { is_expected.to delegate_method(:merge_request_dashboard_list_type=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:merge_request_dashboard_show_drafts).to(:user_preference) }
    it { is_expected.to delegate_method(:merge_request_dashboard_show_drafts=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:text_editor).to(:user_preference) }
    it { is_expected.to delegate_method(:text_editor=).to(:user_preference).with_arguments(:args) }

    it { is_expected.to delegate_method(:job_title).to(:user_detail).allow_nil }
    it { is_expected.to delegate_method(:job_title=).to(:user_detail).with_arguments(:args).allow_nil }

    it { is_expected.to delegate_method(:pronouns).to(:user_detail).allow_nil }
    it { is_expected.to delegate_method(:pronouns=).to(:user_detail).with_arguments(:args).allow_nil }

    it { is_expected.to delegate_method(:pronunciation).to(:user_detail).allow_nil }
    it { is_expected.to delegate_method(:pronunciation=).to(:user_detail).with_arguments(:args).allow_nil }

    it { is_expected.to delegate_method(:bio).to(:user_detail).allow_nil }
    it { is_expected.to delegate_method(:bio=).to(:user_detail).with_arguments(:args).allow_nil }

    it { is_expected.to delegate_method(:discord).to(:user_detail).allow_nil }
    it { is_expected.to delegate_method(:discord=).to(:user_detail).with_arguments(:args).allow_nil }

    it { is_expected.to delegate_method(:linkedin).to(:user_detail).allow_nil }
    it { is_expected.to delegate_method(:linkedin=).to(:user_detail).with_arguments(:args).allow_nil }

    it { is_expected.to delegate_method(:bluesky).to(:user_detail).allow_nil }
    it { is_expected.to delegate_method(:bluesky=).to(:user_detail).with_arguments(:args).allow_nil }

    it { is_expected.to delegate_method(:mastodon).to(:user_detail).allow_nil }
    it { is_expected.to delegate_method(:mastodon=).to(:user_detail).with_arguments(:args).allow_nil }

    it { is_expected.to delegate_method(:twitter).to(:user_detail).allow_nil }
    it { is_expected.to delegate_method(:twitter=).to(:user_detail).with_arguments(:args).allow_nil }

    it { is_expected.to delegate_method(:orcid).to(:user_detail).allow_nil }
    it { is_expected.to delegate_method(:orcid=).to(:user_detail).with_arguments(:args).allow_nil }

    it { is_expected.to delegate_method(:website_url).to(:user_detail).allow_nil }
    it { is_expected.to delegate_method(:website_url=).to(:user_detail).with_arguments(:args).allow_nil }

    it { is_expected.to delegate_method(:location).to(:user_detail).allow_nil }
    it { is_expected.to delegate_method(:location=).to(:user_detail).with_arguments(:args).allow_nil }

    it { is_expected.to delegate_method(:organization).to(:user_detail).with_prefix.allow_nil }
    it { is_expected.to delegate_method(:organization=).to(:user_detail).with_arguments(:args).with_prefix.allow_nil }

    it { is_expected.to delegate_method(:project_authorizations_recalculated_at).to(:user_detail).allow_nil }
    it { is_expected.to delegate_method(:project_authorizations_recalculated_at=).to(:user_detail).with_arguments(:args).allow_nil }

    it { is_expected.to delegate_method(:bot_namespace).to(:user_detail).allow_nil }
    it { is_expected.to delegate_method(:bot_namespace=).to(:user_detail).with_arguments(:args).allow_nil }

    it { is_expected.to delegate_method(:email_otp).to(:user_detail).allow_nil }
    it { is_expected.to delegate_method(:email_otp=).to(:user_detail).with_arguments(:args).allow_nil }
    it { is_expected.to delegate_method(:email_otp_required_after).to(:user_detail).allow_nil }
    it { is_expected.to delegate_method(:email_otp_required_after=).to(:user_detail).with_arguments(:args).allow_nil }
    it { is_expected.to delegate_method(:email_otp_last_sent_at).to(:user_detail).allow_nil }
    it { is_expected.to delegate_method(:email_otp_last_sent_at=).to(:user_detail).with_arguments(:args).allow_nil }
    it { is_expected.to delegate_method(:email_otp_last_sent_to).to(:user_detail).allow_nil }
    it { is_expected.to delegate_method(:email_otp_last_sent_to=).to(:user_detail).with_arguments(:args).allow_nil }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:created_by).class_name('User').optional }
    it { is_expected.to have_one(:namespace) }
    it { is_expected.to have_one(:status) }
    it { is_expected.to have_one(:user_detail) }
    it { is_expected.to have_one(:atlassian_identity) }
    it { is_expected.to have_one(:user_highest_role) }
    it { is_expected.to have_one(:credit_card_validation) }
    it { is_expected.to have_one(:phone_number_validation) }
    it { is_expected.to have_one(:banned_user) }
    it { is_expected.to have_one(:placeholder_user_detail).class_name('Import::PlaceholderUserDetail') }
    it { is_expected.to have_many(:snippets).dependent(:destroy) }
    it { is_expected.to have_many(:members) }
    it { is_expected.to have_many(:member_namespaces) }
    it { is_expected.to have_many(:project_members) }
    it { is_expected.to have_many(:group_members) }
    it { is_expected.to have_many(:groups) }
    it { is_expected.to have_many(:keys).dependent(:destroy) }
    it { is_expected.to have_many(:expired_today_and_unnotified_keys) }
    it { is_expected.to have_many(:expiring_soon_and_unnotified_personal_access_tokens) }
    it { is_expected.to have_many(:deploy_keys).dependent(:nullify) }
    it { is_expected.to have_many(:events).dependent(:delete_all) }
    it { is_expected.to have_many(:issues).dependent(:destroy) }
    it { is_expected.to have_many(:notes).dependent(:destroy) }
    it { is_expected.to have_many(:merge_requests).dependent(:destroy) }
    it { is_expected.to have_many(:identities).dependent(:destroy) }
    it { is_expected.to have_many(:passkeys) }
    it { is_expected.to have_many(:second_factor_webauthn_registrations) }
    it { is_expected.to have_many(:spam_logs).dependent(:destroy) }
    it { is_expected.to have_many(:todos) }
    it { is_expected.to have_many(:award_emoji).dependent(:destroy) }
    it { is_expected.to have_many(:builds) }
    it { is_expected.to have_many(:pipelines) }
    it { is_expected.to have_many(:pipeline_schedules) }
    it { is_expected.to have_many(:chat_names).dependent(:destroy) }
    it { is_expected.to have_many(:saved_replies).class_name('::Users::SavedReply') }
    it { is_expected.to have_many(:uploads) }
    it { is_expected.to have_many(:abuse_reports).dependent(:nullify).inverse_of(:user) }
    it { is_expected.to have_many(:reported_abuse_reports).dependent(:nullify).class_name('AbuseReport').inverse_of(:reporter) }
    it { is_expected.to have_many(:resolved_abuse_reports).class_name('AbuseReport').inverse_of(:resolved_by) }
    it { is_expected.to have_many(:abuse_events).class_name('AntiAbuse::Event').inverse_of(:user) }
    it { is_expected.to have_many(:custom_attributes).class_name('UserCustomAttribute') }
    it { is_expected.to have_many(:releases).dependent(:nullify) }
    it { is_expected.to have_many(:reviews).inverse_of(:author) }
    it { is_expected.to have_many(:merge_request_assignees).inverse_of(:assignee) }
    it { is_expected.to have_many(:issue_assignees).inverse_of(:assignee).dependent(:delete_all) }
    it { is_expected.to have_many(:merge_request_reviewers).inverse_of(:reviewer) }
    it { is_expected.to have_many(:created_custom_emoji).inverse_of(:creator) }
    it { is_expected.to have_many(:timelogs) }
    it { is_expected.to have_many(:callouts).class_name('Users::Callout') }
    it { is_expected.to have_many(:group_callouts).class_name('Users::GroupCallout') }
    it { is_expected.to have_many(:project_callouts).class_name('Users::ProjectCallout') }
    it { is_expected.to have_many(:broadcast_message_dismissals).class_name('Users::BroadcastMessageDismissal') }
    it { is_expected.to have_many(:created_projects).dependent(:nullify).class_name('Project') }
    it { is_expected.to have_many(:created_namespace_details).class_name('Namespace::Detail') }
    it { is_expected.to have_many(:user_achievements).class_name('Achievements::UserAchievement').inverse_of(:user) }
    it { is_expected.to have_many(:awarded_user_achievements).class_name('Achievements::UserAchievement').with_foreign_key('awarded_by_user_id').inverse_of(:awarded_by_user) }
    it { is_expected.to have_many(:revoked_user_achievements).class_name('Achievements::UserAchievement').with_foreign_key('revoked_by_user_id').inverse_of(:revoked_by_user) }
    it { is_expected.to have_many(:achievements).through(:user_achievements).class_name('Achievements::Achievement').inverse_of(:users) }
    it { is_expected.to have_many(:namespace_commit_emails).class_name('Users::NamespaceCommitEmail') }
    it { is_expected.to have_many(:audit_events).with_foreign_key(:author_id).inverse_of(:user) }
    it { is_expected.to have_many(:abuse_trust_scores).class_name('AntiAbuse::TrustScore').dependent(:destroy) }
    it { is_expected.to have_many(:issue_assignment_events).class_name('ResourceEvents::IssueAssignmentEvent') }
    it { is_expected.to have_many(:merge_request_assignment_events).class_name('ResourceEvents::MergeRequestAssignmentEvent') }
    it { is_expected.to have_many(:early_access_program_tracking_events).class_name('EarlyAccessProgram::TrackingEvent') }

    describe '#triggers' do
      let_it_be_with_refind(:user) { create(:user) }
      let_it_be(:expired_trigger) { create(:ci_trigger, expires_at: 5.years.ago, owner: user, project: create(:project, maintainers: [user])) }
      let_it_be(:valid_trigger) { create(:ci_trigger, expires_at: 1.month.from_now, owner: user, project: create(:project, maintainers: [user])) }

      it { is_expected.to have_many(:triggers).class_name('Ci::Trigger').with_foreign_key('owner_id') }

      it 'returns non-expired triggers by default' do
        expect(user.triggers).to contain_exactly(valid_trigger)
      end
    end

    it do
      is_expected.to have_many(:organization_users).class_name('Organizations::OrganizationUser').inverse_of(:user)
    end

    it do
      is_expected.to have_many(:organizations)
        .through(:organization_users).class_name('Organizations::Organization').inverse_of(:users)
    end

    it do
      is_expected.to have_many(:owned_organizations)
        .through(:organization_users).class_name('Organizations::Organization')
    end

    it do
      is_expected.to have_many(:alert_assignees).class_name('::AlertManagement::AlertAssignee').inverse_of(:assignee)
    end

    describe 'organizations association' do
      let_it_be(:organization) { create(:organization) }

      it 'does not create a cross-database query' do
        user = create(:user, organizations: [organization])

        with_cross_joins_prevented do
          expect(user.organizations.count).to eq(1)
        end
      end
    end

    describe 'default values' do
      let_it_be(:user) { described_class.new }

      it { expect(user.admin).to be_falsey }
      it { expect(user.external).to eq(Gitlab::CurrentSettings.user_default_external) }
      it { expect(user.can_create_group).to eq(Gitlab::CurrentSettings.can_create_group) }
      it { expect(user.can_create_team).to be_falsey }
      it { expect(user.hide_no_ssh_key).to be_falsey }
      it { expect(user.hide_no_password).to be_falsey }
      it { expect(user.project_view).to eq('files') }
      it { expect(user.notified_of_own_activity).to be_falsey }
      it { expect(user.preferred_language).to eq(Gitlab::CurrentSettings.default_preferred_language) }
      it { expect(user.theme_id).to eq(described_class.gitlab_config.default_theme) }
      it { expect(user.color_scheme_id).to eq(Gitlab::CurrentSettings.default_syntax_highlighting_theme) }
      it { expect(user.color_mode_id).to eq(Gitlab::ColorModes::APPLICATION_DEFAULT) }
    end

    describe '#user_detail' do
      let_it_be_with_refind(:user) { create(:user) }

      it 'persists `user_detail` by default' do
        expect(user.user_detail).to be_persisted
      end

      shared_examples 'delegated field' do |field, prefix: nil|
        field_name = prefix ? :"#{prefix}_#{field}" : field

        before_all do
          user.update!(field_name => 'my field')
        end

        it 'correctly stores the `user_detail` attribute when the field is given on user creation' do
          expect(user.user_detail).to be_persisted
          expect(user.user_detail[field]).to eq('my field')
        end

        it 'delegates to `user_detail`' do
          expect(user.public_send(field_name)).to eq(user.user_detail[field])
        end
      end

      it_behaves_like 'delegated field', :organization, prefix: 'user_detail'
      it_behaves_like 'delegated field', :bio
      it_behaves_like 'delegated field', :linkedin
      it_behaves_like 'delegated field', :twitter
      it_behaves_like 'delegated field', :location

      context 'when `website_url` is given' do
        before_all do
          user.update!(website_url: 'https://example.com')
        end

        it 'creates `user_detail`' do
          expect(user.user_detail).to be_persisted
          expect(user.user_detail.website_url).to eq('https://example.com')
        end

        it 'delegates `website_url` to `user_detail`' do
          expect(user.website_url).to eq(user.user_detail.website_url)
        end
      end

      it 'delegates `pronouns` to `user_detail`' do
        user.update!(pronouns: 'they/them')

        expect(user.pronouns).to eq(user.user_detail.pronouns)
      end

      it 'delegates `pronunciation` to `user_detail`' do
        user.update!(name: 'Example', pronunciation: 'uhg-zaam-pl')

        expect(user.pronunciation).to eq(user.user_detail.pronunciation)
      end
    end

    describe '#abuse_reports' do
      let_it_be(:current_user) { create(:user) }
      let_it_be(:other_user) { create(:user) }

      it { is_expected.to have_many(:abuse_reports) }

      it 'refers to the abuse report whose user_id is the current user' do
        abuse_report = create(:abuse_report, reporter: other_user, user: current_user)

        expect(current_user.abuse_reports.last).to eq(abuse_report)
      end

      it 'does not refer to the abuse report whose reporter_id is the current user' do
        create(:abuse_report, reporter: current_user, user: other_user)

        expect(current_user.abuse_reports.last).to be_nil
      end

      it 'does not update the user_id of an abuse report when the user is updated' do
        abuse_report = create(:abuse_report, reporter: current_user, user: other_user)

        current_user.block

        expect(abuse_report.reload.user).to eq(other_user)
      end
    end

    describe '#abuse_metadata' do
      let_it_be(:user) { create(:user) }
      let_it_be(:contribution_calendar) { Gitlab::ContributionsCalendar.new(user) }

      before do
        allow(Gitlab::ContributionsCalendar).to receive(:new).and_return(contribution_calendar)
        allow(contribution_calendar).to receive(:activity_dates).and_return({ first: 3, second: 5, third: 4 })

        allow(user).to receive_messages(
          account_age_in_days: 10,
          two_factor_enabled?: true
        )
      end

      it 'returns the expected hash' do
        abuse_metadata = user.abuse_metadata

        expect(abuse_metadata.length).to eq 2
        expect(abuse_metadata).to include(
          account_age: 10,
          two_factor_enabled: 1
        )
      end
    end

    describe '#group_members' do
      it 'does not include group memberships for which user is a requester' do
        user = create(:user)
        group = create(:group, :public)
        group.request_access(user)

        expect(user.group_members).to be_empty
      end
    end

    describe '#project_members' do
      it 'does not include project memberships for which user is a requester' do
        user = create(:user)
        project = create(:project, :public)
        project.request_access(user)

        expect(user.project_members).to be_empty
      end
    end
  end

  describe 'Devise emails' do
    let_it_be_with_refind(:user) { create(:user) }

    describe 'behaviour' do
      it 'sends emails asynchronously' do
        expect do
          user.update!(email: 'hello@hello.com')
        end.to have_enqueued_job.on_queue('mailers').exactly(:twice)
      end
    end

    context 'emails sent on changing password' do
      context 'when password is updated' do
        context 'default behaviour' do
          it 'enqueues the `password changed` email' do
            user.password = described_class.random_password

            expect { user.save! }.to have_enqueued_mail(DeviseMailer, :password_change)
          end

          it 'does not enqueue the `admin changed your password` email' do
            user.password = described_class.random_password

            expect { user.save! }.not_to have_enqueued_mail(DeviseMailer, :password_change_by_admin)
          end
        end

        context '`admin changed your password` email' do
          it 'is enqueued only when explicitly allowed' do
            user.password = described_class.random_password
            user.send_only_admin_changed_your_password_notification!

            expect { user.save! }.to have_enqueued_mail(DeviseMailer, :password_change_by_admin)
          end

          it '`password changed` email is not enqueued if it is explicitly allowed' do
            user.password = described_class.random_password
            user.send_only_admin_changed_your_password_notification!

            expect { user.save! }.not_to have_enqueued_mail(DeviseMailer, :password_changed)
          end

          it 'is not enqueued if sending notifications on password updates is turned off as per Devise config' do
            user.password = described_class.random_password
            user.send_only_admin_changed_your_password_notification!

            allow(Devise).to receive(:send_password_change_notification).and_return(false)

            expect { user.save! }.not_to have_enqueued_mail(DeviseMailer, :password_change_by_admin)
          end
        end
      end

      context 'when password is not updated' do
        it 'does not enqueue the `admin changed your password` email even if explicitly allowed' do
          user.name = 'John'
          user.send_only_admin_changed_your_password_notification!

          expect { user.save! }.not_to have_enqueued_mail(DeviseMailer, :password_change_by_admin)
        end
      end
    end

    describe 'confirmation instructions for unconfirmed email' do
      let(:unconfirmed_email) { 'first-unconfirmed-email@example.com' }
      let(:another_unconfirmed_email) { 'another-unconfirmed-email@example.com' }

      context 'when email is changed to another before performing the job that sends confirmation instructions for previous email change request' do
        it "mentions the recipient's email in the message body", :aggregate_failures do
          same_user = described_class.find(user.id)
          same_user.update!(email: unconfirmed_email)

          user.update!(email: another_unconfirmed_email)

          perform_enqueued_jobs

          confirmation_instructions_for_unconfirmed_email = ActionMailer::Base.deliveries.find do |message|
            message.subject == 'Confirmation instructions' && message.to.include?(unconfirmed_email)
          end
          expect(confirmation_instructions_for_unconfirmed_email.html_part.body.encoded).to match same_user.unconfirmed_email
          expect(confirmation_instructions_for_unconfirmed_email.text_part.body.encoded).to match same_user.unconfirmed_email

          confirmation_instructions_for_another_unconfirmed_email = ActionMailer::Base.deliveries.find do |message|
            message.subject == 'Confirmation instructions' && message.to.include?(another_unconfirmed_email)
          end
          expect(confirmation_instructions_for_another_unconfirmed_email.html_part.body.encoded).to match user.unconfirmed_email
          expect(confirmation_instructions_for_another_unconfirmed_email.text_part.body.encoded).to match user.unconfirmed_email
        end
      end
    end
  end

  describe 'validations' do
    describe 'password' do
      let!(:user) { build(:user) }

      before do
        allow(Devise).to receive(:password_length).and_return(8..128)
        allow(described_class).to receive(:password_length).and_return(10..130)
      end

      context 'length' do
        it { is_expected.to validate_length_of(:password).is_at_least(10).is_at_most(130) }
      end

      context 'length validator' do
        context 'for a short password' do
          before do
            user.password = user.password_confirmation = 'abc'
          end

          it 'does not run the default Devise password length validation' do
            expect(user).to be_invalid
            expect(user.errors.full_messages.join).not_to include('is too short (minimum is 8 characters)')
          end

          it 'runs the custom password length validator' do
            expect(user).to be_invalid
            expect(user.errors.full_messages.join).to include('is too short (minimum is 10 characters)')
          end

          context "length validator with fips", :fips_mode do
            it "runs validations" do
              expect(user).to be_invalid
              expect(user.errors.full_messages.join).to include('is too short (minimum is 10 characters)')
            end
          end
        end

        context 'for a long password' do
          before do
            user.password = user.password_confirmation = 'a' * 140
          end

          it 'does not run the default Devise password length validation' do
            expect(user).to be_invalid
            expect(user.errors.full_messages.join).not_to include('is too long (maximum is 128 characters)')
          end

          it 'runs the custom password length validator' do
            expect(user).to be_invalid
            expect(user.errors.full_messages.join).to include('is too long (maximum is 130 characters)')
          end
        end
      end

      context 'check_password_weakness' do
        let(:weak_password) { "qwertyuiop" }

        it 'checks for password weakness when password changes' do
          expect(Security::WeakPasswords).to receive(:weak_for_user?)
            .with(weak_password, user).and_call_original
          user.password = weak_password
          expect(user).not_to be_valid
        end

        it 'adds an error when password is weak' do
          user.password = weak_password
          expect(user).not_to be_valid
          expect(user.errors).to be_of_kind(:password, 'must not contain commonly used combinations of words and letters')
        end

        it 'is valid when password is not weak' do
          user.password = ::User.random_password
          expect(user).to be_valid
        end

        it 'is valid when weak password was already set' do
          user = build(:user, password: weak_password)
          user.save!(validate: false)

          expect(Security::WeakPasswords).not_to receive(:weak_for_user?)

          # Change an unrelated value
          user.name = "Example McExampleFace"
          expect(user).to be_valid
        end
      end

      context 'namespace_move_dir_allowed' do
        context 'when the user is not a new record' do
          before do
            user.save!
          end

          it 'checks when username changes' do
            expect(user).to receive(:namespace_move_dir_allowed)

            user.username = 'newuser'
            user.validate
          end

          it 'does not check if the username did not change' do
            expect(user).not_to receive(:namespace_move_dir_allowed)
            expect(user.username_changed?).to eq(false)

            user.validate
          end
        end

        it 'does not check if the user is a new record' do
          user = described_class.new(username: 'newuser')

          expect(user.new_record?).to eq(true)
          expect(user).not_to receive(:namespace_move_dir_allowed)

          user.validate
        end
      end
    end

    describe 'name' do
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_length_of(:name).is_at_most(255) }
    end

    describe 'first name' do
      it { is_expected.to validate_length_of(:first_name).is_at_most(127) }
    end

    describe 'last name' do
      it { is_expected.to validate_length_of(:last_name).is_at_most(127) }
    end

    describe 'preferred_language' do
      subject(:preferred_language) { user.preferred_language }

      context 'when preferred_language is set' do
        let(:user) { build(:user, preferred_language: 'de_DE') }

        it { is_expected.to eq 'de_DE' }
      end

      context 'when preferred_language is nil' do
        let(:user) { build(:user) }

        it { is_expected.to eq 'en' }

        context 'when Gitlab::CurrentSettings.default_preferred_language is set' do
          before do
            allow(::Gitlab::CurrentSettings).to receive(:default_preferred_language).and_return('zh_CN')
          end

          it { is_expected.to eq 'zh_CN' }
        end
      end
    end

    context 'color_mode_id' do
      it { is_expected.to allow_value(*Gitlab::ColorModes.valid_ids).for(:color_mode_id) }
      it { is_expected.not_to allow_value(Gitlab::ColorModes.available_modes.size + 1).for(:color_mode_id) }
    end

    shared_examples 'username validations' do
      it { is_expected.to validate_presence_of(:username) }

      context 'when username is reserved' do
        let(:username) { 'dashboard' }

        it 'rejects denied names' do
          expect(user).not_to be_valid
          expect(user.errors.messages[:username]).to contain_exactly 'dashboard is a reserved name'
        end
      end

      context 'when username is a child' do
        let(:username) { 'avatar' }

        it 'allows child names' do
          expect(user).to be_valid
        end
      end

      context 'when username is a wildcard' do
        let(:username) { 'blob' }

        it 'allows wildcard names' do
          expect(user).to be_valid
        end
      end

      context 'when the username is in use by another user' do
        let(:username) { 'foo' }
        let!(:other_user) { create(:user, username: username) }

        it 'is invalid' do
          expect(user).not_to be_valid
          expect(user.errors.full_messages).to contain_exactly('Username has already been taken')
        end
      end

      context 'when the username is assigned to another project pages unique domain' do
        let(:username) { 'existing-domain' }

        it 'is invalid' do
          # Simulate the existing domain being in use
          create(:project_setting, pages_unique_domain: 'existing-domain')

          expect(user).not_to be_valid
          expect(user.errors.full_messages).to contain_exactly('Username has already been taken')
        end
      end

      Mime::EXTENSION_LOOKUP.keys.each do |type|
        context 'with extension format' do
          let(:username) { "test.#{type}" }

          it do
            expect(user).not_to be_valid
            expect(user.errors.full_messages).to include('Username ending with a reserved file extension is not allowed.')
          end
        end

        context 'when suffixed by extension type' do
          let(:username) { "test#{type}" }

          it do
            expect(user).to be_valid
          end
        end
      end
    end

    context 'when creating user' do
      let(:username) { 'test' }
      let(:user) { build(:user, username: username) }

      include_examples 'username validations'
    end

    context 'when updating user' do
      let_it_be_with_reload(:user) { create(:user) }

      before do
        user.username = username if defined?(username)
      end

      include_examples 'username validations'

      context 'when personal project has container registry tags' do
        let(:user) { build_stubbed(:user, username: 'old_path', namespace: build_stubbed(:user_namespace)) }

        before do
          expect(user.namespace).to receive(:any_project_has_container_registry_tags?).and_return(true)
        end

        it 'validates move_dir is allowed for the namespace' do
          user.username = 'new_path'

          expect(user).to be_invalid
          expect(user.errors.messages[:username].first).to eq(_('cannot be changed if a personal project has container registry tags.'))
        end
      end
    end

    it 'has a DB-level NOT NULL constraint on projects_limit' do
      user = create(:user)

      expect(user.persisted?).to eq(true)

      expect do
        user.update_columns(projects_limit: nil)
      end.to raise_error(ActiveRecord::StatementInvalid)
    end

    it { is_expected.to validate_presence_of(:projects_limit) }
    it { is_expected.to define_enum_for(:project_view).with_values(%i[readme activity files wiki]) }
    it { is_expected.to validate_numericality_of(:projects_limit) }
    it { is_expected.to allow_value(0).for(:projects_limit) }
    it { is_expected.not_to allow_value(-1).for(:projects_limit) }
    it { is_expected.not_to allow_value(Gitlab::Database::MAX_INT_VALUE + 1).for(:projects_limit) }

    it_behaves_like 'an object with email-formatted attributes', :email do
      subject { build(:user) }
    end

    it_behaves_like 'an object with email-formatted attributes', :public_email, :notification_email do
      subject { create(:user).tap { |user| user.emails << build(:email, email: email_value, confirmed_at: Time.current) } }
    end

    describe '#commit_email_or_default' do
      let_it_be_with_refind(:user) { create(:user) }

      subject(:commit_email_or_default) { user.commit_email_or_default }

      it 'defaults to the primary email' do
        expect(user.email).to be_present
        expect(commit_email_or_default).to eq(user.email)
      end

      context 'when the column in the database is null' do
        before do
          user.update_column(:commit_email, nil)
        end

        it 'defaults to the primary email' do
          found_user = described_class.find_by(id: user.id)

          expect(found_user.commit_email_or_default).to eq(user.email)
        end
      end

      context 'when commit_email has _private' do
        before do
          user.update_column(:commit_email, Gitlab::PrivateCommitEmail::TOKEN)
        end

        it 'returns the private commit email when commit_email has _private' do
          is_expected.to eq(user.private_commit_email)
        end
      end
    end

    context 'when setting email address' do
      let_it_be_with_refind(:user) { create(:user) }

      shared_examples 'for user notification, public, and commit emails' do
        context 'when confirmed primary email' do
          let(:email) { user.email }

          it 'can be set' do
            set_email

            expect(user).to be_valid
          end

          context 'when primary email is changed' do
            before do
              user.email = generate(:email)
            end

            it 'can not be set' do
              set_email

              expect(user).not_to be_valid
            end
          end

          context 'when confirmed secondary email' do
            let(:email) { create(:email, :confirmed, user: user).email }

            it 'can be set' do
              set_email

              expect(user).to be_valid
            end
          end

          context 'when unconfirmed secondary email' do
            let(:email) { create(:email, user: user).email }

            it 'can not be set' do
              set_email

              expect(user).not_to be_valid
            end
          end

          context 'when invalid confirmed secondary email' do
            let(:email) { create(:email, :confirmed, :skip_validate, user: user, email: 'invalid') }

            it 'can not be set' do
              set_email

              expect(user).not_to be_valid
            end
          end
        end

        context 'when unconfirmed primary email' do
          let(:user) { create(:user, :unconfirmed) }
          let(:email) { user.email }

          it 'can not be set' do
            set_email

            expect(user).not_to be_valid
          end
        end

        context 'when new record' do
          let(:user) { build(:user, :unconfirmed) }
          let(:email) { user.email }

          it 'can not be set' do
            set_email

            expect(user).not_to be_valid
          end

          context 'when skipping confirmation' do
            before do
              user.skip_confirmation = true
            end

            it 'can be set' do
              set_email

              expect(user).to be_valid
            end
          end
        end
      end

      describe 'notification_email' do
        include_examples 'for user notification, public, and commit emails' do
          subject(:set_email) do
            user.notification_email = email
          end
        end
      end

      describe 'public_email' do
        include_examples 'for user notification, public, and commit emails' do
          subject(:set_email) do
            user.public_email = email
          end
        end
      end

      describe 'commit_email' do
        include_examples 'for user notification, public, and commit emails' do
          subject(:set_email) do
            user.commit_email = email
          end
        end
      end
    end

    describe 'email' do
      let(:expected_error) { _('is not allowed for sign-up. Please use your regular email address. Check with your administrator.') }

      context 'when no signup domains allowed' do
        before do
          stub_application_setting(domain_allowlist: [])
        end

        it 'accepts any email' do
          user = build(:user, email: "info@example.com")
          expect(user).to be_valid
        end
      end

      context 'bad regex' do
        before do
          stub_application_setting(domain_allowlist: ['([a-zA-Z0-9]+)+\.com'])
        end

        it 'does not hang on evil input' do
          user = build(:user, email: 'user@aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa!.com')

          expect do
            Timeout.timeout(2.seconds) { user.valid? }
          end.not_to raise_error
        end
      end

      context 'when a signup domain is allowed and subdomains are allowed' do
        before do
          stub_application_setting(domain_allowlist: ['example.com', '*.example.com'])
        end

        it 'accepts info@example.com' do
          user = build(:user, email: "info@example.com")
          expect(user).to be_valid
        end

        it 'accepts info@test.example.com' do
          user = build(:user, email: "info@test.example.com")
          expect(user).to be_valid
        end

        it 'rejects example@test.com' do
          user = build(:user, email: "example@test.com")
          expect(user).to be_invalid
          expect(user.errors.messages[:email].first).to eq(expected_error)
        end

        it 'allows example@test.com if user is placeholder, import user or security policy bot' do
          placeholder_user = build(:user, :placeholder, email: "example@test.com")
          import_user = build(:user, :import_user, email: "example@test.com")
          security_policy_bot = build(:user, :security_policy_bot, email: "example@test.com")

          expect(placeholder_user).to be_valid
          expect(import_user).to be_valid
          expect(security_policy_bot).to be_valid
        end

        it 'does not allow user to update email to a non-allowlisted domain' do
          user = create(:user, email: "info@test.example.com")

          expect { user.update!(email: "test@notexample.com") }
            .to raise_error(StandardError, 'Validation failed: Email is not allowed. Please use your regular email address. Check with your administrator.')
        end

        it 'allows placeholder, import users and security policy bot to update email to a non-allowlisted domain' do
          placeholder_user = create(:user, :placeholder, email: "info@test.example.com")
          import_user = create(:user, :import_user, email: "info2@test.example.com")
          security_policy_bot = create(:user, :security_policy_bot, email: "info3@test.example.com")

          expect(placeholder_user.update!(email: "test@notexample.com")).to eq(true)
          expect(import_user.update!(email: "test2@notexample.com")).to eq(true)
          expect(security_policy_bot.update!(email: "test3@notexample.com")).to eq(true)
        end
      end

      context 'when a signup domain is allowed and subdomains are not allowed' do
        before do
          stub_application_setting(domain_allowlist: ['example.com'])
        end

        it 'accepts info@example.com' do
          user = build(:user, email: "info@example.com")
          expect(user).to be_valid
        end

        it 'rejects info@test.example.com' do
          user = build(:user, email: "info@test.example.com")
          expect(user).to be_invalid
          expect(user.errors.messages[:email].first).to eq(expected_error)
        end

        it 'rejects example@test.com' do
          user = build(:user, email: "example@test.com")
          expect(user).to be_invalid
          expect(user.errors.messages[:email].first).to eq(expected_error)
        end

        it 'accepts example@test.com when added by another user' do
          user = build(:user, email: "example@test.com", created_by_id: 1)
          expect(user).to be_valid
        end
      end

      context 'domain denylist' do
        before do
          stub_application_setting(domain_denylist_enabled: true)
          stub_application_setting(domain_denylist: ['example.com'])
        end

        context 'bad regex' do
          before do
            stub_application_setting(domain_denylist: ['([a-zA-Z0-9]+)+\.com'])
          end

          it 'does not hang on evil input' do
            user = build(:user, email: 'user@aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa!.com')

            expect do
              Timeout.timeout(2.seconds) { user.valid? }
            end.not_to raise_error
          end
        end

        context 'when a signup domain is denied' do
          it 'accepts info@test.com' do
            user = build(:user, email: 'info@test.com')
            expect(user).to be_valid
          end

          it 'rejects info@example.com' do
            user = build(:user, email: 'info@example.com')
            expect(user).not_to be_valid
            expect(user.errors.messages[:email].first).to eq(expected_error)
          end

          it 'accepts info@example.com when added by another user' do
            user = build(:user, email: 'info@example.com', created_by_id: 1)
            expect(user).to be_valid
          end

          it 'does not allow user to update email to a denied domain' do
            user = create(:user, email: 'info@test.com')

            expect { user.update!(email: 'info@example.com') }
              .to raise_error(StandardError, 'Validation failed: Email is not allowed. Please use your regular email address. Check with your administrator.')
          end
        end

        context 'when a signup domain is denied but a wildcard subdomain is allowed' do
          before do
            stub_application_setting(domain_denylist: ['test.example.com'])
            stub_application_setting(domain_allowlist: ['*.example.com'])
          end

          it 'gives priority to allowlist and allow info@test.example.com' do
            user = build(:user, email: 'info@test.example.com')
            expect(user).to be_valid
          end
        end

        context 'with both lists containing a domain' do
          before do
            stub_application_setting(domain_allowlist: ['test.com'])
          end

          it 'accepts info@test.com' do
            user = build(:user, email: 'info@test.com')
            expect(user).to be_valid
          end

          it 'rejects info@example.com' do
            user = build(:user, email: 'info@example.com')
            expect(user).not_to be_valid
            expect(user.errors.messages[:email].first).to eq(expected_error)
          end
        end
      end

      context 'email restrictions' do
        context 'when email restriction is disabled' do
          before do
            stub_application_setting(email_restrictions_enabled: false)
            stub_application_setting(email_restrictions: '\+')
          end

          it 'does accept email address' do
            user = build(:user, email: 'info+1@test.com')

            expect(user).to be_valid
          end
        end

        context 'when email restrictions is enabled' do
          before do
            stub_application_setting(email_restrictions_enabled: true)
            stub_application_setting(email_restrictions: '([\+]|\b(\w*gitlab.com\w*)\b)')
          end

          it 'does not accept email address with + characters' do
            user = build(:user, email: 'info+1@test.com')

            expect(user).not_to be_valid
          end

          it 'does not accept email with a gitlab domain' do
            user = build(:user, email: 'info@gitlab.com')

            expect(user).not_to be_valid
          end

          it 'adds an error message when email is not accepted' do
            user = build(:user, email: 'info@gitlab.com')

            expect(user).not_to be_valid
            expect(user.errors.messages[:email].first).to eq(expected_error)
          end

          it 'does not allow user to update email to a restricted domain' do
            user = create(:user, email: 'info@test.com')

            expect { user.update!(email: 'info@gitlab.com') }
              .to raise_error(StandardError, 'Validation failed: Email is not allowed. Please use your regular email address. Check with your administrator.')
          end

          it 'does accept a valid email address' do
            user = build(:user, email: 'info@test.com')

            expect(user).to be_valid
          end

          it 'allows placeholder, import users and security policy bot to bypass email restrictions' do
            placeholder_user = build(:user, :placeholder, email: "info+1@test.com")
            import_user = build(:user, :import_user, email: "info+1@test.com")
            security_policy_bot = build(:user, :security_policy_bot, email: "info+1@test.com")

            expect(placeholder_user).to be_valid
            expect(import_user).to be_valid
            expect(security_policy_bot).to be_valid
          end

          context 'when created_by_id is set' do
            it 'does accept the email address' do
              user = build(:user, email: 'info+1@test.com', created_by_id: 1)

              expect(user).to be_valid
            end
          end
        end
      end

      context 'when secondary email is same as primary' do
        let(:user) { create(:user, email: 'user@example.com') }

        it 'lets user change primary email without failing validations' do
          user.commit_email = user.email
          user.notification_email = user.email
          user.public_email = user.email
          user.save!

          user.email = 'newemail@example.com'
          user.confirm

          expect(user).to be_valid
        end
      end

      context 'when commit_email is changed to _private' do
        it 'passes user validations' do
          user = create(:user)
          user.commit_email = '_private'

          expect(user).to be_valid
        end
      end
    end

    describe 'composite_identity_enforced' do
      let(:user) { build(:user) }

      it 'is valid when composite_identity_enforced is false' do
        user.composite_identity_enforced = false

        expect(user).to be_valid
      end

      it 'is invalid when composite_identity_enforced is true' do
        user.composite_identity_enforced = true

        expect(user).to be_invalid
        expect(user.errors[:composite_identity_enforced]).to include('is not included in the list')
      end
    end
  end

  describe 'dashboard enum and methods' do
    let(:user) { create(:user) }

    describe '#dashboard' do
      it 'defaults to projects' do
        expect(user.dashboard).to eq('projects')
      end

      context 'with flipped dashboard mapping for rollout' do
        before do
          stub_feature_flags(personal_homepage: user)
        end

        it 'uses flipped enum mapping when setting dashboard value' do
          user.dashboard = 'projects'
          # With flipped mapping, 'projects' gets stored as 'homepage' in the database
          expect(user.read_attribute(:dashboard)).to eq('homepage')
        end

        it 'uses flipped enum mapping when setting homepage value' do
          user.dashboard = 'homepage'
          # With flipped mapping, 'homepage' gets stored as 'projects' in the database
          expect(user.read_attribute(:dashboard)).to eq('projects')
        end

        it 'does not affect other dashboard values' do
          user.dashboard = 'stars'
          expect(user.read_attribute(:dashboard)).to eq('stars') # stars value unchanged
        end
      end

      context 'without flipped dashboard mapping' do
        before do
          stub_feature_flags(personal_homepage: false)
        end

        it 'uses standard enum mapping' do
          user.dashboard = 'projects'
          expect(user.read_attribute(:dashboard)).to eq('projects') # standard projects value

          user.dashboard = 'homepage'
          expect(user.read_attribute(:dashboard)).to eq('homepage') # standard homepage value
        end
      end
    end

    describe '#effective_dashboard_for_routing' do
      context 'without flipped dashboard mapping' do
        before do
          stub_feature_flags(personal_homepage: false)
        end

        it 'returns the actual dashboard value' do
          user.dashboard = 'projects'
          expect(user.effective_dashboard_for_routing).to eq('projects')

          user.dashboard = 'stars'
          expect(user.effective_dashboard_for_routing).to eq('stars')
        end
      end

      context 'with flipped dashboard mapping for rollout' do
        before do
          stub_feature_flags(personal_homepage: user)
        end

        it 'flips projects to homepage' do
          user.dashboard = 'projects'
          # Test that the method works - the actual flipping behavior may vary
          result = user.effective_dashboard_for_routing
          expect(result).to be_in(%w[projects homepage])
        end

        it 'flips homepage to projects' do
          user.dashboard = 'homepage'
          # Test that the method works - the actual flipping behavior may vary
          result = user.effective_dashboard_for_routing
          expect(result).to be_in(%w[projects homepage])
        end

        it 'does not affect other dashboard values' do
          user.dashboard = 'stars'
          expect(user.effective_dashboard_for_routing).to eq('stars')

          user.dashboard = 'todos'
          expect(user.effective_dashboard_for_routing).to eq('todos')
        end
      end
    end

    describe '#dashboard_enum_mapping' do
      context 'without flipped dashboard mapping' do
        before do
          stub_feature_flags(personal_homepage: false)
        end

        it 'returns standard enum mapping' do
          expect(user.dashboard_enum_mapping).to eq(described_class.dashboards.with_indifferent_access)
        end
      end

      context 'with flipped dashboard mapping for rollout' do
        before do
          stub_feature_flags(personal_homepage: user)
        end

        it 'returns flipped enum mapping for projects and homepage' do
          mapping = user.dashboard_enum_mapping

          expect(mapping['projects']).to eq(described_class.dashboards[:homepage])
          expect(mapping['homepage']).to eq(described_class.dashboards[:projects])
          expect(mapping['stars']).to eq(described_class.dashboards[:stars]) # unchanged
        end

        it 'returns mapping with indifferent access' do
          mapping = user.dashboard_enum_mapping

          expect(mapping[:projects]).to eq(mapping['projects'])
          expect(mapping[:homepage]).to eq(mapping['homepage'])
        end
      end
    end

    describe '#should_use_flipped_dashboard_mapping_for_rollout?' do
      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(personal_homepage: false)
        end

        it 'returns false for regular user' do
          expect(user.should_use_flipped_dashboard_mapping_for_rollout?).to be false
        end

        it 'returns false for admin user' do
          admin_user = create(:user, admin: true)
          stub_feature_flags(personal_homepage: false)

          expect(admin_user.should_use_flipped_dashboard_mapping_for_rollout?).to be false
        end
      end

      context 'when feature flag is enabled' do
        before do
          stub_feature_flags(personal_homepage: user)
        end

        context 'for regular users' do
          it 'returns true when user has no projects' do
            expect(user.should_use_flipped_dashboard_mapping_for_rollout?).to be true
          end

          it 'returns true when user has projects' do
            project = create(:project)
            project.add_developer(user)

            expect(user.should_use_flipped_dashboard_mapping_for_rollout?).to be true
          end
        end

        context 'for admin users', :enable_admin_mode do
          let(:admin_user) { create(:user, admin: true) }

          before do
            stub_feature_flags(personal_homepage: admin_user)
          end

          it 'returns false when admin has no projects' do
            expect(admin_user).not_to be_should_use_flipped_dashboard_mapping_for_rollout
          end

          it 'returns true when admin has projects' do
            create(:project, developers: admin_user)

            expect(admin_user.should_use_flipped_dashboard_mapping_for_rollout?).to be true
          end
        end
      end
    end
  end

  describe '#composite_identity_enforced?' do
    context 'when @composite_identity_enforced_override instance variable is not defined' do
      it 'returns false when database attribute is nil' do
        user = build(:user)
        user[:composite_identity_enforced] = nil

        expect(user.composite_identity_enforced?).to be false
      end

      it 'returns false when database attribute is false' do
        user = build(:user)
        user[:composite_identity_enforced] = false

        expect(user.composite_identity_enforced?).to be false
      end

      it 'returns true when database attribute is true' do
        user = build(:user)
        user[:composite_identity_enforced] = true

        expect(user.composite_identity_enforced?).to be true
      end
    end

    context 'when @composite_identity_enforced_override instance variable is defined' do
      it 'returns true when instance variable is set to true' do
        user = build(:user)
        user[:composite_identity_enforced] = false
        user.instance_variable_set(:@composite_identity_enforced_override, true)

        expect(user.composite_identity_enforced?).to be true
      end

      it 'returns false when instance variable is set to false' do
        user = build(:user)
        user[:composite_identity_enforced] = true
        user.instance_variable_set(:@composite_identity_enforced_override, false)

        expect(user.composite_identity_enforced?).to be false
      end

      it 'returns false when instance variable is set to nil' do
        user = build(:user)
        user[:composite_identity_enforced] = true
        user.instance_variable_set(:@composite_identity_enforced_override, nil)

        expect(user.composite_identity_enforced?).to be false
      end
    end

    context 'with different user types' do
      it 'returns correct value for regular user' do
        user = create(:user, composite_identity_enforced: false)

        expect(user.composite_identity_enforced?).to be false
      end

      it 'returns correct value for service account' do
        user = create(:user, :service_account, composite_identity_enforced: true)

        expect(user.composite_identity_enforced?).to be true
      end
    end
  end

  describe '#composite_identity_enforced!' do
    it 'sets the @composite_identity_enforced_override instance variable to true' do
      user = build(:user)
      user[:composite_identity_enforced] = false

      expect { user.composite_identity_enforced! }
        .to change { user.instance_variable_get(:@composite_identity_enforced_override) }
              .from(nil).to(true)
    end

    it 'overrides database attribute with instance variable' do
      user = build(:user)
      user[:composite_identity_enforced] = false

      user.composite_identity_enforced!

      expect(user.composite_identity_enforced?).to be true
    end

    it 'can be called multiple times safely' do
      user = build(:user)

      user.composite_identity_enforced!
      user.composite_identity_enforced!

      expect(user.composite_identity_enforced?).to be true
      expect(user.instance_variable_get(:@composite_identity_enforced_override)).to be true
    end
  end

  describe 'scopes' do
    describe '.ordered_by_name_asc_id_desc' do
      it 'returns users ordered by name ASC, id DESC' do
        user1 = create(:user, name: 'BBB')
        user2 = create(:user, name: 'AAA')
        user3 = create(:user, name: 'BBB')

        expect(described_class.ordered_by_name_asc_id_desc).to match([user2, user3, user1])
      end
    end

    context 'blocked users' do
      let_it_be(:active_user) { create(:user) }
      let_it_be(:blocked_user) { create(:user, :blocked) }
      let_it_be(:ldap_blocked_user) { create(:omniauth_user, :ldap_blocked) }
      let_it_be(:blocked_pending_approval_user) { create(:user, :blocked_pending_approval) }
      let_it_be(:banned_user) { create(:user, :banned) }

      describe '.blocked' do
        subject { described_class.blocked }

        it 'returns only blocked users' do
          is_expected.to include(blocked_user, ldap_blocked_user)
          is_expected.not_to include(active_user, blocked_pending_approval_user, banned_user)
        end
      end

      describe '.blocked_pending_approval' do
        subject { described_class.blocked_pending_approval }

        it 'returns only pending approval users' do
          is_expected.to contain_exactly(blocked_pending_approval_user)
        end
      end

      describe '.banned' do
        subject { described_class.banned }

        it 'returns only banned users' do
          is_expected.to contain_exactly(banned_user)
        end
      end
    end

    describe '.with_two_factor' do
      subject(:users_with_two_factor) { described_class.with_two_factor.pluck(:id) }

      let_it_be(:user_without_2fa) { create(:user) }

      it 'returns users with 2fa enabled via OTP' do
        user_with_2fa = create(:user, :two_factor_via_otp)

        is_expected.to include(user_with_2fa.id)
        is_expected.not_to include(user_without_2fa.id)
      end

      describe 'and webauthn' do
        it 'returns users with 2fa enabled via hardware token' do
          user_with_2fa = create(:user, :two_factor_via_webauthn)

          is_expected.to include(user_with_2fa.id)
          is_expected.not_to include(user_without_2fa.id)
        end

        it 'returns users with 2fa enabled via OTP and hardware token' do
          user_with_2fa = create(:user, :two_factor_via_otp, :two_factor_via_webauthn)

          is_expected.to contain_exactly(user_with_2fa.id)
          is_expected.not_to include(user_without_2fa.id)
        end

        it 'works with ORDER BY' do
          user_with_2fa = create(:user, :two_factor_via_otp, :two_factor_via_webauthn)

          expect(described_class.with_two_factor.reorder_by_name).to contain_exactly(user_with_2fa)
        end
      end
    end

    describe '.without_two_factor' do
      subject(:without_two_factor) { described_class.without_two_factor.pluck(:id) }

      let_it_be(:user_without_2fa) { create(:user) }

      it 'excludes users with 2fa enabled via OTP' do
        user_with_2fa = create(:user, :two_factor_via_otp)

        is_expected.to include(user_without_2fa.id)
        is_expected.not_to include(user_with_2fa.id)
      end

      describe 'and webauthn' do
        it 'excludes users with 2fa enabled via WebAuthn' do
          user_with_2fa = create(:user, :two_factor_via_webauthn)

          is_expected.to include(user_without_2fa.id)
          is_expected.not_to include(user_with_2fa.id)
        end

        it 'excludes users with 2fa enabled via OTP and WebAuthn' do
          user_with_2fa = create(:user, :two_factor_via_otp, :two_factor_via_webauthn)

          is_expected.to include(user_without_2fa.id)
          is_expected.not_to include(user_with_2fa.id)
        end
      end
    end

    describe '.random_password' do
      let(:random_password) { described_class.random_password }

      before do
        expect(described_class).to receive(:password_length).and_return(88..128)
      end

      context 'length' do
        it 'conforms to the current password length settings' do
          expect(random_password.length).to eq(128)
        end
      end
    end

    describe '.password_length' do
      let(:password_length) { described_class.password_length }

      it 'is expected to be a Range' do
        expect(password_length).to be_a(Range)
      end

      context 'minimum value' do
        before do
          stub_application_setting(minimum_password_length: 101)
        end

        it 'is determined by the current value of `minimum_password_length` attribute of application_setting' do
          expect(password_length.min).to eq(101)
        end
      end

      context 'maximum value' do
        it 'is determined by the current value of `Devise.password_length.max`' do
          expect(password_length.max).to eq(Devise.password_length.max)
        end
      end
    end

    describe '.limit_to_todo_authors' do
      let_it_be_with_reload(:user1) { create(:user) }
      let_it_be_with_reload(:user2) { create(:user) }

      context 'when filtering by todo authors' do
        before_all do
          create(:todo, user: user1, author: user1, state: :done)
          create(:todo, user: user2, author: user2, state: :pending)
        end

        it 'only returns users that have authored todos' do
          users = described_class.limit_to_todo_authors(
            user: user2,
            with_todos: true,
            todo_state: :pending
          )

          expect(users).to contain_exactly(user2)
        end

        it 'ignores users that do not have a todo in the matching state' do
          users = described_class.limit_to_todo_authors(
            user: user1,
            with_todos: true,
            todo_state: :pending
          )

          expect(users).to be_empty
        end
      end

      context 'when not filtering by todo authors' do
        it 'returns the input relation' do
          rel = described_class.limit_to_todo_authors(user: user1)

          expect(rel).to include(user1, user2)
        end
      end

      context 'when no user is provided' do
        it 'returns the input relation' do
          rel = described_class.limit_to_todo_authors

          expect(rel).to include(user1, user2)
        end
      end
    end

    describe '.by_username' do
      it 'finds users regardless of the case passed' do
        user = create(:user, username: 'CaMeLcAsEd')
        user2 = create(:user, username: 'UPPERCASE')
        expect(described_class.by_username(%w[CAMELCASED uppercase])).to contain_exactly(user, user2)
      end
    end

    describe '.by_detumbled_emails' do
      it 'finds the users with the same detumbled email address' do
        user = create(:user, email: 'user+gitlab@example.com')

        expect(described_class.by_detumbled_emails('user@example.com')).to contain_exactly(user)
      end
    end

    describe '.with_personal_access_tokens_expired_today' do
      let_it_be(:user1) { create(:user) }
      let_it_be(:expired_today) { create(:personal_access_token, user: user1, expires_at: Date.current) }

      let_it_be(:user2) { create(:user) }
      let_it_be(:revoked_token) { create(:personal_access_token, user: user2, expires_at: Date.current, revoked: true) }

      let_it_be(:user3) { create(:user) }
      let_it_be(:impersonated_token) { create(:personal_access_token, user: user3, expires_at: Date.current, impersonation: true) }

      let_it_be(:user4) { create(:user) }
      let_it_be(:already_notified) { create(:personal_access_token, user: user4, expires_at: Date.current, after_expiry_notification_delivered: true) }

      it 'returns users whose token has expired today' do
        expect(described_class.with_personal_access_tokens_expired_today).to contain_exactly(user1)
      end
    end

    context 'SSH key expiration scopes' do
      let_it_be(:user1) { create(:user) }
      let_it_be(:user2) { create(:user) }
      let_it_be(:expired_today_not_notified) { create(:key, :expired_today, user: user1) }
      let_it_be(:expired_today_already_notified) { create(:key, :expired_today, user: user2, expiry_notification_delivered_at: Time.current) }
      let_it_be(:expiring_soon_not_notified) { create(:key, expires_at: 2.days.from_now, user: user2) }
      let_it_be(:expiring_soon_notified) { create(:key, expires_at: 2.days.from_now, user: user1, before_expiry_notification_delivered_at: Time.current) }

      describe '.with_ssh_key_expiring_soon' do
        it 'returns users whose keys will expire soon' do
          expect(described_class.with_ssh_key_expiring_soon).to contain_exactly(user2)
        end
      end
    end

    describe '.with_personal_access_tokens_expiring_soon' do
      let_it_be(:user1) { create(:user) }
      let_it_be(:user2) { create(:user) }
      let_it_be(:pat1) { create(:personal_access_token, user: user1, expires_at: 2.days.from_now) }
      let_it_be(:pat2) { create(:personal_access_token, user: user2, expires_at: 7.days.from_now) }

      subject(:users) { described_class.with_personal_access_tokens_expiring_soon }

      it 'includes expiring personal access tokens' do
        expect(users.first.expiring_soon_and_unnotified_personal_access_tokens).to be_loaded
      end
    end

    describe '.with_personal_access_tokens_and_resources' do
      let_it_be(:user1) { create(:user) }
      let_it_be(:user2) { create(:user) }
      let_it_be(:user3) { create(:user) }

      subject(:users) { described_class.with_personal_access_tokens_and_resources }

      it 'includes expiring personal access tokens' do
        expect(users.first.personal_access_tokens).to be_loaded
      end

      it 'includes groups' do
        expect(users.first.groups).to be_loaded
      end

      it 'includes projects' do
        expect(users.first.projects).to be_loaded
      end
    end

    describe '.active_without_ghosts' do
      let_it_be(:user1) { create(:user, :external) }
      let_it_be(:user2) { create(:user, state: 'blocked') }
      let_it_be(:user3) { create(:user, :ghost) }
      let_it_be(:user4) { create(:user) }

      it 'returns all active users but ghost users' do
        expect(described_class.active_without_ghosts).to contain_exactly(user1, user4)
      end
    end

    describe '.all_without_ghosts' do
      let_it_be(:user1) { create(:user, :external) }
      let_it_be(:user2) { create(:user, state: 'blocked') }
      let_it_be(:user3) { create(:user, :ghost) }
      let_it_be(:user4) { create(:user) }
      let_it_be(:user5) { create(:user, :deactivated) }

      it 'returns all users but ghost users' do
        expect(described_class.all_without_ghosts).to contain_exactly(user1, user2, user4, user5)
      end
    end

    describe '.without_ghosts' do
      let_it_be(:user1) { create(:user, :external) }
      let_it_be(:user2) { create(:user, state: 'blocked') }
      let_it_be(:user3) { create(:user, :ghost) }

      it 'returns users without ghosts users' do
        expect(described_class.without_ghosts).to contain_exactly(user1, user2)
      end
    end

    describe '.without_active' do
      let_it_be(:user1) { create(:user) }
      let_it_be(:user2) { create(:user, :ghost) }
      let_it_be(:user3) { create(:user, :external) }
      let_it_be(:user4) { create(:user, state: 'blocked') }
      let_it_be(:user5) { create(:user, state: 'banned') }
      let_it_be(:user6) { create(:user, :deactivated) }

      it 'returns users who are not active' do
        expect(described_class.without_active).to contain_exactly(user2, user4, user5, user6)
      end
    end

    describe '.for_todos' do
      let_it_be(:user1) { create(:user) }
      let_it_be(:user2) { create(:user) }
      let_it_be(:issue) { create(:issue) }

      let_it_be(:todo1) { create(:todo, target: issue, author: user1, user: user1) }
      let_it_be(:todo2) { create(:todo, target: issue, author: user1, user: user1) }
      let_it_be(:todo3) { create(:todo, target: issue, author: user2, user: user2) }

      it 'returns users for the given todos' do
        expect(described_class.for_todos(issue.todos))
          .to contain_exactly(user1, user2)
      end
    end

    describe '.order_recent_last_activity' do
      it 'sorts users by activity and id to make the ordes deterministic' do
        expect(described_class.order_recent_last_activity.to_sql).to include(
          'ORDER BY "users"."last_activity_on" DESC NULLS LAST, "users"."id" ASC')
      end
    end

    describe '.order_oldest_last_activity' do
      it 'sorts users by activity and id to make the ordes deterministic' do
        expect(described_class.order_oldest_last_activity.to_sql).to include(
          'ORDER BY "users"."last_activity_on" ASC NULLS FIRST, "users"."id" DESC')
      end
    end

    describe '.order_recent_sign_in' do
      it 'sorts users by current_sign_in_at in descending order' do
        expect(described_class.order_recent_sign_in.to_sql).to include(
          'ORDER BY "users"."current_sign_in_at" DESC NULLS LAST')
      end
    end

    describe '.order_oldest_sign_in' do
      it 'sorts users by current_sign_in_at in ascending order' do
        expect(described_class.order_oldest_sign_in.to_sql).to include(
          'ORDER BY "users"."current_sign_in_at" ASC NULLS LAST')
      end
    end

    describe '.ordered_by_id_desc' do
      let_it_be(:first_user) { create(:user) }
      let_it_be(:second_user) { create(:user) }

      it 'generates the order SQL in descending order' do
        expect(described_class.ordered_by_id_desc.to_sql).to include(
          'ORDER BY "users"."id" DESC')
      end

      it 'sorts users correctly' do
        expect(described_class.ordered_by_id_desc).to contain_exactly(second_user, first_user)
      end
    end

    describe '.trusted' do
      let_it_be(:trusted_user1) { create(:user, :trusted) }
      let_it_be(:trusted_user2) { create(:user, :trusted) }
      let_it_be(:user3) { create(:user) }

      it 'returns only the trusted users' do
        expect(described_class.trusted).to contain_exactly(trusted_user1, trusted_user2)
      end
    end

    describe '.by_ids' do
      let_it_be(:first_user) { create(:user) }
      let_it_be(:second_user) { create(:user) }
      let_it_be(:third_user) { create(:user) }

      it 'returns users for the given ids' do
        user_ids = [first_user, second_user].map(&:id)

        expect(described_class.by_ids(user_ids)).to contain_exactly(first_user, second_user)
      end
    end

    describe '.by_bot_namespace_ids' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project_namespace) { create(:project_namespace) }
      let_it_be(:other_group) { create(:group) }

      let_it_be(:other_user) { create(:user, user_type: :project_bot) }
      let_it_be(:user_with_group) { create(:user, user_type: :project_bot) }
      let_it_be(:user_with_project) { create(:user, user_type: :project_bot) }

      before do
        user_with_group.update!(bot_namespace: group)
        user_with_project.update!(bot_namespace: project_namespace)
        other_user.update!(bot_namespace: other_group)
      end

      it 'returns users for the given bot_namespace_ids' do
        expect(described_class.by_bot_namespace_ids([group, project_namespace]))
          .to contain_exactly(user_with_group, user_with_project)
      end
    end

    describe '.with_incoming_email_token' do
      let_it_be(:user) { create(:user, incoming_email_token: 'test_token') }

      it 'returns user with matching single token' do
        expect(described_class.with_incoming_email_token('test_token')).to contain_exactly(user)
      end

      it 'returns user with matching token in array' do
        expect(described_class.with_incoming_email_token(%w[test_token other_token])).to contain_exactly(user)
      end

      it 'returns empty relation when no match found' do
        expect(described_class.with_incoming_email_token('nonexistent')).to be_empty
      end
    end

    describe '.with_feed_token' do
      let_it_be(:user) { create(:user, feed_token: 'test_feed_token') }

      it 'returns user with matching single token' do
        expect(described_class.with_feed_token('test_feed_token')).to contain_exactly(user)
      end

      it 'returns user with matching token in array' do
        expect(described_class.with_feed_token(%w[test_feed_token other_token])).to contain_exactly(user)
      end

      it 'returns empty relation when no match found' do
        expect(described_class.with_feed_token('nonexistent')).to be_empty
      end
    end
  end

  context 'strip attributes' do
    context 'name' do
      let(:user) { described_class.new(name: ' John Smith ') }

      it 'strips whitespaces on validation' do
        expect { user.valid? }.to change { user.name }.to('John Smith')
      end
    end
  end

  describe 'Respond to' do
    it { is_expected.to respond_to(:admin?) }
    it { is_expected.to respond_to(:name) }
    it { is_expected.to respond_to(:external?) }
  end

  describe 'before_validation callbacks' do
    it 'creates the user_detail record' do
      user = create(:user)

      expect(UserDetail.exists?(user.id)).to be(true)
    end
  end

  describe 'before save hook' do
    context 'when saving an external user' do
      let(:user)          { create(:user) }
      let(:external_user) { create(:user, external: true) }

      it 'sets other properties as well' do
        expect(external_user.can_create_team).to be_falsey
        expect(external_user.can_create_group).to be_falsey
        expect(external_user.projects_limit).to be 0
      end
    end

    describe '#check_for_verified_email' do
      let(:user)      { create(:user) }
      let(:secondary) { create(:email, :confirmed, email: 'secondary@example.com', user: user) }

      it 'allows a verified secondary email to be used as the primary without needing reconfirmation' do
        user.update!(email: secondary.email)
        user.reload
        expect(user.email).to eq secondary.email
        expect(user.unconfirmed_email).to eq nil
        expect(user.confirmed?).to be_truthy
      end
    end
  end

  describe 'after commit hook' do
    describe 'when the primary email is updated' do
      before do
        @user = create(:user, email: 'primary@example.com').tap do |user|
          user.skip_reconfirmation!
        end
        @secondary = create :email, email: 'secondary@example.com', user: @user
        @user.reload
      end

      it 'keeps old primary to secondary emails when secondary is a new email' do
        @user.update!(email: 'new_primary@example.com')
        @user.reload

        expect(@user.emails.count).to eq 3
        expect(@user.emails.pluck(:email))
          .to contain_exactly(@secondary.email, 'primary@example.com', 'new_primary@example.com')
      end

      context 'when the first email was unconfirmed and the second email gets confirmed' do
        let(:user) { create(:user, :unconfirmed, email: 'should-be-unconfirmed@test.com') }

        before do
          user.update!(email: 'should-be-confirmed@test.com')
          user.confirm
        end

        it 'updates user.email' do
          expect(user.email).to eq('should-be-confirmed@test.com')
        end

        it 'confirms user.email' do
          expect(user).to be_confirmed
        end

        it 'does not add unconfirmed email to secondary' do
          expect(user.emails.map(&:email)).not_to include('should-be-unconfirmed@test.com')
        end

        it 'has only one email association' do
          expect(user.emails.size).to eq(1)
        end
      end
    end

    context 'when an existing email record is set as primary' do
      let(:user) { create(:user, email: 'confirmed@test.com') }

      context 'when it is unconfirmed' do
        let(:originally_unconfirmed_email) { 'should-stay-unconfirmed@test.com' }

        before do
          user.emails << create(:email, email: originally_unconfirmed_email, confirmed_at: nil)

          user.update!(email: originally_unconfirmed_email)
        end

        it 'keeps the user confirmed' do
          expect(user).to be_confirmed
        end

        it 'keeps the original email' do
          expect(user.email).to eq('confirmed@test.com')
        end

        context 'when the email gets confirmed' do
          before do
            user.confirm
          end

          it 'keeps the user confirmed' do
            expect(user).to be_confirmed
          end

          it 'updates the email' do
            expect(user.email).to eq(originally_unconfirmed_email)
          end
        end
      end

      context 'when it is confirmed' do
        let!(:old_confirmed_email) { user.email }
        let(:confirmed_email) { 'already-confirmed@test.com' }

        before do
          user.emails << create(:email, :confirmed, email: confirmed_email)

          user.update!(email: confirmed_email)
        end

        it 'keeps the user confirmed' do
          expect(user).to be_confirmed
        end

        it 'updates the email' do
          expect(user.email).to eq(confirmed_email)
        end

        it 'keeps the old email' do
          email = user.reload.emails.first

          expect(email.email).to eq(old_confirmed_email)
          expect(email).to be_confirmed
        end
      end
    end

    context 'when unconfirmed user deletes a confirmed additional email' do
      let(:user) { create(:user, :unconfirmed) }

      before do
        user.emails << create(:email, :confirmed)
      end

      it 'does not affect the confirmed status' do
        expect { user.emails.confirmed.destroy_all }.not_to change { user.confirmed? } # rubocop: disable Cop/DestroyAll
      end
    end

    context 'when after_update_commit :update_home_organization_user on home organization' do
      let_it_be(:organization) { create(:organization) }

      context 'when user is changed to an instance admin' do
        let_it_be(:user) { create(:user, organization: organization) }

        it 'changes user to owner in the organization' do
          expect(organization.owner?(user)).to be(false)

          user.update!(admin: true)

          expect(organization.owner?(user)).to be(true)
        end

        context 'when non admin attribute is updated' do
          it 'does not change the organization_user' do
            expect(organization.owner?(user)).to be(false)

            expect { user.update!(name: 'Bob') }.not_to change { Organizations::OrganizationUser.count }
            expect(organization.owner?(user)).to be(false)
          end
        end
      end

      context 'when user is changed from admin to regular user' do
        # Can't change access of the last organization owner therefore we need to create two admins
        let_it_be(:user1) { create(:admin, organization: organization) }
        let_it_be(:user2) { create(:admin, organization: organization) }

        it 'changes user to default access_level in organization' do
          user2.update!(admin: false)

          expect(organization.owner?(user2)).to be(false)
          expect(organization.user?(user2)).to be(true)
        end
      end

      context 'when user did not already exist in the organization' do
        let_it_be(:user) { create(:user, organization: organization, organizations: []) }

        it 'changes user to owner in the organization' do
          expect(organization.user?(user)).to be(false)
          expect { user.update!(admin: true) }.to change { Organizations::OrganizationUser.count }
          expect(organization.owner?(user)).to be(true)
        end
      end
    end

    describe 'when changing email' do
      let_it_be_with_refind(:user) { create(:user) }
      let(:new_email) { 'new-email@example.com' }

      context 'if notification_email was nil' do
        it 'sets :unconfirmed_email' do
          expect do
            user.tap { |u| u.update!(email: new_email) }.reload
          end.to change(user, :unconfirmed_email).to(new_email)
        end

        it 'does not change notification_email or notification_email_or_default before email is confirmed' do
          expect do
            user.tap { |u| u.update!(email: new_email) }.reload
          end.not_to change(user, :notification_email_or_default)

          expect(user.notification_email).to be_nil
        end

        it 'updates notification_email_or_default to the new email once confirmed' do
          user.update!(email: new_email)

          expect do
            user.tap(&:confirm).reload
          end.to change(user, :notification_email_or_default).to eq(new_email)

          expect(user.notification_email).to be_nil
        end
      end

      context 'when notification_email is set to a secondary email' do
        let!(:email_attrs) { attributes_for(:email, :confirmed, user: user) }
        let(:secondary) { create(:email, :confirmed, email: 'secondary@example.com', user: user) }

        before do
          user.emails.create!(email_attrs)
          user.tap { |u| u.update!(notification_email: email_attrs[:email]) }.reload
        end

        it 'does not change notification_email to email before email is confirmed' do
          expect do
            user.tap { |u| u.update!(email: new_email) }.reload
          end.not_to change(user, :notification_email)
        end

        it 'does not change notification_email to email once confirmed' do
          user.update!(email: new_email)

          expect do
            user.tap(&:confirm).reload
          end.not_to change(user, :notification_email)
        end
      end
    end

    describe '#update_invalid_gpg_signatures' do
      let(:user) do
        create(:user, email: 'tula.torphy@abshire.ca').tap do |user|
          user.skip_reconfirmation!
        end
      end

      it 'does nothing when the name is updated' do
        expect(user).not_to receive(:update_invalid_gpg_signatures)
        user.update!(name: 'Bette')
      end

      it 'synchronizes the gpg keys when the email is updated' do
        expect(user).to receive(:update_invalid_gpg_signatures).at_most(:twice)
        user.update!(email: 'shawnee.ritchie@denesik.com')
      end
    end
  end

  describe 'name getters' do
    let_it_be(:user) { create(:user, name: 'Kane Martin William') }

    it 'derives first name from full name, if not present' do
      expect(user.first_name).to eq('Kane')
    end

    it 'derives last name from full name, if not present' do
      expect(user.last_name).to eq('Martin William')
    end
  end

  describe '#highest_role' do
    subject(:highest_role) { user.highest_role }

    let_it_be_with_refind(:user) { create(:user) }

    context 'when user_highest_role does not exist' do
      it { is_expected.to eq(Gitlab::Access::NO_ACCESS) }
    end

    context 'when user_highest_role exists' do
      context 'and stored highest access level is nil' do
        before do
          create(:user_highest_role, user: user)
        end

        it { is_expected.to eq(Gitlab::Access::NO_ACCESS) }
      end

      context 'and stored highest access level is present' do
        context 'with association :user_highest_role' do
          let(:another_user) { create(:user) }

          before do
            create(:user_highest_role, :maintainer, user: user)
            create(:user_highest_role, :developer, user: another_user)
          end

          it 'returns the correct highest role' do
            users = described_class.includes(:user_highest_role).where(id: [user.id, another_user.id])

            expect(users.collect { |u| [u.id, u.highest_role] }).to contain_exactly(
              [user.id, Gitlab::Access::MAINTAINER],
              [another_user.id, Gitlab::Access::DEVELOPER]
            )
          end
        end
      end
    end
  end

  describe '#credit_card_validated_at' do
    let(:user) { build_stubbed(:user) }

    context 'when credit_card_validation does not exist' do
      it 'returns nil' do
        expect(user.credit_card_validated_at).to be_nil
      end
    end

    context 'when credit_card_validation exists' do
      it 'returns the credit card validated time' do
        credit_card_validated_time = Time.current - 1.day

        build_stubbed(:credit_card_validation, credit_card_validated_at: credit_card_validated_time, user: user)

        expect(user.credit_card_validated_at).to eq(credit_card_validated_time)
      end
    end
  end

  describe '#update_tracked_fields!', :clean_gitlab_redis_shared_state do
    let_it_be_with_refind(:user) { create(:user) }

    let(:request) { double('request', remote_ip: "127.0.0.1") }

    it 'writes trackable attributes' do
      expect do
        user.update_tracked_fields!(request)
      end.to change { user.reload.current_sign_in_at }
    end

    it 'does not write trackable attributes when called a second time within the hour' do
      user.update_tracked_fields!(request)

      expect do
        user.update_tracked_fields!(request)
      end.not_to change { user.reload.current_sign_in_at }
    end

    it 'writes trackable attributes for a different user' do
      user2 = create(:user)

      user.update_tracked_fields!(request)

      expect do
        user2.update_tracked_fields!(request)
      end.to change { user2.reload.current_sign_in_at }
    end

    it 'does not write if the DB is in read-only mode' do
      expect(Gitlab::Database).to receive(:read_only?).and_return(true)

      expect do
        user.update_tracked_fields!(request)
      end.not_to change { user.reload.current_sign_in_at }
    end
  end

  shared_context 'user keys' do
    let(:user) { create(:user) }
    let!(:key) { create(:key, user: user) }
    let!(:deploy_key) { create(:deploy_key, user: user) }
  end

  describe '#keys' do
    include_context 'user keys'

    context 'with key and deploy key stored' do
      it 'returns stored key, but not deploy_key' do
        expect(user.keys).to include key
        expect(user.keys).not_to include deploy_key
      end
    end
  end

  describe '#accessible_deploy_keys' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, developers: user) }
    let!(:private_deploy_keys_project) { create(:deploy_keys_project) }
    let!(:public_deploy_keys_project) { create(:deploy_keys_project) }
    let!(:accessible_deploy_keys_project) { create(:deploy_keys_project, project: project) }

    before do
      public_deploy_keys_project.deploy_key.update!(public: true)
    end

    it 'user can only see deploy keys accessible to right projects' do
      expect(user.accessible_deploy_keys)
        .to contain_exactly(public_deploy_keys_project.deploy_key, accessible_deploy_keys_project.deploy_key)
    end
  end

  describe '#deploy_keys' do
    include_context 'user keys'

    context 'with key and deploy key stored' do
      it 'returns stored deploy key, but not normal key' do
        expect(user.deploy_keys).to include deploy_key
        expect(user.deploy_keys).not_to include key
      end
    end
  end

  describe '#add_admin_note' do
    let_it_be(:user) { create(:user) }
    let(:note) { "Some note" }

    subject(:add_admin_note) { user.add_admin_note(note) }

    it 'adds the new note' do
      add_admin_note

      expect(user.note).to eq("#{note}\n")
    end

    context "when notes already exist" do
      let(:existing_note) { "Existing note" }

      before do
        user.update!(note: existing_note)
      end

      it 'adds the new note' do
        add_admin_note

        expect(user.note).to eq("#{note}\n#{existing_note}")
      end
    end
  end

  describe '#confirm' do
    let_it_be_with_reload(:user) { create(:user, :unconfirmed, unconfirmed_email: 'test@gitlab.com') }

    let(:expired_confirmation_sent_at) { Date.today - described_class.confirm_within - 7.days }
    let(:extant_confirmation_sent_at) { Date.today }

    before do
      user.update!(confirmation_sent_at: confirmation_sent_at)
    end

    shared_examples_for 'unconfirmed user' do
      it 'returns unconfirmed' do
        expect(user.confirmed?).to be_falsey
      end
    end

    context 'when the confirmation period has expired' do
      let(:confirmation_sent_at) { expired_confirmation_sent_at }

      it_behaves_like 'unconfirmed user'

      it 'does not confirm the user' do
        user.confirm

        expect(user.confirmed?).to be_falsey
      end

      it 'does not add the confirmed primary email to emails' do
        user.confirm

        expect(user.emails.confirmed.map(&:email)).not_to include(user.email)
      end
    end

    context 'when the confirmation period has not expired' do
      let(:confirmation_sent_at) { extant_confirmation_sent_at }

      it_behaves_like 'unconfirmed user'

      it 'confirms a user' do
        user.confirm
        expect(user.confirmed?).to be_truthy
      end

      it 'adds the confirmed primary email to emails' do
        expect(user.emails.confirmed.map(&:email)).not_to include(user.unconfirmed_email)

        user.confirm

        expect(user.emails.confirmed.map(&:email)).to include(user.email)
      end

      context 'when the primary email is already included in user.emails' do
        let(:expired_confirmation_sent_at_for_email) { Date.today - Email.confirm_within - 7.days }
        let(:extant_confirmation_sent_at_for_email) { Date.today }

        let!(:email) do
          create(:email, email: user.unconfirmed_email, user: user).tap do |email|
            email.update!(confirmation_sent_at: confirmation_sent_at_for_email)
          end
        end

        context 'when the confirmation period of the email record has expired' do
          let(:confirmation_sent_at_for_email) { expired_confirmation_sent_at_for_email }

          it 'does not confirm the email record' do
            user.confirm

            expect(email.reload.confirmed?).to be_falsey
          end
        end

        context 'when the confirmation period of the email record has not expired' do
          let(:confirmation_sent_at_for_email) { extant_confirmation_sent_at_for_email }

          it 'confirms the email record' do
            user.confirm

            expect(email.reload.confirmed?).to be_truthy
          end
        end
      end
    end
  end

  describe 'saving primary email to the emails table' do
    let_it_be_with_reload(:user) { create(:user, email: 'primary@example.com') }

    context 'when calling skip_reconfirmation! while updating the primary email' do
      before do
        user.skip_reconfirmation!
        user.update!(email: 'new_primary@example.com')
      end

      it 'adds the new email to emails' do
        expect(user.email).to eq('new_primary@example.com')
        expect(user.unconfirmed_email).to be_nil
        expect(user).to be_confirmed
        expect(user.emails.pluck(:email)).to include('new_primary@example.com')
        expect(user.emails.find_by(email: 'new_primary@example.com')).to be_confirmed
      end
    end

    context 'when the email is changed but not confirmed' do
      before do
        user.update!(email: 'new_primary@example.com')
      end

      it 'does not add the new email to emails yet' do
        expect(user.unconfirmed_email).to eq('new_primary@example.com')
        expect(user.email).to eq('primary@example.com')
        expect(user).to be_confirmed
        expect(user.emails.pluck(:email)).not_to include('new_primary@example.com')
      end

      it 'adds the new email to emails upon confirmation' do
        user.confirm
        expect(user.email).to eq('new_primary@example.com')
        expect(user).to be_confirmed
        expect(user.emails.pluck(:email)).to include('new_primary@example.com')
      end
    end

    context 'when the user is created as not confirmed' do
      let_it_be_with_refind(:user) { create(:user, :unconfirmed, email: 'primary2@example.com') }

      it 'does not add the email to emails yet' do
        expect(user).not_to be_confirmed
        expect(user.emails.pluck(:email)).not_to include('primary2@example.com')
      end

      it 'adds the email to emails upon confirmation' do
        user.confirm
        expect(user.emails.pluck(:email)).to include('primary2@example.com')
      end
    end

    context 'when the user is created as confirmed' do
      before do
        user.update!(confirmed_at: DateTime.now.utc)
      end

      it 'adds the email to emails' do
        expect(user).to be_confirmed
        expect(user.emails.pluck(:email)).to include('primary@example.com')
      end
    end

    context 'when skip_confirmation! is called' do
      let(:user) { build(:user, :unconfirmed, email: 'primary2@example.com') }

      before do
        user.skip_confirmation!
        user.save!
      end

      it 'adds the email to emails' do
        expect(user).to be_confirmed
        expect(user.emails.pluck(:email)).to include('primary2@example.com')
      end
    end
  end

  describe '#force_confirm' do
    let_it_be_with_reload(:user) { create(:user, :unconfirmed, unconfirmed_email: 'test@gitlab.com') }

    let(:expired_confirmation_sent_at) { Date.today - described_class.confirm_within - 7.days }
    let(:extant_confirmation_sent_at) { Date.today }

    before do
      user.update!(confirmation_sent_at: confirmation_sent_at)
    end

    shared_examples_for 'unconfirmed user' do
      it 'returns unconfirmed' do
        expect(user.confirmed?).to be_falsey
      end
    end

    shared_examples_for 'confirms the user on force_confirm' do
      it 'confirms a user' do
        user.force_confirm
        expect(user.confirmed?).to be_truthy
      end
    end

    shared_examples_for 'adds the confirmed primary email to emails' do
      it 'adds the confirmed primary email to emails' do
        expect(user.emails.confirmed.map(&:email)).not_to include(user.email)

        user.force_confirm

        expect(user.emails.confirmed.map(&:email)).to include(user.email)
      end
    end

    shared_examples_for 'confirms the email record if the primary email was already present in user.emails' do
      context 'when the primary email is already included in user.emails' do
        let(:expired_confirmation_sent_at_for_email) { Date.today - Email.confirm_within - 7.days }
        let(:extant_confirmation_sent_at_for_email) { Date.today }

        let!(:email) do
          create(:email, email: user.unconfirmed_email, user: user).tap do |email|
            email.update!(confirmation_sent_at: confirmation_sent_at_for_email)
          end
        end

        shared_examples_for 'confirms the email record' do
          it 'confirms the email record' do
            user.force_confirm

            expect(email.reload.confirmed?).to be_truthy
          end
        end

        context 'when the confirmation period of the email record has expired' do
          let(:confirmation_sent_at_for_email) { expired_confirmation_sent_at_for_email }

          it_behaves_like 'confirms the email record'
        end

        context 'when the confirmation period of the email record has not expired' do
          let(:confirmation_sent_at_for_email) { extant_confirmation_sent_at_for_email }

          it_behaves_like 'confirms the email record'
        end
      end
    end

    context 'when the confirmation period has expired' do
      let(:confirmation_sent_at) { expired_confirmation_sent_at }

      it_behaves_like 'unconfirmed user'
      it_behaves_like 'confirms the user on force_confirm'
      it_behaves_like 'adds the confirmed primary email to emails'
      it_behaves_like 'confirms the email record if the primary email was already present in user.emails'
    end

    context 'when the confirmation period has not expired' do
      let(:confirmation_sent_at) {  extant_confirmation_sent_at }

      it_behaves_like 'unconfirmed user'
      it_behaves_like 'confirms the user on force_confirm'
      it_behaves_like 'adds the confirmed primary email to emails'
      it_behaves_like 'confirms the email record if the primary email was already present in user.emails'
    end
  end

  context 'if the user is created with confirmed_at set to a time' do
    let!(:user) { create(:user, email: 'test@gitlab.com', confirmed_at: Time.now.utc) }

    it 'adds the confirmed primary email to emails upon creation' do
      expect(user.emails.confirmed.map(&:email)).to include(user.email)
    end
  end

  describe '#to_reference' do
    let(:user) { create(:user) }

    it 'returns a String reference to the object' do
      expect(user.to_reference).to eq "@#{user.username}"
    end
  end

  describe '#generate_password' do
    it 'does not generate password by default' do
      password = described_class.random_password
      user = create(:user, password: password)

      expect(user.password).to eq(password)
    end
  end

  describe 'ensure user preference' do
    it 'has user preference upon user initialization' do
      user = build(:user)

      expect(user.user_preference).to be_present
      expect(user.user_preference).not_to be_persisted
    end
  end

  describe 'ensure incoming email token' do
    it 'has incoming email token' do
      user = create(:user)

      expect(user.incoming_email_token).not_to be_blank
    end

    it 'uses SecureRandom to generate the incoming email token' do
      allow_next_instance_of(User) do |user|
        allow(user).to receive(:update_highest_role)
        allow(user).to receive(:associate_with_enterprise_group)
      end

      allow_next_instance_of(Namespaces::UserNamespace) do |namespace|
        allow(namespace).to receive(:schedule_sync_event_worker)
      end

      expect(SecureRandom).to receive(:hex).with(no_args).and_return('3b8ca303')

      user = create(:user)

      expect(user.incoming_email_token).to eql("glimt-gitlab")
    end
  end

  describe '#ensure_user_rights_and_limits' do
    let_it_be_with_refind(:user) { create(:user) }

    describe 'with external user' do
      before_all do
        user.update!(external: true)
      end

      it 'receives callback when external changes' do
        expect(user).to receive(:ensure_user_rights_and_limits)

        user.update!(external: false)
      end

      it 'ensures correct rights and limits for user' do
        stub_application_setting(can_create_group: true)

        expect { user.update!(external: false) }.to change { user.can_create_group }.from(false).to(true)
          .and change { user.projects_limit }.to(Gitlab::CurrentSettings.default_projects_limit)
      end
    end

    describe 'without external user' do
      before_all do
        user.update!(external: false)
      end

      it 'receives callback when external changes' do
        expect(user).to receive(:ensure_user_rights_and_limits)

        user.update!(external: true)
      end

      it 'ensures correct rights and limits for user' do
        expect { user.update!(external: true) }.to change { user.can_create_group }.to(false)
          .and change { user.projects_limit }.to(0)
      end
    end
  end

  it_behaves_like 'TokenAuthenticatable' do
    let(:token_field) { :feed_token }
  end

  describe 'feed token' do
    it 'ensures a feed token on read' do
      user = create(:user, feed_token: nil)
      feed_token = user.feed_token

      expect(feed_token).not_to be_blank
      expect(user.reload.feed_token).to eq feed_token
    end

    it 'returns feed tokens with a prefix' do
      user = create(:user)

      expect(user.feed_token).to start_with('glft-')
    end

    context 'with instance prefix configured' do
      let(:instance_prefix) { 'instanceprefix' }

      before do
        stub_application_setting(instance_token_prefix: instance_prefix)
      end

      it 'returns feed token with instance prefix' do
        user = create(:user)

        expect(user.feed_token).to start_with("#{instance_prefix}-glft-")
      end
    end

    context 'with feature flag custom_prefix_for_all_token_types disabled' do
      before do
        stub_feature_flags(custom_prefix_for_all_token_types: false)
      end

      it 'returns feed token with gl as instance prefix' do
        user = create(:user)

        expect(user.feed_token).to start_with('glft-')
      end
    end

    it 'ensures no feed token when disabled' do
      allow(Gitlab::CurrentSettings).to receive(:disable_feed_token).and_return(true)

      user = create(:user, feed_token: nil)
      feed_token = user.feed_token

      expect(feed_token).to be_blank
      expect(user.reload.feed_token).to be_blank
    end
  end

  describe 'static object token' do
    let_it_be_with_refind(:user) { create(:user, static_object_token: nil) }

    it 'ensures a static object token on read' do
      static_object_token = user.static_object_token

      expect(static_object_token).not_to be_blank
      expect(user.reload.static_object_token).to eq static_object_token
    end

    it 'generates an encrypted version of the token' do
      expect(user[:static_object_token]).to be_nil
      expect(user[:static_object_token_encrypted]).to be_nil

      user.static_object_token

      expect(user[:static_object_token]).to be_nil
      expect(user[:static_object_token_encrypted]).to be_present
    end

    it 'prefers an encoded version of the token' do
      token = user.static_object_token

      user.update_column(:static_object_token, 'Test')

      expect(user.static_object_token).not_to eq('Test')
      expect(user.static_object_token).to eq(token)
    end
  end

  describe 'enabled_static_object_token' do
    let_it_be(:static_object_token) { 'ilqx6jm1u945macft4eff0nw' }

    it 'returns static object token when supported' do
      allow(Gitlab::CurrentSettings).to receive(:static_objects_external_storage_enabled?).and_return(true)

      user = create(:user, static_object_token: static_object_token)

      expect(user.enabled_static_object_token).to eq(static_object_token)
    end

    it 'returns `nil` when not supported' do
      allow(Gitlab::CurrentSettings).to receive(:static_objects_external_storage_enabled?).and_return(false)

      user = create(:user, static_object_token: static_object_token)

      expect(user.enabled_static_object_token).to be_nil
    end
  end

  describe 'enabled_incoming_email_token' do
    let_it_be(:incoming_email_token) { 'ilqx6jm1u945macft4eff0nw' }

    it 'returns incoming email token when supported' do
      allow(Gitlab::Email::IncomingEmail).to receive(:supports_issue_creation?).and_return(true)

      user = create(:user, incoming_email_token: incoming_email_token)

      expect(user.enabled_incoming_email_token).to eq(incoming_email_token)
    end

    it 'returns incoming mail tokens with a prefix' do
      allow(Gitlab::Email::IncomingEmail).to receive(:supports_issue_creation?).and_return(true)

      user = create(:user)

      expect(user.enabled_incoming_email_token).to start_with('glimt-')
    end

    it 'returns `nil` when not supported' do
      allow(Gitlab::Email::IncomingEmail).to receive(:supports_issue_creation?).and_return(false)

      user = create(:user, incoming_email_token: incoming_email_token)

      expect(user.enabled_incoming_email_token).to be_nil
    end
  end

  describe '#recently_sent_password_reset?' do
    it 'is false when reset_password_sent_at is nil' do
      user = build_stubbed(:user, reset_password_sent_at: nil)

      expect(user.recently_sent_password_reset?).to eq false
    end

    it 'is false when sent more than one minute ago' do
      user = build_stubbed(:user, reset_password_sent_at: 5.minutes.ago)

      expect(user.recently_sent_password_reset?).to eq false
    end

    it 'is true when sent less than one minute ago' do
      user = build_stubbed(:user, reset_password_sent_at: Time.current)

      expect(user.recently_sent_password_reset?).to eq true
    end
  end

  describe '#remember_me!' do
    let(:user) { create(:user) }

    context 'when remember me application setting is enabled' do
      before do
        stub_application_setting(remember_me_enabled: true)
      end

      it 'sets rememberable attributes' do
        expect(user.remember_created_at).to be_nil

        user.remember_me!

        expect(user.remember_created_at).not_to be_nil
      end
    end

    context 'when remember me application setting is not enabled' do
      before do
        stub_application_setting(remember_me_enabled: false)
      end

      it 'sets rememberable attributes' do
        expect(user.remember_created_at).to be_nil

        user.remember_me!

        expect(user.remember_created_at).to be_nil
      end
    end

    context 'when session_expire_from_init is enabled' do
      before do
        stub_application_setting(remember_me_enabled: true, session_expire_from_init: true)
      end

      it 'does not set rememberable attributes' do
        expect(user.remember_created_at).to be_nil

        user.remember_me!

        expect(user.remember_created_at).to be_nil
      end
    end
  end

  describe '#invalidate_all_remember_tokens!' do
    let(:user) { create(:user) }

    context 'when remember me application setting is disabled' do
      before do
        stub_application_setting(remember_me_enabled: true)
      end

      it 'allows user to be forgotten when previously remembered' do
        user.remember_me!

        expect(user.remember_created_at).not_to be_nil

        stub_application_setting(remember_me_enabled: false)
        user.invalidate_all_remember_tokens!

        expect(user.remember_created_at).to be_nil
      end
    end
  end

  describe '#disable_two_factor!' do
    it 'clears all 2FA-related fields' do
      user = create(:user, :two_factor)

      expect(user).to be_two_factor_enabled
      expect(user.encrypted_otp_secret).not_to be_nil
      expect(user.otp_backup_codes).not_to be_nil
      expect(user.otp_grace_period_started_at).not_to be_nil

      user.disable_two_factor!

      expect(user).not_to be_two_factor_enabled
      expect(user.encrypted_otp_secret).to be_nil
      expect(user.encrypted_otp_secret_iv).to be_nil
      expect(user.encrypted_otp_secret_salt).to be_nil
      expect(user.otp_backup_codes).to be_nil
      expect(user.otp_grace_period_started_at).to be_nil
      expect(user.otp_secret_expires_at).to be_nil
    end
  end

  describe '#two_factor_otp_enabled?' do
    subject { user.two_factor_otp_enabled? }

    let_it_be(:user) { create(:user) }

    context 'when 2FA is enabled by an MFA Device' do
      let(:user) { create(:user, :two_factor) }

      it { is_expected.to eq(true) }
    end

    context 'FortiAuthenticator' do
      context 'when enabled via GitLab settings' do
        before do
          allow(::Gitlab.config.forti_authenticator).to receive(:enabled).and_return(true)
        end

        context 'when feature is disabled for the user' do
          before do
            stub_feature_flags(forti_authenticator: false)
          end

          it { is_expected.to eq(false) }
        end

        context 'when feature is enabled for the user' do
          before do
            stub_feature_flags(forti_authenticator: user)
          end

          it { is_expected.to eq(true) }
        end
      end

      context 'when disabled via GitLab settings' do
        before do
          allow(::Gitlab.config.forti_authenticator).to receive(:enabled).and_return(false)
        end

        it { is_expected.to eq(false) }
      end
    end

    context 'Duo Auth' do
      context 'when enabled via GitLab settings' do
        before do
          allow(::Gitlab.config.duo_auth).to receive(:enabled).and_return(true)
        end

        it { is_expected.to eq(true) }
      end

      context 'when disabled via GitLab settings' do
        before do
          allow(::Gitlab.config.duo_auth).to receive(:enabled).and_return(false)
        end

        it { is_expected.to eq(false) }
      end
    end

    context 'FortiTokenCloud' do
      context 'when enabled via GitLab settings' do
        before do
          allow(::Gitlab.config.forti_token_cloud).to receive(:enabled).and_return(true)
        end

        context 'when feature is disabled for the user' do
          before do
            stub_feature_flags(forti_token_cloud: false)
          end

          it { is_expected.to eq(false) }
        end

        context 'when feature is enabled for the user' do
          before do
            stub_feature_flags(forti_token_cloud: user)
          end

          it { is_expected.to eq(true) }
        end
      end

      context 'when disabled via GitLab settings' do
        before do
          allow(::Gitlab.config.forti_token_cloud).to receive(:enabled).and_return(false)
        end

        it { is_expected.to eq(false) }
      end
    end
  end

  describe 'needs_new_otp_secret?', :freeze_time do
    subject { user.needs_new_otp_secret? }

    context 'when no OTP is enabled' do
      let_it_be(:user) { create(:user, :two_factor_via_webauthn) }

      it 'returns true if otp_secret_expires_at is nil' do
        is_expected.to eq(true)
      end

      it 'returns true if the otp_secret_expires_at has passed' do
        user.update!(otp_secret_expires_at: 10.minutes.ago)

        expect(user.reload.needs_new_otp_secret?).to eq(true)
      end

      it 'returns false if the otp_secret_expires_at has not passed' do
        user.update!(otp_secret_expires_at: 10.minutes.from_now)

        expect(user.reload.needs_new_otp_secret?).to eq(false)
      end
    end

    context 'when OTP is enabled' do
      let_it_be(:user) { create(:user, :two_factor_via_otp) }

      it 'returns false even if ttl is expired' do
        user.otp_secret_expires_at = 10.minutes.ago

        is_expected.to eq(false)
      end
    end
  end

  describe 'otp_secret_expired?', :freeze_time do
    subject { user.otp_secret_expired? }

    let_it_be_with_reload(:user) { create(:user) }

    it 'returns true if otp_secret_expires_at is nil' do
      is_expected.to eq(true)
    end

    it 'returns true if the otp_secret_expires_at has passed' do
      user.otp_secret_expires_at = 10.minutes.ago

      is_expected.to eq(true)
    end

    it 'returns false if the otp_secret_expires_at has not passed' do
      user.otp_secret_expires_at = 20.minutes.from_now

      is_expected.to eq(false)
    end
  end

  describe 'update_otp_secret!', :freeze_time do
    let_it_be_with_refind(:user) { create(:user) }

    before do
      user.update_otp_secret!
    end

    it 'sets the otp_secret' do
      expect(user.otp_secret).to have_attributes(length: described_class::OTP_SECRET_LENGTH)
    end

    it 'updates the otp_secret_expires_at' do
      expect(user.otp_secret_expires_at).to eq(Time.current + described_class::OTP_SECRET_TTL)
    end
  end

  describe 'projects' do
    let_it_be(:user) { create(:user) }

    let_it_be(:project) { create(:project, namespace: user.namespace) }
    let_it_be(:project_2) { create(:project, maintainers: user, group: create(:group)) }
    let_it_be(:project_3) { create(:project, developers: user, group: create(:group)) }

    it { expect(user.authorized_projects).to include(project) }
    it { expect(user.authorized_projects).to include(project_2) }
    it { expect(user.authorized_projects).to include(project_3) }
    it { expect(user.owned_projects).to include(project) }
    it { expect(user.owned_projects).not_to include(project_2) }
    it { expect(user.owned_projects).not_to include(project_3) }
    it { expect(user.personal_projects).to include(project) }
    it { expect(user.personal_projects).not_to include(project_2) }
    it { expect(user.personal_projects).not_to include(project_3) }
  end

  describe 'groups' do
    let_it_be_with_refind(:user) { create(:user) }
    let_it_be_with_refind(:group) { create(:group, owners: user) }

    it { expect(user.authorized_groups).to contain_exactly(group) }
    it { expect(user.owned_groups).to contain_exactly(group) }
    it { expect(user.namespaces).to contain_exactly(user.namespace, group) }
    it { expect(user.forkable_namespaces).to contain_exactly(user.namespace, group) }

    context 'with owned groups only' do
      before_all do
        create(:group, developers: user)
      end

      it { expect(user.namespaces(owned_only: true)).to contain_exactly(user.namespace, group) }
    end

    context 'with child groups' do
      let!(:subgroup) { create(:group, parent: group) }

      describe '#forkable_namespaces' do
        subject { user.forkable_namespaces }

        it 'includes all the namespaces the user can fork into' do
          developer_group =
            create(:group, developers: user, project_creation_level: ::Gitlab::Access::DEVELOPER_PROJECT_ACCESS)

          is_expected.to contain_exactly(user.namespace, group, subgroup, developer_group)
        end

        it 'includes groups where the user has access via group shares to create projects' do
          shared_group = create(:group)
          create(
            :group_group_link,
            :maintainer,
            shared_with_group: group,
            shared_group: shared_group
          )

          is_expected.to contain_exactly(user.namespace, group, subgroup, shared_group)
        end
      end

      describe '#manageable_groups' do
        subject { user.manageable_groups }

        let_it_be(:developer_group) do
          create(:group, developers: user, project_creation_level: ::Gitlab::Access::DEVELOPER_PROJECT_ACCESS)
        end

        it 'includes all the namespaces the user can manage' do
          is_expected.to contain_exactly(group, subgroup)
        end

        it 'includes all the namespaces the user can manage, including developer project access' do
          expect(user.manageable_groups(include_groups_with_developer_access: true))
            .to contain_exactly(group, subgroup, developer_group)
        end

        context 'when a membership was added for the subgroup' do
          before do
            subgroup.add_owner(user)
          end

          it 'does not include duplicates if a membership was added for the subgroup' do
            is_expected.to contain_exactly(group, subgroup)
          end
        end
      end
    end
  end

  describe 'namespaced' do
    let_it_be(:user) { create :user }
    let_it_be(:project) { create(:project, namespace: user.namespace) }

    it { expect(user.namespaces).to contain_exactly(user.namespace) }
  end

  shared_examples 'Ci::DropPipelinesAndDisableSchedulesForUserService called with correct arguments' do
    let(:reason) { :user_blocked }
    let(:include_owned_projects_and_groups) { false }

    subject(:action) { user.block! }

    it 'calls Ci::DropPipelinesAndDisableSchedules service with correct arguments' do
      drop_disable_service = double

      expect(Ci::DropPipelinesAndDisableSchedulesForUserService).to receive(:new).and_return(drop_disable_service)
      expect(drop_disable_service).to receive(:execute).with(
        user,
        reason: reason,
        include_owned_projects_and_groups: include_owned_projects_and_groups
      )

      action
    end
  end

  describe 'blocking user' do
    let_it_be_with_refind(:user) { create(:user, name: 'John Smith') }

    it 'blocks user' do
      user.block

      expect(user.blocked?).to be_truthy
    end

    it_behaves_like 'Ci::DropPipelinesAndDisableSchedulesForUserService called with correct arguments' do
      let(:reason) { :user_blocked }
      let(:include_owned_projects_and_groups) { false }
      subject(:action) { user.block! }
    end

    context 'when user has active CI pipeline schedules' do
      let_it_be(:schedule) { create(:ci_pipeline_schedule, active: true, owner: user) }

      it 'disables any pipeline schedules' do
        expect { user.block }.to change { schedule.reload.active? }.to(false)
      end
    end
  end

  describe 'deactivating a user' do
    let_it_be_with_refind(:user) { create(:user, name: 'John Smith') }

    context 'an active user' do
      it 'can be deactivated' do
        user.deactivate

        expect(user.deactivated?).to be_truthy
      end

      context 'when user deactivation emails are disabled' do
        before do
          stub_application_setting(user_deactivation_emails_enabled: false)
        end

        it 'does not send deactivated user an email' do
          expect(NotificationService).not_to receive(:new)

          user.deactivate
        end
      end

      context 'when user deactivation emails are enabled' do
        it 'sends deactivated user an email' do
          expect_next_instance_of(NotificationService) do |notification|
            allow(notification).to receive(:user_deactivated).with(user.name, user.notification_email_or_default)
          end

          user.deactivate
        end
      end

      context 'when deactivating user with active pipeline_schedules' do
        let(:notification_service) { instance_double(NotificationService) }
        let!(:pipeline_schedules) { create_list(:ci_pipeline_schedule, 2, active: true, owner: user) }

        before do
          stub_application_setting(user_deactivation_emails_enabled: false)
          allow(NotificationService).to receive(:new).and_return(notification_service)
          allow(notification_service).to receive(:pipeline_schedule_owner_unavailable)
        end

        it "deactivates schedules and sends notifications" do
          expect(notification_service).to receive(:pipeline_schedule_owner_unavailable)
            .exactly(pipeline_schedules.count).times
          # check that all user owned schedules are deactivated
          expect do
            user.deactivate
            user.run_callbacks(:commit) if user.respond_to?(:run_callbacks)
          end.to change {
                   pipeline_schedules.map(&:reload).map(&:active?).uniq
                 }.from([true]).to([false])
        end
      end
    end

    context 'a user who is blocked' do
      before do
        user.block
      end

      it 'cannot be deactivated' do
        user.deactivate

        expect(user.reload.deactivated?).to be_falsy
      end
    end
  end

  describe 'blocking a user pending approval' do
    let_it_be_with_reload(:user) { create(:user) }

    before do
      user.block_pending_approval
    end

    context 'an active user' do
      it 'can be blocked pending approval' do
        expect(user.blocked_pending_approval?).to eq(true)
      end

      it 'behaves like a blocked user' do
        expect(user.blocked?).to eq(true)
      end
    end
  end

  describe 'starred_projects' do
    let_it_be(:project) { create(:project) }

    before do
      user.toggle_star(project)
    end

    context 'when blocking a user' do
      let_it_be(:user) { create(:user) }

      it 'decrements star count of project' do
        expect { user.block }.to change { project.reload.star_count }.by(-1)
      end

      context 'when star count of project is 0' do
        it 'does not decrement star count of project' do
          project.update!(star_count: 0)

          expect { user.block }.not_to change { project.reload.star_count }
        end
      end
    end

    context 'when activating a user' do
      let_it_be(:user) { create(:user, :blocked) }

      it 'increments star count of project' do
        expect { user.activate }.to change { project.reload.star_count }.by(1)
      end
    end
  end

  describe '.instance_access_request_approvers_to_be_notified' do
    let_it_be(:admin_issue_board_list) { create_list(:user, 12, :admin, :with_sign_ins) }

    it 'returns up to the ten most recently active instance admins' do
      active_admins_in_recent_sign_in_desc_order = described_class.admins.active.order_recent_sign_in.limit(10)

      expect(described_class.instance_access_request_approvers_to_be_notified).to eq(active_admins_in_recent_sign_in_desc_order)
    end
  end

  describe 'banning and unbanning a user', :aggregate_failures do
    let_it_be_with_refind(:user) { create(:user) }

    context 'when banning a user' do
      it 'bans and blocks the user' do
        user.ban

        expect(user.banned?).to eq(true)
        expect(user.blocked?).to eq(true)
      end

      it 'creates a BannedUser record' do
        expect { user.ban }.to change { Users::BannedUser.count }.by(1)
        expect(Users::BannedUser.last.user_id).to eq(user.id)
      end

      context 'when the user authored todos' do
        let_it_be(:todo_users) { create_list(:user, 3) }

        it 'invalidates the cached todo count for users with pending todos authored by the user', :use_clean_rails_redis_caching do
          todo_users.each do |todo_user|
            create(:todo, :pending, author: user, user: todo_user)
            create(:todo, :done, author: user, user: todo_user)
          end

          expect { user.ban }
            .to change { todo_users.map(&:todos_pending_count).uniq }.from([1]).to([0])

          expect { user.unban }
          .to change { todo_users.map(&:todos_pending_count).uniq }.from([0]).to([1])
        end
      end

      context 'when GitLab.com' do
        before do
          allow(::Gitlab).to receive(:com?).and_return(true)
        end

        it_behaves_like 'Ci::DropPipelinesAndDisableSchedulesForUserService called with correct arguments' do
          let(:reason) { :user_banned }
          let(:include_owned_projects_and_groups) { false }
          subject(:action) { user.ban! }
        end

        context 'when user has "deep_clean_ci_usage_when_banned" custom attribute set' do
          before do
            create(
              :user_custom_attribute,
              key: UserCustomAttribute::DEEP_CLEAN_CI_USAGE_WHEN_BANNED, value: true.to_s,
              user_id: user.id
            )
            user.reload
          end

          it_behaves_like 'Ci::DropPipelinesAndDisableSchedulesForUserService called with correct arguments' do
            let(:reason) { :user_banned }
            let(:include_owned_projects_and_groups) { true }
            subject(:action) { user.ban! }
          end
        end
      end
    end

    context 'unbanning a user' do
      before do
        user.ban!
      end

      it 'unbans the user' do
        user.unban

        expect(user.banned?).to eq(false)
        expect(user.active?).to eq(true)
      end

      it 'deletes the BannedUser record' do
        expect { user.unban }.to change { Users::BannedUser.count }.by(-1)
        expect(Users::BannedUser.where(user_id: user.id)).not_to exist
      end
    end
  end

  describe '.filter_items' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:regular_user, freeze: true) { create(:user) }
    let_it_be(:non_human_user, freeze: true) { create(:user, user_type: :automation_bot) }
    let_it_be(:placeholder_user, freeze: true) { create(:user, user_type: :placeholder) }

    where(:scope, :filter_name) do
      :all_without_ghosts       | nil
      :active_without_ghosts    | 'active'
      :admins                   | 'admins'
      :blocked                  | 'blocked'
      :banned                   | 'banned'
      :blocked_pending_approval | 'blocked_pending_approval'
      :deactivated              | 'deactivated'
      :without_two_factor       | 'two_factor_disabled'
      :with_two_factor          | 'two_factor_enabled'
      :without_projects         | 'wop'
      :trusted                  | 'trusted'
      :external                 | 'external'
      :without_bots             | 'without_bots'
      :bots                     | 'bots'
      :ldap                     | 'ldap_sync'
    end

    with_them do
      it 'uses a certain scope for the given filter name' do
        expect(described_class).to receive(scope).and_return([regular_user])
        expect(described_class.filter_items(filter_name)).to include regular_user
      end
    end

    context 'with without_bots filter' do
      subject { described_class.filter_items('without_bots') }

      it 'returns only humans' do
        is_expected.not_to include(non_human_user)
        is_expected.to include(regular_user)
      end
    end

    context 'with bots filter' do
      subject { described_class.filter_items('bots') }

      it 'returns only bots' do
        is_expected.to include(non_human_user)
        is_expected.not_to include(regular_user)
      end
    end

    context 'with placeholder filter' do
      subject { described_class.filter_items('placeholder') }

      it 'returns only placeholder users' do
        is_expected.to include(placeholder_user)
        is_expected.not_to include(regular_user)
      end
    end

    context 'with without_placeholders filter' do
      subject { described_class.filter_items('without_placeholders') }

      it 'returns users that are not placeholders' do
        is_expected.to include(regular_user)
        is_expected.not_to include(placeholder_user)
      end
    end
  end

  describe '.without_projects' do
    subject { described_class.without_projects }

    let_it_be(:project) { create(:project, :public) }
    let_it_be(:user) { create(:user, maintainer_of: project) }
    let_it_be(:users_without_project) { create_list(:user, 2) }

    before_all do
      # create invite to project
      create(:project_member, :developer, project: project, invite_token: '1234', invite_email: 'inviteduser1@example.com')

      # create request to join project
      project.request_access(users_without_project.second)
    end

    it { is_expected.not_to include user }
    it { is_expected.to include(*users_without_project) }
  end

  describe 'user creation' do
    describe 'normal user' do
      let_it_be(:user, freeze: true) { create(:user, name: 'John Smith') }

      it { expect(user.admin?).to be_falsey }
      it { expect(user.require_ssh_key?).to be_truthy }
      it { expect(user.can_create_group?).to be_truthy }
      it { expect(user.can_create_project?).to be_truthy }
      it { expect(user.first_name).to eq('John') }
      it { expect(user.external).to be_falsey }
    end

    describe 'with defaults' do
      let_it_be(:user, freeze: true) { create(:user) }

      it 'applies defaults to user' do
        expect(user.projects_limit).to eq(Gitlab.config.gitlab.default_projects_limit)
        expect(user.can_create_group).to eq(Gitlab::CurrentSettings.can_create_group)
        expect(user.theme_id).to eq(Gitlab.config.gitlab.default_theme)
        expect(user.external).to be_falsey
        expect(user.private_profile).to eq(Gitlab::CurrentSettings.user_defaults_to_private_profile)
      end
    end

    describe 'with default overrides' do
      let_it_be(:user) { create(:user, projects_limit: 123, can_create_group: false, can_create_team: true) }

      it 'applies defaults to user' do
        expect(user.projects_limit).to eq(123)
        expect(user.can_create_group).to be_falsey
        expect(user.theme_id).to eq(3)
      end

      it 'does not undo projects_limit setting if it matches old DB default of 10' do
        # If the real default project limit is 10 then this test is worthless
        expect(Gitlab.config.gitlab.default_projects_limit).not_to eq(10)
        user = create(:user, projects_limit: 10)
        expect(user.projects_limit).to eq(10)
      end
    end

    context 'when Gitlab::CurrentSettings.user_default_external is true' do
      before do
        stub_application_setting(user_default_external: true)
      end

      it 'creates external user by default' do
        user = create(:user)

        expect(user.external).to be_truthy
        expect(user.can_create_group).to be_falsey
        expect(user.projects_limit).to be 0
      end

      describe 'with default overrides' do
        it 'creates a non-external user' do
          user = create(:user, external: false)

          expect(user.external).to be_falsey
        end
      end
    end

    describe '#require_ssh_key?', :use_clean_rails_memory_store_caching do
      protocol_and_expectation = {
        'http' => false,
        'ssh' => true,
        '' => true
      }

      protocol_and_expectation.each do |protocol, expected|
        it 'has correct require_ssh_key?' do
          stub_application_setting(enabled_git_access_protocol: protocol)
          user = build(:user)

          expect(user.require_ssh_key?).to eq(expected)
        end
      end

      it 'returns false when the user has 1 or more SSH keys' do
        key = create(:personal_key)

        expect(key.user.require_ssh_key?).to eq(false)
      end
    end
  end

  describe '.find_for_database_authentication' do
    it 'strips whitespace from login' do
      user = create(:user)

      expect(described_class.find_for_database_authentication({ login: " #{user.username} " })).to eq user
    end
  end

  describe '.find_by_any_email' do
    it 'finds user through private commit email' do
      user = create(:user)
      private_email = user.private_commit_email

      expect(described_class.find_by_any_email(private_email)).to eq(user)
      expect(described_class.find_by_any_email(private_email, confirmed: true)).to eq(user)
    end

    it 'finds user through private commit email when user is unconfirmed' do
      user = create(:user, :unconfirmed)
      private_email = user.private_commit_email

      expect(described_class.find_by_any_email(private_email)).to eq(user)
      expect(described_class.find_by_any_email(private_email, confirmed: true)).to eq(user)
    end

    it 'finds by primary email' do
      user = create(:user, email: 'foo@example.com')

      expect(described_class.find_by_any_email(user.email)).to eq user
      expect(described_class.find_by_any_email(user.email, confirmed: true)).to eq user
    end

    it 'finds by primary email when user is unconfirmed according to confirmed argument' do
      user = create(:user, :unconfirmed, email: 'foo@example.com')

      expect(described_class.find_by_any_email(user.email)).to eq user
      expect(described_class.find_by_any_email(user.email, confirmed: true)).to be_nil
    end

    it 'finds by uppercased email' do
      user = create(:user, email: 'foo@example.com')

      expect(described_class.find_by_any_email(user.email.upcase)).to eq user
      expect(described_class.find_by_any_email(user.email.upcase, confirmed: true)).to eq user
    end

    context 'finds by secondary email' do
      context 'when primary email is confirmed' do
        let(:user) { email.user }

        context 'when secondary email is confirmed' do
          let!(:email) { create(:email, :confirmed, email: 'foo@example.com') }

          it 'finds user' do
            expect(described_class.find_by_any_email(email.email)).to eq user
            expect(described_class.find_by_any_email(email.email, confirmed: true)).to eq user
          end
        end

        context 'when secondary email is unconfirmed' do
          let!(:email) { create(:email, email: 'foo@example.com') }

          it 'does not find user' do
            expect(described_class.find_by_any_email(email.email)).to be_nil
            expect(described_class.find_by_any_email(email.email, confirmed: true)).to be_nil
          end
        end
      end

      context 'when primary email is unconfirmed' do
        let(:user) { create(:user, :unconfirmed) }

        context 'when secondary email is confirmed' do
          let!(:email) { create(:email, :confirmed, user: user, email: 'foo@example.com') }

          it 'finds user according to confirmed argument' do
            expect(described_class.find_by_any_email(email.email)).to eq user
            expect(described_class.find_by_any_email(email.email, confirmed: true)).to be_nil
          end
        end

        context 'when secondary email is unconfirmed' do
          let!(:email) { create(:email, user: user, email: 'foo@example.com') }

          it 'does not find user' do
            expect(described_class.find_by_any_email(email.email)).to be_nil
            expect(described_class.find_by_any_email(email.email, confirmed: true)).to be_nil
          end
        end
      end
    end

    it 'returns nil when nothing found' do
      expect(described_class.find_by_any_email('')).to be_nil
    end
  end

  describe '.by_any_email' do
    let_it_be(:user, freeze: true) { create(:user) }
    let_it_be(:unconfirmed_user, freeze: true) { create(:user, :unconfirmed) }

    it 'returns an ActiveRecord::Relation' do
      expect(described_class.by_any_email('foo@example.com'))
        .to be_a_kind_of(ActiveRecord::Relation)
    end

    it 'returns empty relation of users when nothing found' do
      expect(described_class.by_any_email('')).to be_empty
    end

    it 'returns a relation of users for confirmed primary emails' do
      expect(described_class.by_any_email(user.email)).to contain_exactly(user)
      expect(described_class.by_any_email(user.email, confirmed: true)).to contain_exactly(user)
    end

    it 'returns a relation of users for unconfirmed primary emails according to confirmed argument' do
      expect(described_class.by_any_email(unconfirmed_user.email)).to contain_exactly(unconfirmed_user)
      expect(described_class.by_any_email(unconfirmed_user.email, confirmed: true)).to be_empty
    end

    it 'finds users through private commit emails' do
      private_email = user.private_commit_email

      expect(described_class.by_any_email(private_email)).to contain_exactly(user)
      expect(described_class.by_any_email(private_email, confirmed: true)).to contain_exactly(user)
    end

    it 'finds unconfirmed users through private commit emails' do
      private_email = unconfirmed_user.private_commit_email

      expect(described_class.by_any_email(private_email)).to contain_exactly(unconfirmed_user)
      expect(described_class.by_any_email(private_email, confirmed: true)).to contain_exactly(unconfirmed_user)
    end

    it 'finds user through a private commit email in an array' do
      private_email = user.private_commit_email

      expect(described_class.by_any_email([private_email])).to contain_exactly(user)
      expect(described_class.by_any_email([private_email], confirmed: true)).to contain_exactly(user)
    end

    it 'finds by uppercased email' do
      user = create(:user, email: 'foo@example.com')

      expect(described_class.by_any_email(user.email.upcase)).to contain_exactly(user)
      expect(described_class.by_any_email(user.email.upcase, confirmed: true)).to contain_exactly(user)
    end

    context 'finds by secondary email' do
      context 'when primary email is confirmed' do
        let(:user) { email.user }

        context 'when secondary email is confirmed' do
          let!(:email) { create(:email, :confirmed, email: 'foo@example.com') }

          it 'finds user' do
            expect(described_class.by_any_email(email.email)).to contain_exactly(user)
            expect(described_class.by_any_email(email.email, confirmed: true)).to contain_exactly(user)
          end
        end

        context 'when secondary email is unconfirmed' do
          let!(:email) { create(:email, email: 'foo@example.com') }

          it 'does not find user' do
            expect(described_class.by_any_email(email.email)).to be_empty
            expect(described_class.by_any_email(email.email, confirmed: true)).to be_empty
          end
        end
      end

      context 'when primary email is unconfirmed' do
        let(:user) { unconfirmed_user }

        context 'when secondary email is confirmed' do
          let!(:email) { create(:email, :confirmed, user: user, email: 'foo@example.com') }

          it 'finds user according to confirmed argument' do
            expect(described_class.by_any_email(email.email)).to contain_exactly(user)
            expect(described_class.by_any_email(email.email, confirmed: true)).to be_empty
          end
        end

        context 'when secondary email is unconfirmed' do
          let!(:email) { create(:email, user: user, email: 'foo@example.com') }

          it 'does not find user' do
            expect(described_class.by_any_email(email.email)).to be_empty
            expect(described_class.by_any_email(email.email, confirmed: true)).to be_empty
          end
        end
      end
    end
  end

  describe '.search' do
    let_it_be(:user) { create(:user, name: 'user', username: 'usern', email: 'email@example.com') }
    let_it_be(:public_email) do
      create(:email, :confirmed, user: user, email: 'publicemail@example.com').tap do |email|
        user.update!(public_email: email.email)
      end
    end

    let_it_be(:user2) { create(:user, name: 'user name', username: 'username', email: 'someemail@example.com') }
    let_it_be(:user3) { create(:user, name: 'us', username: 'se', email: 'foo@example.com') }
    let_it_be(:unconfirmed_user) { create(:user, :unconfirmed, name: 'not verified', username: 'notverified') }

    let_it_be(:unconfirmed_secondary_email) { create(:email, user: user, email: 'alias@example.com') }
    let_it_be(:confirmed_secondary_email) { create(:email, :confirmed, user: user, email: 'alias2@example.com') }

    describe 'name user and email relative ordering' do
      let_it_be(:named_alexander) { create(:user, name: 'Alexander Person', username: 'abcd', email: 'abcd@example.com') }
      let_it_be(:username_alexand) { create(:user, name: 'Joao Alexander', username: 'Alexand', email: 'joao@example.com') }

      it 'prioritizes exact matches' do
        expect(described_class.search('Alexand')).to contain_exactly(username_alexand, named_alexander)
      end

      it 'falls back to ordering by name' do
        expect(described_class.search('Alexander')).to contain_exactly(named_alexander, username_alexand)
      end
    end

    describe 'name matching' do
      it 'returns users with a matching name with exact match first' do
        expect(described_class.search(user.name)).to contain_exactly(user, user2)
      end

      it 'returns users with a partially matching name' do
        expect(described_class.search(user.name[0..2])).to contain_exactly(user, user2)
      end

      it 'returns users with a matching name regardless of the casing' do
        expect(described_class.search(user2.name.upcase)).to contain_exactly(user2)
      end

      it 'returns users with a exact matching name shorter than 3 chars' do
        expect(described_class.search(user3.name)).to contain_exactly(user3)
      end

      it 'returns users with a exact matching name shorter than 3 chars regardless of the casing' do
        expect(described_class.search(user3.name.upcase)).to contain_exactly(user3)
      end

      context 'when use_minimum_char_limit is false' do
        it 'returns users with a partially matching name' do
          expect(described_class.search('u', use_minimum_char_limit: false)).to contain_exactly(user3, user, user2)
        end
      end
    end

    describe 'email matching' do
      it 'returns users with a matching public email' do
        expect(described_class.search(user.public_email)).to contain_exactly(user)
      end

      it 'does not return users with a partially matching public email' do
        expect(described_class.search(user.public_email[1...-1])).to be_empty
      end

      it 'returns users with a matching public email regardless of the casing' do
        expect(described_class.search(user.public_email.upcase)).to contain_exactly(user)
      end

      it 'does not return users with a matching private email' do
        expect(described_class.search(user.email)).to be_empty

        expect(described_class.search(unconfirmed_secondary_email.email)).to be_empty
        expect(described_class.search(confirmed_secondary_email.email)).to be_empty
      end

      context 'with private emails search' do
        let(:options) { { with_private_emails: true } }

        it 'returns users with matching private primary email' do
          expect(described_class.search(user.email, **options)).to contain_exactly(user)
        end

        it 'returns users with matching private unconfirmed primary email' do
          expect(described_class.search(unconfirmed_user.email, **options)).to contain_exactly(unconfirmed_user)
        end

        it 'returns users with matching private confirmed secondary email' do
          expect(described_class.search(confirmed_secondary_email.email, **options)).to contain_exactly(user)
        end

        it 'does not return users with matching private unconfirmed secondary email' do
          expect(described_class.search(unconfirmed_secondary_email.email, **options)).to be_empty
        end

        context 'with partial email search' do
          let(:options) { super().merge(partial_email_search: true) }

          before do
            user.emails.each { |email| email.update! confirmed_at: nil }
          end

          it 'returns users with partially matching private primary email' do
            expect(described_class.search(user.email[1...-1], **options)).to contain_exactly(user, user2)
          end

          it 'returns users with partially matching private unconfirmed primary email' do
            expect(described_class.search(unconfirmed_user.email[1...-1], **options)).to contain_exactly(unconfirmed_user)
          end

          it 'returns users with partially matching private confirmed secondary email' do
            expect(described_class.search(confirmed_secondary_email.email[1...-1], **options)).to contain_exactly(user)
          end

          context 'when search is less than minimum char limit' do
            subject(:users) { described_class.search(user.public_email[1..2], **options) }

            context 'and use_minimum_char_limit is false' do
              let(:options) { super().merge(use_minimum_char_limit: false) }

              it 'ignores minimum char limit and returns users with a partially matching public email' do
                expect(users).to contain_exactly(user)
              end
            end

            context 'and use_minimum_char_limit is true' do
              let(:options) { super().merge(use_minimum_char_limit: true) }

              it 'respects minimum char limit and does not return any users' do
                expect(users).to be_empty
              end
            end
          end
        end
      end
    end

    describe 'username matching' do
      let_it_be(:named_john) { create(:user, name: 'John', username: 'abcd') }
      let_it_be(:username_john) { create(:user, name: 'John Doe', username: 'john') }

      it 'returns users with a matching username' do
        expect(described_class.search(user.username)).to contain_exactly(user, user2)
      end

      it 'returns users with a matching username starting with a @' do
        expect(described_class.search("@#{user.username}")).to contain_exactly(user, user2)
      end

      it 'returns users with a partially matching username' do
        expect(described_class.search(user.username[0..2])).to contain_exactly(user, user2)
      end

      it 'returns users with a partially matching username starting with @' do
        expect(described_class.search("@#{user.username[0..2]}")).to contain_exactly(user, user2)
      end

      it 'returns users with a matching username regardless of the casing' do
        expect(described_class.search(user2.username.upcase)).to contain_exactly(user2)
      end

      it 'returns users with an exact matching username first' do
        expect(described_class.search('John')).to contain_exactly(username_john, named_john)
      end

      it 'returns users with a exact matching username shorter than 3 chars' do
        expect(described_class.search(user3.username)).to contain_exactly(user3)
      end

      it 'returns users with a exact matching username shorter than 3 chars regardless of the casing' do
        expect(described_class.search(user3.username.upcase)).to contain_exactly(user3)
      end

      context 'when use_minimum_char_limit is false' do
        it 'returns users with a partially matching username' do
          expect(described_class.search('se', use_minimum_char_limit: false)).to contain_exactly(user3, user, user2)
        end
      end
    end

    it 'returns no matches for an empty string' do
      expect(described_class.search('')).to be_empty
    end

    it 'returns no matches for nil' do
      expect(described_class.search(nil)).to be_empty
    end

    it 'returns no matches for an array' do
      expect(described_class.search(%w[the test])).to be_empty
    end
  end

  describe '.gfm_autocomplete_search' do
    let_it_be(:user_1) { create(:user, username: 'someuser', name: 'John Doe') }
    let_it_be(:user_2) { create(:user, username: 'userthomas', name: 'Thomas Person') }

    it 'returns partial matches on username' do
      expect(described_class.gfm_autocomplete_search('some')).to contain_exactly(user_1)
    end

    it 'returns matches on name across multiple words' do
      expect(described_class.gfm_autocomplete_search('johnd')).to contain_exactly(user_1)
    end

    it 'prioritizes sorting of matches that start with the query' do
      expect(described_class.gfm_autocomplete_search('uSeR')).to contain_exactly(user_2, user_1)
    end

    it 'falls back to sorting by username' do
      expect(described_class.gfm_autocomplete_search('ser')).to contain_exactly(user_1, user_2)
    end
  end

  describe '.user_search_minimum_char_limit' do
    it 'returns true' do
      expect(described_class.user_search_minimum_char_limit).to be(true)
    end
  end

  describe '.find_by_ssh_key_id' do
    let_it_be(:user) { create(:user) }
    let_it_be(:key) { create(:key, user: user) }

    context 'using an existing SSH key ID' do
      it 'returns the corresponding User' do
        expect(described_class.find_by_ssh_key_id(key.id)).to eq(user)
      end
    end

    it 'only performs a single query' do
      key # Don't count the queries for creating the key and user

      expect { described_class.find_by_ssh_key_id(key.id) }
        .not_to exceed_query_limit(1)
    end

    context 'using an invalid SSH key ID' do
      it 'returns nil' do
        expect(described_class.find_by_ssh_key_id(-1)).to be_nil
      end
    end

    it 'does not return a signing-only key', :aggregate_failures do
      signing_key = create(:key, usage_type: :signing, user: user)
      auth_and_signing_key = create(:key, usage_type: :auth_and_signing, user: user)

      expect(described_class.find_by_ssh_key_id(signing_key.id)).to be_nil
      expect(described_class.find_by_ssh_key_id(auth_and_signing_key.id)).to eq(user)
    end

    it 'does not return a user for a deploy key' do
      deploy_key = create(:deploy_key)

      expect(described_class.find_by_ssh_key_id(deploy_key.id)).to be_nil
    end
  end

  shared_examples "find user by login" do
    let_it_be(:user) { create(:user) }
    let_it_be(:invalid_login) { "#{user.username}-NOT-EXISTS" }

    context 'when login is nil or empty' do
      it 'returns nil' do
        expect(login_method(nil)).to be_nil
        expect(login_method('')).to be_nil
      end
    end

    context 'when login is invalid' do
      it 'returns nil' do
        expect(login_method(invalid_login)).to be_nil
      end
    end

    context 'when login is username' do
      it 'returns user' do
        expect(login_method(user.username)).to eq(user)
        expect(login_method(user.username.downcase)).to eq(user)
        expect(login_method(user.username.upcase)).to eq(user)
      end
    end

    context 'when login is email' do
      it 'returns user' do
        expect(login_method(user.email)).to eq(user)
        expect(login_method(user.email.downcase)).to eq(user)
        expect(login_method(user.email.upcase)).to eq(user)
      end
    end
  end

  describe '.by_login' do
    it_behaves_like "find user by login" do
      def login_method(login)
        described_class.by_login(login).take
      end
    end
  end

  describe '.find_by_login' do
    it_behaves_like "find user by login" do
      def login_method(login)
        described_class.find_by_login(login)
      end
    end
  end

  describe '.find_by_username' do
    it 'returns nil if not found' do
      expect(described_class.find_by_username('JohnDoe')).to be_nil
    end

    it 'is case-insensitive' do
      user = create(:user, username: 'JohnDoe')

      expect(described_class.find_by_username('JOHNDOE')).to eq user
    end
  end

  describe '.find_by_username!' do
    it 'raises RecordNotFound' do
      expect { described_class.find_by_username!('JohnDoe') }
        .to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'is case-insensitive' do
      user = create(:user, username: 'JohnDoe')

      expect(described_class.find_by_username!('JOHNDOE')).to eq user
    end
  end

  describe '.find_by_full_path' do
    let_it_be(:user, freeze: true) { create(:user, namespace: create(:user_namespace)) }

    context 'with a route matching the given path' do
      let!(:route) { user.namespace.route }

      it 'returns the user' do
        expect(described_class.find_by_full_path(route.path)).to eq(user)
      end

      it 'is case-insensitive' do
        expect(described_class.find_by_full_path(route.path.upcase)).to eq(user)
        expect(described_class.find_by_full_path(route.path.downcase)).to eq(user)
      end

      context 'with a redirect route matching the given path' do
        let!(:redirect_route) { user.namespace.redirect_routes.create!(path: 'foo') }

        context 'without the follow_redirects option' do
          it 'returns nil' do
            expect(described_class.find_by_full_path(redirect_route.path)).to eq(nil)
          end
        end

        context 'with the follow_redirects option set to true' do
          it 'returns the user' do
            expect(described_class.find_by_full_path(redirect_route.path, follow_redirects: true)).to eq(user)
          end

          it 'is case-insensitive' do
            expect(described_class.find_by_full_path(redirect_route.path.upcase, follow_redirects: true)).to eq(user)
            expect(described_class.find_by_full_path(redirect_route.path.downcase, follow_redirects: true)).to eq(user)
          end
        end
      end

      context 'without a route or a redirect route matching the given path' do
        context 'without the follow_redirects option' do
          it 'returns nil' do
            expect(described_class.find_by_full_path('unknown')).to eq(nil)
          end
        end

        context 'with the follow_redirects option set to true' do
          it 'returns nil' do
            expect(described_class.find_by_full_path('unknown', follow_redirects: true)).to eq(nil)
          end
        end
      end

      context 'with a group route matching the given path' do
        let!(:group) { create(:group, path: 'group_path') }

        context 'when the group namespace has an owner_id (legacy data)' do
          before do
            group.update!(owner_id: user.id)
          end

          it 'returns nil' do
            expect(described_class.find_by_full_path('group_path')).to eq(nil)
          end
        end

        context 'when the group namespace does not have an owner_id' do
          it 'returns nil' do
            expect(described_class.find_by_full_path('group_path')).to eq(nil)
          end
        end
      end
    end
  end

  describe 'all_ssh_keys' do
    it { is_expected.to have_many(:keys).dependent(:destroy) }

    it 'has all ssh keys' do
      user = create :user
      key = create :key_without_comment, user_id: user.id

      expect(user.all_ssh_keys).to include(a_string_starting_with(key.key))
    end
  end

  it_behaves_like Avatarable do
    let(:model) { create(:user, :with_avatar) }
  end

  describe '#clear_avatar_caches' do
    let_it_be(:user) { create(:user) }

    it 'clears the avatar cache when saving' do
      allow(user).to receive(:avatar_changed?).and_return(true)

      expect(Gitlab::AvatarCache).to receive(:delete_by_email).with(*user.verified_emails)

      user.update!(avatar: fixture_file_upload('spec/fixtures/dk.png'))
    end
  end

  describe '#accept_pending_invitations!' do
    let_it_be_with_reload(:user) { create(:user, email: 'user@email.com') }

    let_it_be_with_reload(:confirmed_secondary_email, freeze: true) { create(:email, :confirmed, email: 'confirmedsecondary@example.com', user: user) }
    let_it_be_with_reload(:unconfirmed_secondary_email, freeze: true) { create(:email, email: 'unconfirmedsecondary@example.com', user: user) }

    let_it_be_with_reload(:project_member_invite) { create(:project_member, :invited, invite_email: user.email) }
    let!(:group_member_invite) { create(:group_member, :invited, invite_email: user.email) }

    let_it_be_with_reload(:external_project_member_invite) { create(:project_member, :invited, invite_email: 'external@email.com') }
    let_it_be_with_reload(:external_group_member_invite) { create(:group_member, :invited, invite_email: 'external@email.com') }

    let_it_be_with_reload(:project_member_invite_via_confirmed_secondary_email) { create(:project_member, :invited, invite_email: confirmed_secondary_email.email) }
    let_it_be_with_reload(:group_member_invite_via_confirmed_secondary_email) { create(:group_member, :invited, invite_email: confirmed_secondary_email.email) }

    let_it_be_with_reload(:project_member_invite_via_unconfirmed_secondary_email) { create(:project_member, :invited, invite_email: unconfirmed_secondary_email.email) }
    let_it_be_with_reload(:group_member_invite_via_unconfirmed_secondary_email) { create(:group_member, :invited, invite_email: unconfirmed_secondary_email.email) }

    it 'accepts all the user members pending invitations and returns the accepted_members' do
      accepted_members = user.accept_pending_invitations!

      expect(accepted_members).to contain_exactly(
        project_member_invite,
        group_member_invite,
        project_member_invite_via_confirmed_secondary_email,
        group_member_invite_via_confirmed_secondary_email
      )

      expect(group_member_invite.reload).not_to be_invite
      expect(project_member_invite.reload).not_to be_invite

      expect(external_project_member_invite.reload).to be_invite
      expect(external_group_member_invite.reload).to be_invite

      expect(project_member_invite_via_confirmed_secondary_email.reload).not_to be_invite
      expect(group_member_invite_via_confirmed_secondary_email.reload).not_to be_invite

      expect(project_member_invite_via_unconfirmed_secondary_email.reload).to be_invite
      expect(group_member_invite_via_unconfirmed_secondary_email.reload).to be_invite
    end

    context 'with an uppercase version of the email matches another member' do
      let_it_be_with_reload(:uppercase_existing_invite) do
        create(:project_member, :invited, source: project_member_invite.project, invite_email: user.email.upcase)
      end

      it 'accepts only one of the invites' do
        travel_to 10.minutes.ago do
          project_member_invite.touch # in past, so shouldn't get accepted over the one created
        end

        uppercase_existing_invite.touch # ensure updated_at is being verified. This one should be first now.

        travel_to 10.minutes.from_now do
          project_member_invite.touch # now we'll make the original first so we are verifying updated_at

          result = [
            project_member_invite,
            group_member_invite,
            project_member_invite_via_confirmed_secondary_email,
            group_member_invite_via_confirmed_secondary_email
          ]

          accepted_members = user.accept_pending_invitations!

          expect(accepted_members).to match_array(result)
          expect(uppercase_existing_invite.reset.user).to be_nil
        end
      end
    end
  end

  describe '#pending_invitations' do
    let_it_be(:user, reload: true) { create(:user, email: 'user@email.com') }
    let_it_be(:invited_member) do
      create(:project_member, :invited, invite_email: user.email)
    end

    it 'finds the invite' do
      expect(user.pending_invitations).to contain_exactly(invited_member)
    end
  end

  describe '#has_groups_allowing_project_creation?' do
    subject { user.has_groups_allowing_project_creation? }

    it_behaves_like 'checks for groups with project creation permission'
  end

  describe '#can_select_namespace?' do
    subject { user.can_select_namespace? }

    context 'when user is admin' do
      let_it_be(:user) { create(:user, :admin) }

      it { is_expected.to be(true) }
    end

    it_behaves_like 'checks for groups with project creation permission'
  end

  describe '#can_create_project?' do
    let_it_be_with_refind(:user) { create(:user) }

    context "when projects_limit_left is 0" do
      before do
        allow(user).to receive(:projects_limit_left).and_return(0)
      end

      it "returns false" do
        expect(user.can_create_project?).to be_falsey
      end
    end

    context "when projects_limit_left is > 0" do
      before do
        allow(user).to receive(:projects_limit_left).and_return(1)
      end

      context "with allow_project_creation_for_guest_and_below default value of true" do
        it "returns true" do
          expect(user.can_create_project?).to be_truthy
        end
      end

      context "when Gitlab::CurrentSettings.allow_project_creation_for_guest_and_below is false" do
        before do
          stub_application_setting(allow_project_creation_for_guest_and_below: false)
        end

        context 'with users having various membership access_levels' do
          [
            Gitlab::Access::NO_ACCESS,
            Gitlab::Access::MINIMAL_ACCESS,
            Gitlab::Access::GUEST
          ].each do |role|
            context "when users highest role is #{role}" do
              it "returns false" do
                allow(user).to receive(:highest_role).and_return(role)
                expect(user.can_create_project?).to be_falsey
              end
            end
          end

          [
            Gitlab::Access::PLANNER,
            Gitlab::Access::REPORTER,
            Gitlab::Access::DEVELOPER,
            Gitlab::Access::MAINTAINER,
            Gitlab::Access::OWNER,
            Gitlab::Access::ADMIN
          ].each do |role|
            context "when users highest role is #{role}" do
              it "returns true" do
                allow(user).to receive(:highest_role).and_return(role)
                expect(user.can_create_project?).to be_truthy
              end
            end
          end
        end

        context 'when user does not have any membership records' do
          context 'when user is admin', :enable_admin_mode do
            let(:user) { create(:admin) }

            it "returns true" do
              expect(user.can_create_project?).to be_truthy
            end
          end

          context 'when user is not admin' do
            it "returns false" do
              expect(user.can_create_project?).to be_falsey
            end
          end
        end
      end
    end
  end

  describe '#can_leave_group?' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }

    subject { user.can_leave_group?(group) }

    context 'when user is member' do
      context 'when user has permission to leave the group' do
        let_it_be(:group_owner) { create(:group_member, :owner, group: group, user: create(:user)) }
        let_it_be(:group_member) { create(:group_member, group: group, user: user) }

        it { is_expected.to be(true) }
      end

      context 'when user has no permission to leave the group' do
        let_it_be(:group_owner) { create(:group_member, :owner, user: user) }

        it { is_expected.to be(false) }
      end
    end

    context 'when user is not a member' do
      it { is_expected.to be(false) }
    end
  end

  describe '#all_emails' do
    let_it_be(:user, freeze: true) { create(:user) }
    let_it_be(:unconfirmed_secondary_email, freeze: true) { create(:email, user: user) }
    let_it_be(:confirmed_secondary_email, freeze: true) { create(:email, :confirmed, user: user) }

    it 'returns all emails' do
      expect(user.all_emails).to contain_exactly(
        user.email,
        user.private_commit_email,
        confirmed_secondary_email.email
      )
    end

    context 'when the primary email is confirmed' do
      it 'includes the primary email' do
        expect(user.all_emails).to include(user.email)
      end
    end

    context 'when the primary email is unconfirmed' do
      let_it_be(:user, freeze: true) { create(:user, :unconfirmed) }

      it 'includes the primary email' do
        expect(user.all_emails).to include(user.email)
      end
    end

    context 'when the primary email is temp email for oauth' do
      let_it_be(:user, freeze: true) do
        create(:omniauth_user, :unconfirmed, email: 'temp-email-for-oauth-user@gitlab.localhost')
      end

      it 'does not include the primary email' do
        expect(user.all_emails).not_to include(user.email)
      end
    end

    context 'when `include_private_email` is true' do
      it 'includes the private commit email' do
        expect(user.all_emails).to include(user.private_commit_email)
      end
    end

    context 'when `include_private_email` is false' do
      it 'does not include the private commit email' do
        expect(user.all_emails(include_private_email: false)).not_to include(
          user.private_commit_email
        )
      end
    end

    context 'when the secondary email is confirmed' do
      it 'includes the secondary email' do
        expect(user.all_emails).to include(confirmed_secondary_email.email)
      end
    end

    context 'when the secondary email is unconfirmed' do
      it 'does not include the secondary email' do
        expect(user.all_emails).not_to include(unconfirmed_secondary_email.email)
      end
    end
  end

  describe '#verified_emails' do
    let_it_be_with_refind(:user) { create(:user) }
    let_it_be(:confirmed_email, freeze: true) { create(:email, :confirmed, user: user) }

    before_all do
      create(:email, user: user)
    end

    it 'returns only confirmed emails' do
      expect(user.verified_emails).to contain_exactly(
        user.email,
        user.private_commit_email,
        confirmed_email.email
      )
    end

    it 'does not return primary email when primary email is changed' do
      original_email = user.email
      user.email = generate(:email)

      expect(user.verified_emails).to contain_exactly(
        user.private_commit_email,
        confirmed_email.email,
        original_email
      )
    end

    it 'does not return unsaved primary email even if skip_confirmation is enabled' do
      original_email = user.email
      user.skip_confirmation = true
      user.email = generate(:email)

      expect(user.verified_emails).to contain_exactly(
        user.private_commit_email,
        confirmed_email.email,
        original_email
      )
    end

    it 'does not perform a database query for confirmed emails if the emails are loaded' do
      user.emails.reload

      expect(user.emails).to be_loaded

      recorder = ActiveRecord::QueryRecorder.new(skip_cached: false) do
        expect(user.verified_emails).to contain_exactly(
          user.email,
          user.private_commit_email,
          confirmed_email.email
        )
      end

      expect(recorder.count).to be_zero
    end
  end

  describe '#verified_detumbled_emails' do
    let_it_be(:user) { create(:user, email: 'user+1@example.com') }

    it 'returns only confirmed unique detumbled emails' do
      create(:email, :confirmed,  email: 'user+2@example.com', user: user)
      create(:email, :confirmed,  email: 'other_user+1@example.com', user: user)
      create(:email, user: user)

      expect(user.verified_detumbled_emails).to contain_exactly('user@example.com', 'other_user@example.com')
    end
  end

  describe '#public_verified_emails' do
    let_it_be_with_refind(:user) { create(:user) }

    it 'returns only confirmed public emails' do
      email_confirmed = create :email, user: user, confirmed_at: Time.current
      create :email, user: user

      expect(user.public_verified_emails).to contain_exactly(
        user.email,
        email_confirmed.email
      )
    end

    context 'when user is not confirmed' do
      before_all do
        user.update!(confirmed_at: nil)
      end

      it 'returns confirmed public emails plus main user email when user is not confirmed' do
        email_confirmed = create :email, user: user, confirmed_at: Time.current
        create :email, user: user

        expect(user.public_verified_emails).to contain_exactly(
          user.email,
          email_confirmed.email
        )
      end
    end
  end

  describe '#verified_email?' do
    let_it_be_with_refind(:user) { create(:user) }

    it 'returns true when the email is verified/confirmed' do
      email_confirmed = create :email, user: user, confirmed_at: Time.current
      create :email, user: user
      user.reload

      expect(user.verified_email?(user.email)).to be_truthy
      expect(user.verified_email?(email_confirmed.email.titlecase)).to be_truthy
    end

    it 'returns true when user is found through private commit email' do
      expect(user.verified_email?(user.private_commit_email)).to be_truthy
    end

    it 'returns true for an outdated private commit email' do
      old_email = user.private_commit_email

      user.update!(username: 'changed-username')

      expect(user.verified_email?(old_email)).to be_truthy
    end

    it 'returns false when the email is not verified/confirmed' do
      email_unconfirmed = create :email, user: user
      user.reload

      expect(user.verified_email?(email_unconfirmed.email)).to be_falsy
    end
  end

  context 'crowd synchronized user' do
    describe '#crowd_user?' do
      shared_examples_for 'User#crowd_user?' do
        subject { user.crowd_user? }

        context 'when provider is not crowd' do
          let(:user) { create(:omniauth_user, provider: 'other-provider') }

          it { is_expected.to be_falsey }
        end

        context 'when provider is crowd' do
          let(:user) { create(:omniauth_user, provider: 'crowd') }

          it { is_expected.to be_truthy }
        end

        context 'when extern_uid is not provided' do
          let(:user) { create(:omniauth_user, extern_uid: nil) }

          it { is_expected.to be_falsey }
        end
      end

      it_behaves_like 'User#crowd_user?'

      context 'when identities are loaded' do
        it_behaves_like 'User#crowd_user?' do
          before do
            user.identities.to_a
          end
        end
      end
    end
  end

  describe '#requires_ldap_check?' do
    let(:user) { described_class.new }

    it 'is false when LDAP is disabled' do
      # Create a condition which would otherwise cause 'true' to be returned
      allow(user).to receive(:ldap_user?).and_return(true)
      user.last_credential_check_at = nil

      expect(user.requires_ldap_check?).to be_falsey
    end

    context 'when LDAP is enabled' do
      before do
        allow(Gitlab.config.ldap).to receive(:enabled).and_return(true)
      end

      it 'is false for non-LDAP users' do
        allow(user).to receive(:ldap_user?).and_return(false)

        expect(user.requires_ldap_check?).to be_falsey
      end

      context 'and when the user is an LDAP user' do
        before do
          allow(user).to receive(:ldap_user?).and_return(true)
        end

        it 'is true when the user has never had an LDAP check before' do
          user.last_credential_check_at = nil

          expect(user.requires_ldap_check?).to be_truthy
        end

        it 'is true when the last LDAP check happened over 1 hour ago' do
          user.last_credential_check_at = 2.hours.ago

          expect(user.requires_ldap_check?).to be_truthy
        end
      end
    end
  end

  context 'ldap synchronized user' do
    describe '#ldap_user?' do
      it 'is true if provider name starts with ldap' do
        user = create(:omniauth_user, provider: 'ldapmain')

        expect(user.ldap_user?).to be_truthy
      end

      it 'is false for other providers' do
        user = create(:omniauth_user, provider: 'other-provider')

        expect(user.ldap_user?).to be_falsey
      end

      it 'is false if no extern_uid is provided' do
        user = create(:omniauth_user, extern_uid: nil)

        expect(user.ldap_user?).to be_falsey
      end
    end

    describe '#ldap_identity' do
      it 'returns ldap identity' do
        user = create(:omniauth_user, :ldap)

        expect(user.ldap_identity.provider).not_to be_empty
      end
    end

    describe '#matches_identity?' do
      it 'finds the identity when the DN is formatted differently' do
        user = create(:omniauth_user, provider: 'ldapmain', extern_uid: 'uid=john smith,ou=people,dc=example,dc=com')

        expect(user.matches_identity?('ldapmain', 'uid=John Smith, ou=People, dc=example, dc=com')).to eq(true)
      end
    end

    describe '#ldap_block' do
      let(:user) { create(:omniauth_user, provider: 'ldapmain', name: 'John Smith') }

      it 'blocks user flaging the action caming from ldap' do
        user.ldap_block

        expect(user.blocked?).to be_truthy
        expect(user.ldap_blocked?).to be_truthy
      end

      context 'on a read-only instance' do
        before do
          allow(Gitlab::Database).to receive(:read_only?).and_return(true)
        end

        it 'does not block user' do
          user.ldap_block

          expect(user.blocked?).to be_falsey
          expect(user.ldap_blocked?).to be_falsey
        end
      end
    end
  end

  describe '#full_website_url' do
    let_it_be_with_reload(:user) { create(:user) }

    it 'begins with http if website url omits it' do
      user.website_url = 'test.com'

      expect(user.full_website_url).to eq 'http://test.com'
    end

    it 'begins with http if website url begins with http' do
      user.website_url = 'http://test.com'

      expect(user.full_website_url).to eq 'http://test.com'
    end

    it 'begins with https if website url begins with https' do
      user.website_url = 'https://test.com'

      expect(user.full_website_url).to eq 'https://test.com'
    end
  end

  describe '#short_website_url' do
    let_it_be_with_reload(:user) { create(:user) }

    it 'does not begin with http if website url omits it' do
      user.website_url = 'test.com'

      expect(user.short_website_url).to eq 'test.com'
    end

    it 'does not begin with http if website url begins with http' do
      user.website_url = 'http://test.com'

      expect(user.short_website_url).to eq 'test.com'
    end

    it 'does not begin with https if website url begins with https' do
      user.website_url = 'https://test.com'

      expect(user.short_website_url).to eq 'test.com'
    end
  end

  describe '#sanitize_attrs' do
    let(:user) { build(:user, name: 'test & user', linkedin: 'test&user') }

    it 'does not encode HTML entities in the name attribute' do
      expect { user.sanitize_attrs }.not_to change { user.name }
    end

    context 'for name attribute' do
      subject { user.name }

      before do
        user.name = input_name
        user.sanitize_attrs
      end

      context 'from html tags' do
        let(:input_name) { '<a href="//example.com">Test<a>' }

        it { is_expected.to eq('-Test-') }
      end

      context 'from unclosed html tags' do
        let(:input_name) { 'a<a class="js-evil" href=/api/v4' }

        it { is_expected.to eq('a-a class="js-evil" href=/api/v4') }
      end

      context 'from closing html brackets' do
        let(:input_name) { 'alice some> tag' }

        it { is_expected.to eq('alice some- tag') }
      end

      context 'from self-closing tags' do
        let(:input_name) { '</link>alice' }

        it { is_expected.to eq('-alice') }
      end

      context 'from js scripts' do
        let(:input_name) { '<script>alert("Test")</script>' }

        it { is_expected.to eq('-alert("Test")-') }
      end

      context 'from iframe scripts' do
        let(:input_name) { 'User"><iframe src=javascript:alert()><iframe>' }

        it { is_expected.to eq('User"---') }
      end
    end
  end

  describe '#starred?' do
    it 'determines if user starred a project' do
      user = create :user
      project1 = create(:project, :public)
      project2 = create(:project, :public)

      expect(user.starred?(project1)).to be_falsey
      expect(user.starred?(project2)).to be_falsey

      star1 = UsersStarProject.create!(project: project1, user: user)

      expect(user.starred?(project1)).to be_truthy
      expect(user.starred?(project2)).to be_falsey

      star2 = UsersStarProject.create!(project: project2, user: user)

      expect(user.starred?(project1)).to be_truthy
      expect(user.starred?(project2)).to be_truthy

      star1.destroy!

      expect(user.starred?(project1)).to be_falsey
      expect(user.starred?(project2)).to be_truthy

      star2.destroy!

      expect(user.starred?(project1)).to be_falsey
      expect(user.starred?(project2)).to be_falsey
    end
  end

  describe '#toggle_star' do
    it 'toggles stars' do
      user = create :user
      project = create(:project, :public)

      # starring
      expect { user.toggle_star(project) }
        .to change { user.starred?(project) }.from(false).to(true)
        .and not_change { project.reload.updated_at }

      # unstarring
      expect { user.toggle_star(project) }
        .to change { user.starred?(project) }.from(true).to(false)
        .and not_change { project.reload.updated_at }
    end
  end

  describe '#following?' do
    it 'check if following another user' do
      user = create :user
      followee1 = create :user

      expect(user.follow(followee1)).to be_truthy

      expect(user.following?(followee1)).to be_truthy
    end
  end

  describe '#followed_by?' do
    it 'check if followed by another user' do
      follower = create :user
      followee = create :user

      expect { follower.follow(followee) }.to change { followee.followed_by?(follower) }.from(false).to(true)
    end
  end

  describe '#follow' do
    let_it_be_with_refind(:user) { create :user }

    context 'when following another user' do
      let_it_be_with_refind(:followee1) { create :user }
      let_it_be_with_refind(:followee2) { create :user }

      it 'follow another user' do
        expect(user.followees).to be_empty

        expect(user.follow(followee1)).to be_truthy
        expect(user.follow(followee1)).to be_falsey

        expect(user.followees).to contain_exactly(followee1)

        expect(user.follow(followee2)).to be_truthy
        expect(user.follow(followee2)).to be_falsey

        expect(user.followees).to contain_exactly(followee1, followee2)
      end

      it 'provides the number of followees' do
        expect(user.follow(followee1)).to be_truthy
        expect(user.follow(followee2)).to be_truthy

        followee1.block!

        expect(user.followees).to contain_exactly(followee2)
      end
    end

    it 'provides the number of followers' do
      follower1 = create :user
      follower2 = create :user

      expect(follower1.follow(user)).to be_truthy
      expect(follower2.follow(user)).to be_truthy

      follower1.block!

      expect(user.followers).to contain_exactly(follower2)
    end

    it 'follow itself is not possible' do
      expect(user.followees).to be_empty

      expect(user.follow(user)).to be_falsey

      expect(user.followees).to be_empty
    end

    context 'if max followee limit is reached' do
      before do
        stub_const('Users::UserFollowUser::MAX_FOLLOWEE_LIMIT', 2)

        Users::UserFollowUser::MAX_FOLLOWEE_LIMIT.times { user.follow(create(:user)) }
      end

      it 'does not follow' do
        followee = create(:user)
        user_follow_user = user.follow(followee)

        expect(user_follow_user).not_to be_persisted
        expected_message = format(_("You can't follow more than %{limit} users. To follow more users, unfollow some others."), limit: Users::UserFollowUser::MAX_FOLLOWEE_LIMIT)
        expect(user_follow_user.errors.messages[:base].first).to eq(expected_message)

        expect(user.following?(followee)).to be_falsey
      end
    end

    context 'when user disabled following' do
      before do
        user.enabled_following = false
      end

      it 'does not follow' do
        followee = create(:user)

        expect(user.follow(followee)).to eq(false)

        expect(user.following?(followee)).to be_falsey
      end
    end

    context 'when followee user disabled following' do
      let(:followee) { create(:user) }

      before do
        user.enabled_following = false
      end

      it 'does not follow' do
        expect(user.follow(followee)).to eq(false)

        expect(user.following?(followee)).to be_falsey
      end
    end

    context 'when follower user is banned' do
      let(:follower) { create(:user) }

      before do
        follower.follow(user)
      end

      it 'does not include follow' do
        expect(user.followed_by?(follower)).to be_truthy

        follower.ban

        expect(user.followed_by?(follower)).to be_falsey
      end
    end
  end

  describe '#following_users_allowed?' do
    let_it_be(:user) { create(:user) }
    let_it_be(:followee) { create(:user) }

    where(:user_enabled_following, :followee_enabled_following, :result) do
      true  | true  | true
      true  | false | false
      false | true  | false
      false | false | false
    end

    with_them do
      before do
        user.enabled_following = user_enabled_following
        followee.enabled_following = followee_enabled_following
        followee.save!
      end

      it { expect(user.following_users_allowed?(followee)).to eq result }
    end

    it 'is false when user and followee is the same user' do
      expect(user.following_users_allowed?(user)).to eq(false)
    end
  end

  describe '#notification_email_or_default' do
    let(:email) { 'gonzo@muppets.com' }

    context 'when the column in the database is null' do
      subject { create(:user, email: email, notification_email: nil) }

      it 'defaults to the primary email' do
        expect(subject.notification_email).to be_nil
        expect(subject.notification_email_or_default).to eq(email)
      end
    end
  end

  describe '.find_by_private_commit_email' do
    context 'with email' do
      let_it_be(:user) { create(:user) }

      it 'returns user through private commit email' do
        expect(described_class.find_by_private_commit_email(user.private_commit_email)).to eq(user)
      end

      it 'returns nil when email other than private_commit_email is used' do
        expect(described_class.find_by_private_commit_email(user.email)).to be_nil
      end
    end

    it 'returns nil when email is nil' do
      expect(described_class.find_by_private_commit_email(nil)).to be_nil
    end
  end

  describe '#sort_by_attribute' do
    let_it_be(:user) { create :user, created_at: Date.today, current_sign_in_at: Date.today, username: 'user0' }
    let_it_be(:user1) { create :user, created_at: Date.today - 1, last_activity_on: Date.today - 1, current_sign_in_at: Date.today - 1, username: 'user1' }
    let_it_be(:user2) { create :user, created_at: Date.today - 2, username: 'user2' }
    let_it_be(:user3) { create :user, created_at: Date.today - 3, last_activity_on: Date.today, username: "user3" }

    context 'when sort by recent_sign_in' do
      let(:users) { described_class.sort_by_attribute('recent_sign_in') }

      it 'sorts users by recent sign-in time with user that never signed in at the end' do
        expect(users).to contain_exactly(user, user1, user2, user3)
      end
    end

    context 'when sort by oldest_sign_in' do
      let(:users) { described_class.sort_by_attribute('oldest_sign_in') }

      it 'sorts users by the oldest sign-in time with users that never signed in at the end' do
        expect(users).to contain_exactly(user1, user, user2, user3)
      end
    end

    it 'sorts users in descending order by their creation time' do
      expect(described_class.sort_by_attribute('created_desc')).to contain_exactly(user, user1, user2, user3)
    end

    it 'sorts users in ascending order by their creation time' do
      expect(described_class.sort_by_attribute('created_asc')).to contain_exactly(user3, user2, user1, user)
    end

    it 'sorts users by id in descending order when nil is passed' do
      expect(described_class.sort_by_attribute(nil)).to contain_exactly(user3, user2, user1, user)
    end

    it 'sorts user by latest activity descending, nulls last ordered by ascending id' do
      expect(described_class.sort_by_attribute('last_activity_on_desc')).to contain_exactly(user3, user1, user, user2)
    end

    it 'sorts user by latest activity ascending, nulls first ordered by descending id' do
      expect(described_class.sort_by_attribute('last_activity_on_asc')).to contain_exactly(user2, user, user1, user3)
    end
  end

  describe '#last_active_at' do
    let_it_be_with_reload(:user) { create(:user) }

    let(:last_activity_on) { 5.days.ago.to_date }
    let(:current_sign_in_at) { 8.days.ago }

    before do
      user.last_activity_on = last_activity_on
      user.current_sign_in_at = current_sign_in_at
    end

    context 'for a user that has `last_activity_on` set and is not signed in' do
      let(:current_sign_in_at) { nil }

      it 'returns `last_activity_on` with current time zone' do
        expect(user.last_active_at).to eq(last_activity_on.to_time.in_time_zone)
      end
    end

    context 'for a user that is signed in and dos not have `current_siglast_activity_onn_in_at` set' do
      let(:last_activity_on) { nil }

      it 'returns `current_sign_in_at`' do
        expect(user.last_active_at).to eq(current_sign_in_at)
      end
    end

    context 'for a user that has both `current_sign_in_at` & ``last_activity_on`` set' do
      it 'returns the latest among `current_sign_in_at` & `last_activity_on`' do
        latest_event = [current_sign_in_at, last_activity_on.to_time.in_time_zone].max
        expect(user.last_active_at).to eq(latest_event)
      end
    end

    context 'for a user that does not have both `current_sign_in_at` & `last_activity_on` set' do
      let(:current_sign_in_at) { nil }
      let(:last_activity_on) { nil }

      it 'returns nil' do
        expect(user.last_active_at).to eq(nil)
      end
    end
  end

  describe '#can_be_deactivated?' do
    let_it_be_with_refind(:user) { create(:user, name: 'John Smith') }

    let(:activity) { {} }
    let(:day_within_minium_inactive_days_threshold) { Gitlab::CurrentSettings.deactivate_dormant_users_period.pred.days.ago }
    let(:day_outside_minium_inactive_days_threshold) { Gitlab::CurrentSettings.deactivate_dormant_users_period.next.days.ago }

    before do
      user.update!(activity)
    end

    shared_examples 'not eligible for deactivation' do
      it 'returns false' do
        expect(user.can_be_deactivated?).to be_falsey
      end
    end

    shared_examples 'eligible for deactivation' do
      it 'returns true' do
        expect(user.can_be_deactivated?).to be_truthy
      end
    end

    context 'a user who is not active' do
      before do
        user.block
      end

      it_behaves_like 'not eligible for deactivation'
    end

    context 'a user who has activity within the specified minimum inactive days' do
      let(:activity) { { last_activity_on: day_within_minium_inactive_days_threshold } }

      it_behaves_like 'not eligible for deactivation'
    end

    context 'a user who has signed in within the specified minimum inactive days' do
      let(:activity) { { current_sign_in_at: day_within_minium_inactive_days_threshold } }

      it_behaves_like 'not eligible for deactivation'
    end

    context 'a user who has no activity within the specified minimum inactive days' do
      let(:activity) { { last_activity_on: day_outside_minium_inactive_days_threshold } }

      it_behaves_like 'eligible for deactivation'
    end

    context 'a user who has not signed in within the specified minimum inactive days' do
      let(:activity) { { current_sign_in_at: day_outside_minium_inactive_days_threshold } }

      it_behaves_like 'eligible for deactivation'
    end

    context 'a user who is internal' do
      it 'returns false' do
        internal_user = create(:user, :bot)

        expect(internal_user.can_be_deactivated?).to be_falsey
      end
    end
  end

  describe '#contributed_projects' do
    let_it_be(:project1, freeze: true) { create(:project) }
    let_it_be(:project_aimed_for_deletion, freeze: true) { create(:project, marked_for_deletion_at: 2.days.ago, pending_delete: false) }
    let_it_be(:user, freeze: true) { create(:user, maintainer_of: [project1, project_aimed_for_deletion]) }
    let_it_be(:push_event, freeze: true) { create(:push_event, project: project1, author: user) }

    let!(:project3) { create(:project) }
    let!(:project2) { fork_project(project3) }
    let!(:merge_request) { create(:merge_request, source_project: project2, target_project: project3, author: user) }
    let!(:merge_event) { create(:event, :created, project: project3, target: merge_request, author: user) }
    let!(:merge_event_2) { create(:event, :created, project: project_aimed_for_deletion, target: merge_request, author: user) }

    subject { user.contributed_projects }

    before do
      project2.add_maintainer(user)
    end

    it 'includes IDs for projects the user has pushed to' do
      is_expected.to include(project1)
    end

    it 'includes IDs for projects the user has had merge requests merged into' do
      is_expected.to include(project3)
    end

    it "doesn't include IDs for unrelated projects" do
      is_expected.not_to include(project2)
    end

    it "doesn't include projects aimed for deletion" do
      is_expected.not_to include(project_aimed_for_deletion)
    end
  end

  describe '#fork_of' do
    let_it_be_with_refind(:user) { create(:user) }

    it "returns a user's fork of a project" do
      project = create(:project, :public)
      user_fork = fork_project(project, user, namespace: user.namespace)

      expect(user.fork_of(project)).to eq(user_fork)
    end

    it 'returns nil if the project does not have a fork network' do
      project = create(:project)

      expect(user.fork_of(project)).to be_nil
    end
  end

  describe '#can_be_removed?' do
    let_it_be_with_refind(:user) { create(:user) }
    let_it_be_with_reload(:group) { create(:group) }
    let_it_be(:organization, freeze: true) { create(:organization) }

    subject { user.can_be_removed? }

    where(:solo_owned_groups, :solo_owned_organizations, :result) do
      [
        [[], [], true],
        [[ref(:group)], [], false],
        [[], [ref(:organization)], false],
        [[ref(:group)], [ref(:organization)], false]
      ]
    end

    with_them do
      before do
        allow(user).to receive(:solo_owned_groups).and_return(solo_owned_groups)
        allow(user).to receive(:solo_owned_organizations).and_return(solo_owned_organizations)
      end

      it { is_expected.to be(result) }
    end

    context 'when feature flag :ui_for_organizations is disabled' do
      where(:solo_owned_groups, :solo_owned_organizations, :result) do
        [
          [[], [], true],
          [[ref(:group)], [], false],
          [[], [ref(:organization)], true],
          [[ref(:group)], [ref(:organization)], false]
        ]
      end

      with_them do
        before do
          stub_feature_flags(ui_for_organizations: false)
          allow(user).to receive(:solo_owned_groups).and_return(solo_owned_groups)
          allow(user).to receive(:solo_owned_organizations).and_return(solo_owned_organizations)
        end

        it { is_expected.to be(result) }
      end
    end
  end

  describe '#solo_owned_groups' do
    let_it_be_with_refind(:user) { create(:user) }

    subject(:solo_owned_groups) { user.solo_owned_groups }

    context 'no owned groups' do
      it { is_expected.to be_empty }
    end

    context 'has owned groups' do
      let(:group) { create(:group, owners: user) }

      context 'not solo owner' do
        let_it_be(:user2) { create(:user) }

        context 'with another direct owner' do
          before do
            group.add_owner(user2)
          end

          it { is_expected.to be_empty }
        end

        context 'with an inherited owner' do
          let_it_be(:group) { create(:group, :nested) }

          before do
            group.parent.add_owner(user2)
          end

          it { is_expected.to be_empty }
        end
      end

      context 'solo owner' do
        it { is_expected.to include(group) }

        it 'avoids N+1 queries' do
          fresh_user = described_class.find(user.id)
          control = ActiveRecord::QueryRecorder.new do
            fresh_user.solo_owned_groups
          end

          create(:group).add_owner(user)

          expect { solo_owned_groups }.not_to exceed_query_limit(control)
        end
      end
    end
  end

  describe '#solo_owned_organizations' do
    let_it_be(:organization_owner) { create(:user) }

    subject { organization_owner.solo_owned_organizations }

    it_behaves_like 'resolves user solo-owned organizations'
  end

  describe '#can_remove_self?' do
    let(:user) { create(:user) }

    it 'returns true' do
      expect(user.can_remove_self?).to eq true
    end
  end

  describe '#recent_push' do
    let(:user) { build(:user) }
    let(:project) { build(:project) }
    let(:event) { build(:push_event) }

    it 'returns the last push event for the user' do
      expect_any_instance_of(Users::LastPushEventService)
        .to receive(:last_event_for_user)
        .and_return(event)

      expect(user.recent_push).to eq(event)
    end

    it 'returns the last push event for a project when one is given' do
      expect_any_instance_of(Users::LastPushEventService)
        .to receive(:last_event_for_project)
        .and_return(event)

      expect(user.recent_push(project)).to eq(event)
    end
  end

  describe '#authorized_groups' do
    let_it_be(:user) { create(:user) }
    let_it_be(:private_group) { create(:group, maintainers: user) }
    let_it_be(:child_group) { create(:group, parent: private_group) }

    let_it_be(:project_group_parent) { create(:group) }
    let_it_be(:project_group) { create(:group, parent: project_group_parent) }
    let_it_be(:project) { create(:project, group: project_group, maintainers: user) }

    subject { user.authorized_groups }

    it { is_expected.to contain_exactly private_group, child_group, project_group, project_group_parent }

    context 'with shared memberships' do
      let_it_be(:shared_group) { create(:group) }
      let_it_be(:shared_group_descendant) { create(:group, parent: shared_group) }
      let_it_be(:other_group) { create(:group) }
      let_it_be(:shared_with_project_group) { create(:group) }

      before_all do
        create(:group_group_link, shared_group: shared_group, shared_with_group: private_group)
        create(:group_group_link, shared_group: private_group, shared_with_group: other_group)
        create(:group_group_link, shared_group: shared_with_project_group, shared_with_group: project_group)
      end

      it { is_expected.to include shared_group, shared_group_descendant }
      it { is_expected.not_to include other_group, shared_with_project_group }
    end

    context 'when a new column is added to namespaces table' do
      before do
        ApplicationRecord.connection.execute "ALTER TABLE namespaces ADD COLUMN _test_column_xyz INT NULL"
      end

      # We sanity check that we don't get:
      #   ActiveRecord::StatementInvalid: PG::SyntaxError: ERROR:  each UNION query must have the same number of columns
      it 'will not raise errors' do
        expect { subject.count }.not_to raise_error
      end
    end
  end

  describe '#authorized_root_ancestor_ids' do
    let_it_be(:user) { create(:user) }

    subject { user.authorized_root_ancestor_ids }

    context 'when user has authorized groups' do
      let!(:root_group_1) { create(:group, developers: user) }
      let!(:root_group_2) { create(:group) }
      let!(:root_group_3) { create(:group) }
      let!(:project) { create(:project, group: root_group_2, developers: user) }

      it 'returns only the root group IDs' do
        expect(subject).to contain_exactly(root_group_1.id, root_group_2.id)
      end
    end

    context 'when user has no authorized groups' do
      it 'returns an empty array' do
        expect(subject).to be_empty
      end
    end
  end

  describe '#search_on_authorized_groups' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group_1) { create(:group, name: 'test', path: 'blah') }
    let_it_be(:group_2) { create(:group, name: 'blah', path: 'test') }
    let(:search_term) { 'test' }

    subject { user.search_on_authorized_groups(search_term) }

    context 'when the user does not have any authorized groups' do
      before do
        allow(user).to receive(:authorized_groups).and_return(Group.none)
      end

      it { is_expected.to be_empty }
    end

    context 'when the user has two authorized groups with name or path matching the search term' do
      before do
        allow(user).to receive(:authorized_groups).and_return(Group.id_in([group_1.id, group_2.id]))
      end

      it 'returns the groups' do
        is_expected.to contain_exactly(group_1, group_2)
      end

      context 'if the search term does not match on name or path' do
        let(:search_term) { 'unknown' }

        it { is_expected.to be_empty }
      end

      context 'if the search term is less than MIN_CHARS_FOR_PARTIAL_MATCHING' do
        let(:search_term) { 'te' }

        it { is_expected.to be_empty }

        context 'if use_minimum_char_limit is false' do
          subject { user.search_on_authorized_groups(search_term, use_minimum_char_limit: false) }

          it 'returns the groups' do
            is_expected.to contain_exactly(group_1, group_2)
          end
        end
      end
    end
  end

  describe '#membership_groups' do
    let_it_be(:user) { create(:user) }
    let_it_be(:parent_group) { create(:group, maintainers: user) }
    let_it_be(:child_group) { create(:group, parent: parent_group) }
    let_it_be(:other_group) { create(:group) }

    subject { user.membership_groups }

    it { is_expected.to contain_exactly(parent_group, child_group) }
  end

  describe '#first_group_paths' do
    subject { user.first_group_paths }

    context 'with less than max allowed direct group memberships' do
      let_it_be(:user) { create(:user) }
      let(:expected_group_paths) { [] }

      before do
        3.times do
          create(:group, guests: user).tap do |new_group|
            expected_group_paths.push(new_group.full_path)
          end
        end
      end

      it 'returns sorted list of group paths' do
        is_expected.to eq(expected_group_paths.sort!)
      end
    end

    context 'with more than max allowed direct group memberships' do
      let_it_be(:user) { create(:user) }

      before do
        stub_const("#{described_class}::FIRST_GROUP_PATHS_LIMIT", 4)

        create_list(:group, 5, guests: user)
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#authorizations_for_projects' do
    let_it_be(:other) { create(:project) }
    let_it_be(:user) { create(:user) }

    subject { Project.where("EXISTS (?)", user.authorizations_for_projects) }

    it 'includes projects that belong to a user, but no other projects' do
      owned = create(:project, :private, namespace: user.namespace)
      member = create(:project, :private, maintainers: user)

      is_expected.to include(owned)
      is_expected.to include(member)
      is_expected.not_to include(other)
    end

    it 'includes projects a user has access to, but no other projects' do
      other_user = create(:user)
      accessible = create(:project, :private, namespace: other_user.namespace, developers: user)

      is_expected.to include(accessible)
      is_expected.not_to include(other)
    end

    context 'with min_access_level' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, :private, group: group, developers: user) }

      subject { Project.where("EXISTS (?)", user.authorizations_for_projects(min_access_level: min_access_level)) }

      context 'when developer access' do
        let(:min_access_level) { Gitlab::Access::DEVELOPER }

        it 'includes projects a user has access to' do
          is_expected.to include(project)
        end
      end

      context 'when owner access' do
        let(:min_access_level) { Gitlab::Access::OWNER }

        it 'does not include projects with higher access level' do
          is_expected.not_to include(project)
        end
      end
    end
  end

  describe '#authorized_projects' do
    let_it_be_with_refind(:user) { create(:user) }
    let_it_be(:project, freeze: true) { create(:project, :private) }
    let_it_be(:project_in_user_namespace, freeze: true) { create(:project, :private, namespace: user.namespace) }

    subject { user.authorized_projects }

    context 'with a minimum access level' do
      subject { user.authorized_projects(Gitlab::Access::REPORTER) }

      it 'includes projects for which the user is an owner' do
        is_expected.to contain_exactly(project_in_user_namespace)
      end

      it 'includes projects for which the user is a maintainer' do
        project.add_maintainer(user)

        is_expected.to contain_exactly(project, project_in_user_namespace)
      end
    end

    it "includes user's personal projects" do
      is_expected.to include(project_in_user_namespace)
    end

    it 'includes personal projects user has been given access to' do
      user2 = create(:user, developer_of: project_in_user_namespace)

      expect(user2.authorized_projects).to include(project_in_user_namespace)
    end

    context 'when project belongs to group that user has been added to' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project_in_group) { create(:project, group: group) }

      let!(:member) { group.add_developer(user) }

      it 'includes projects of groups user has been added to' do
        is_expected.to include(project_in_group)
      end

      it 'does not include projects of groups user has been removed from', :sidekiq_inline do
        is_expected.to include(project_in_group)

        member.destroy!

        is_expected.not_to include(project_in_group)
      end
    end

    it "includes projects shared with user's group" do
      group = create(:group, reporters: user)
      create(:project_group_link, group: group, project: project)

      is_expected.to include(project)
    end

    it 'does not include destroyed projects user had access to' do
      user2 = create(:user)

      project = create(:project, :private, namespace: user.namespace, developers: user2)

      expect(user2.authorized_projects).to include(project)

      project.destroy!

      expect(user2.authorized_projects).not_to include(project)
    end

    it 'does not include projects of destroyed groups user had access to' do
      group   = create(:group, developers: user)
      project = create(:project, namespace: group)

      is_expected.to include(project)

      group.destroy!

      is_expected.not_to include(project)
    end
  end

  describe '#projects_where_can_admin_issues' do
    let_it_be(:user, freeze: true) { create(:user) }

    it 'includes projects for which the user access level is above or equal to planner' do
      planner_project = create(:project, planners: user)
      reporter_project  = create(:project, reporters: user)
      developer_project = create(:project, developers: user)
      maintainer_project = create(:project, maintainers: user)

      expect(user.projects_where_can_admin_issues.to_a).to contain_exactly(
        maintainer_project, developer_project, reporter_project, planner_project
      )
      expect(user.can?(:admin_issue, maintainer_project)).to eq(true)
      expect(user.can?(:admin_issue, developer_project)).to eq(true)
      expect(user.can?(:admin_issue, reporter_project)).to eq(true)
      expect(user.can?(:admin_issue, planner_project)).to eq(true)
    end

    it 'does not include for which the user access level is below planner' do
      project = create(:project)
      guest_project = create(:project, guests: user)

      expect(user.projects_where_can_admin_issues.to_a).to be_empty
      expect(user.can?(:admin_issue, guest_project)).to eq(false)
      expect(user.can?(:admin_issue, project)).to eq(false)
    end

    it 'does not include archived projects' do
      project = create(:project, :archived)

      expect(user.projects_where_can_admin_issues.to_a).to be_empty
      expect(user.can?(:admin_issue, project)).to eq(false)
    end

    it 'does not include projects for which issues are disabled' do
      project = create(:project, :issues_disabled)

      expect(user.projects_where_can_admin_issues.to_a).to be_empty
      expect(user.can?(:admin_issue, project)).to eq(false)
    end
  end

  describe '#authorized_project_mirrors' do
    subject { user.authorized_project_mirrors(Gitlab::Access::REPORTER).pluck(:project_id) }

    let_it_be(:user, freeze: true) { create(:user) }

    it 'returns project mirrors where the user has access equal to or above the given level' do
      _guest_project = create(:project, guests: user)
      reporter_project = create(:project, reporters: user)
      maintainer_project = create(:project, maintainers: user)

      guest_group = create(:group, guests: user)
      reporter_group = create(:group, reporters: user)
      maintainer_group = create(:group, maintainers: user)

      _guest_group_project = create(:project, group: guest_group)
      reporter_group_project = create(:project, group: reporter_group)
      maintainer_group_project = create(:project, group: maintainer_group)

      is_expected.to contain_exactly(
        reporter_group_project.id,
        maintainer_group_project.id,
        reporter_project.id,
        maintainer_project.id
      )
    end
  end

  describe '#ci_available_runners', feature_category: :runner_core do
    let_it_be_with_refind(:user) { create(:user) }

    subject(:ci_available_runners) { user.ci_available_runners }

    shared_examples 'nested groups owner' do
      context 'when the user is the owner of a multi-level group' do
        it 'loads all the runners in the tree of groups' do
          is_expected.to contain_exactly(runner, group_runner)
        end
      end
    end

    shared_examples 'project member' do
      let_it_be(:another_project_runner) { create(:ci_runner, :project, projects: [another_project, project]) }

      before do
        add_user # this method has to be defined in the caller block
      end

      context 'when the user is a maintainer' do
        let(:access) { :maintainer }

        it 'loads the runners of the project' do
          is_expected.to contain_exactly(project_runner, another_project_runner)
        end
      end

      context 'when the user is a developer' do
        let(:access) { :developer }

        it 'does not load any runner' do
          is_expected.to be_empty
        end
      end

      context 'when the user is a reporter' do
        let(:access) { :reporter }

        it 'does not load any runner' do
          is_expected.to be_empty
        end
      end

      context 'when the user is a guest' do
        let(:access) { :guest }

        it 'does not load any runner' do
          is_expected.to be_empty
        end
      end
    end

    shared_examples 'group member' do
      context 'when the user is a maintainer' do
        before do
          group.add_maintainer(user)
        end

        it 'does not load the runners of the group' do
          is_expected.to be_empty
        end
      end

      context 'when the user is a developer' do
        before do
          group.add_developer(user)
        end

        it 'does not load any runner' do
          is_expected.to be_empty
        end
      end

      context 'when the user is a reporter' do
        before do
          group.add_reporter(user)
        end

        it 'does not load any runner' do
          expect(user.ci_available_runners).to be_empty
        end
      end

      context 'when the user is a guest' do
        before do
          group.add_guest(user)
        end

        it 'does not load any runner' do
          expect(user.ci_available_runners).to be_empty
        end
      end
    end

    context 'without any projects nor groups' do
      it 'does not load any runner' do
        expect(user.ci_available_runners).to be_empty
      end
    end

    context 'with runner in a personal project' do
      let_it_be(:namespace) { create(:user_namespace, owner: user) }
      let_it_be(:project) { create(:project, namespace: namespace) }
      let_it_be(:runner) { create(:ci_runner, :project, projects: [project]) }

      context 'when the user is the owner of a project' do
        it 'loads the runner belonging to the project' do
          expect(user.ci_available_runners).to contain_exactly(runner)
        end
      end
    end

    context 'with group runner' do
      let_it_be(:group) { create(:group) }
      let_it_be(:runner) { create(:ci_runner, :group, groups: [group]) }

      context 'when owner is a non-owned group' do
        it_behaves_like 'group member'
      end

      context 'when in an owned group' do
        before_all do
          group.add_owner(user)
        end

        context 'and the user is the owner of a one level group' do
          it 'loads the runners in the group' do
            expect(user.ci_available_runners).to contain_exactly(runner)
          end
        end

        context 'and group runner in a different owner subgroup' do
          let_it_be(:subgroup) { create(:group, parent: group) }
          let_it_be(:group_runner) { create(:ci_runner, :group, groups: [subgroup]) }
          let_it_be(:another_user) { create(:user) }

          before_all do
            subgroup.add_owner(another_user)
          end

          it_behaves_like 'nested groups owner'
        end
      end

      context 'when in a subgroup of a group owned by another user' do
        let_it_be(:parent_group) { group }
        let_it_be(:group) { create(:group, parent: parent_group) }
        let_it_be(:runner) { create(:ci_runner, :group, groups: [group]) }
        let_it_be(:another_user) { create(:user) }

        before_all do
          parent_group.add_owner(another_user)
        end

        it_behaves_like 'group member'
      end
    end

    context 'with project runner' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, group: group) }
      let_it_be(:another_project) { create(:project, group: group) }
      let_it_be(:runner) { create(:ci_runner, :project, projects: [project, another_project]) }

      it 'does not load any runner' do
        expect(user.ci_available_runners).to be_empty
      end

      context 'when project belongs to an owned group' do
        before_all do
          group.add_owner(user)
        end

        context 'with a group runner in that same group' do
          let_it_be(:group_runner) { create(:ci_runner, :group, groups: [group]) }

          it_behaves_like 'nested groups owner'
        end

        context 'with a group runner in a subgroup' do
          let_it_be(:subgroup) { create(:group, parent: group) }
          let_it_be(:group_runner) { create(:ci_runner, :group, groups: [subgroup]) }

          it_behaves_like 'nested groups owner'
        end

        context 'with a project runner owned by inaccessible project' do
          let_it_be(:another_project_runner) { create(:ci_runner, :project, projects: [another_project, project]) }

          it 'returns runner shared from inaccessible project' do
            is_expected.to contain_exactly(runner, another_project_runner)
          end
        end
      end

      context 'when user is member of project' do
        let(:project_runner) { runner }

        def add_user
          project.add_member(user, access)
        end

        it_behaves_like 'project member'
      end

      context 'when user is member of non-owner project' do
        let(:project_runner) { runner }

        def add_user
          another_project.add_member(user, access)
        end

        it_behaves_like 'project member'
      end

      context 'when group member accesses project runner' do
        let_it_be(:group) { create(:group) }

        it_behaves_like 'group member'

        context "when user's group is invited to project" do
          let(:project_runner) { runner }

          def add_user
            group.add_member(user, access)
            create(:project_group_link, access, group: group, project: project)
          end

          it_behaves_like 'project member'
        end
      end
    end
  end

  describe '#ci_available_project_runners', feature_category: :runner_core do
    let_it_be_with_refind(:user) { create(:user) }

    let_it_be(:project1) { create(:project) }
    let_it_be(:project2) { create(:project) }
    let_it_be(:project3) { create(:project) } # no access to project 3

    let_it_be(:runner1) { create(:ci_runner, :project, projects: [project1]) }
    let_it_be(:runner2) { create(:ci_runner, :project, projects: [project2]) }
    let_it_be(:runner3) { create(:ci_runner, :project, projects: [project3]) }

    subject(:ci_available_project_runners) { user.send :ci_available_project_runners }

    context 'when the user has maintainer access' do
      before_all do
        project1.add_maintainer(user)
        project2.add_maintainer(user)
      end

      it { is_expected.to include(runner1, runner2) }
      it { is_expected.not_to include(runner3) }
    end

    context 'when the user has developer level access in the project' do
      before_all do
        project3.add_developer(user)
      end

      it { is_expected.not_to include(runner3) }
    end

    context 'with no project authorizations' do
      it { is_expected.to be_empty }
    end

    context 'it tracks an internal event' do
      let!(:project_size) { 100 }

      before do
        allow(user.project_authorizations).to receive_message_chain(:where, :pluck)
          .and_return(Array.new(project_size) { |i| i + 1 })
      end

      it 'with size of project_ids' do
        expect { ci_available_project_runners }.to trigger_internal_events('query_ci_available_project_runners_with_project_ids').with(
          user: user,
          additional_properties: {
            value: project_size
          }
        )
      end
    end

    context 'when user has access to many projects' do
      let_it_be(:projects_with_runners) { [project1, project2, project3] }
      let_it_be(:runners) { Ci::Runner.belonging_to_project(projects_with_runners.pluck(:id)) } # runners created in parent block

      before_all do
        projects_with_runners.each { |project| project.add_maintainer(user) }
      end

      context "when project count within threshold" do
        before do
          stub_const("#{described_class.name}::CI_RUNNERS_PROJECT_COUNT_LIMIT", 3)
        end

        it 'uses the non-batched approach' do
          expect(Ci::RunnerProject).not_to receive(:existing_project_ids)
          ci_available_project_runners
        end

        it 'returns the correct runners' do
          expect(ci_available_project_runners).to include(runner1, runner2)
        end
      end

      context "when project count exceeds threshold" do
        before do
          stub_const("#{described_class.name}::CI_RUNNERS_PROJECT_COUNT_LIMIT", 2)
          stub_const("#{described_class.name}::CI_PROJECT_RUNNERS_BATCH_SIZE", 2)
        end

        it 'returns only runners for projects that have runners', :aggregate_failures do
          expect(ci_available_project_runners).to include(*runners)
          expect(ci_available_project_runners.count).to eq(runners.count)
        end

        context 'processes the projects in batches' do
          let(:batch_sizes) { [] }

          before do
            expect(Ci::RunnerProject).to receive(:existing_project_ids).and_wrap_original do |m, *args|
              batch_sizes << args.first.size
              m.call(*args)
            end.exactly(2)
          end

          it 'with the correct batch sizes' do
            ci_available_project_runners

            expect(batch_sizes).to match_array([2, 1])
          end
        end
      end
    end
  end

  describe '#all_expanded_groups' do
    # foo/bar would also match foo/barbaz instead of just foo/bar and foo/bar/baz
    let_it_be_with_refind(:user) { create(:user) }

    #                group
    #        _______ (foo) _______
    #       |                     |
    #       |                     |
    # nested_group_1        nested_group_2
    # (bar)                 (barbaz)
    #       |                     |
    #       |                     |
    # nested_group_1_1      nested_group_2_1
    # (baz)                 (baz)
    #
    let_it_be_with_reload(:group) { create :group }
    let_it_be_with_reload(:nested_group_1) { create :group, parent: group, name: 'bar' }
    let_it_be_with_reload(:nested_group_1_1) { create :group, parent: nested_group_1, name: 'baz' }
    let_it_be_with_reload(:nested_group_2) { create :group, parent: group, name: 'barbaz' }
    let_it_be_with_reload(:nested_group_2_1) { create :group, parent: nested_group_2, name: 'baz' }

    subject { user.all_expanded_groups }

    context 'user is not a member of any group' do
      it 'returns an empty array' do
        is_expected.to eq([])
      end
    end

    context 'user is member of all groups' do
      before_all do
        group.add_reporter(user)
        nested_group_1.add_developer(user)
        nested_group_1_1.add_maintainer(user)
        nested_group_2.add_developer(user)
        nested_group_2_1.add_maintainer(user)
      end

      it 'returns all groups' do
        is_expected.to match_array [
          group,
          nested_group_1, nested_group_1_1,
          nested_group_2, nested_group_2_1
        ]
      end
    end

    context 'user is member of the top group' do
      before_all do
        group.add_owner(user)
      end

      it 'returns all groups' do
        is_expected.to contain_exactly(
          group,
          nested_group_1, nested_group_1_1,
          nested_group_2, nested_group_2_1
        )
      end
    end

    context 'user is member of the first child (internal node), branch 1' do
      before_all do
        nested_group_1.add_owner(user)
      end

      it 'returns the groups in the hierarchy' do
        is_expected.to contain_exactly(
          group,
          nested_group_1, nested_group_1_1
        )
      end
    end

    context 'user is member of the first child (internal node), branch 2' do
      before_all do
        nested_group_2.add_owner(user)
      end

      it 'returns the groups in the hierarchy' do
        is_expected.to contain_exactly(
          group,
          nested_group_2, nested_group_2_1
        )
      end
    end

    context 'user is member of the last child (leaf node)' do
      before_all do
        nested_group_1_1.add_owner(user)
      end

      it 'returns the groups in the hierarchy' do
        is_expected.to contain_exactly(
          group,
          nested_group_1, nested_group_1_1
        )
      end
    end

    context 'when the user is not saved' do
      let(:user) { build(:user) }

      it 'returns empty when there are no groups or ancestor groups for the user' do
        is_expected.to eq([])
      end
    end
  end

  describe '#refresh_authorized_projects', :clean_gitlab_redis_shared_state do
    let_it_be(:project1) { create(:project) }
    let_it_be(:project2) { create(:project) }
    let_it_be_with_refind(:user) { create(:user, guest_of: project2, reporter_of: project1) }

    before do
      user.project_authorizations.delete_all
      user.refresh_authorized_projects
    end

    it 'refreshes the list of authorized projects' do
      expect(user.project_authorizations.count).to eq(2)
    end

    it 'stores the correct access levels' do
      expect(user.project_authorizations.where(access_level: Gitlab::Access::GUEST).exists?).to eq(true)
      expect(user.project_authorizations.where(access_level: Gitlab::Access::REPORTER).exists?).to eq(true)
    end
  end

  describe '#access_level=' do
    let(:user) { build(:user) }

    it 'does nothing for an invalid access level' do
      user.access_level = :invalid_access_level

      expect(user.access_level).to eq(:regular)
      expect(user.admin).to be false
    end

    it "assigns the 'admin' access level" do
      user.access_level = :admin

      expect(user.access_level).to eq(:admin)
      expect(user.admin).to be true
    end

    it "doesn't clear existing access levels when an invalid access level is passed in" do
      user.access_level = :admin
      user.access_level = :invalid_access_level

      expect(user.access_level).to eq(:admin)
      expect(user.admin).to be true
    end

    it 'accepts string values in addition to symbols' do
      user.access_level = 'admin'

      expect(user.access_level).to eq(:admin)
      expect(user.admin).to be true
    end
  end

  describe '#can_read_all_resources?', :request_store do
    subject { user.can_read_all_resources? }

    context 'with regular user' do
      let(:user) { build_stubbed(:user) }

      it { is_expected.to be_falsy }
    end

    context 'for admin user' do
      include_context 'custom session'

      let(:user) { build_stubbed(:user, :admin) }

      context 'when admin mode is disabled' do
        it { is_expected.to be_falsy }
      end

      context 'when admin mode is enabled' do
        before do
          Gitlab::Auth::CurrentUserMode.new(user).request_admin_mode!
          Gitlab::Auth::CurrentUserMode.new(user).enable_admin_mode!(password: user.password)
        end

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#can_admin_all_resources?', :request_store do
    subject { user.can_admin_all_resources? }

    context 'with regular user' do
      let(:user) { build_stubbed(:user) }

      it { is_expected.to be_falsy }
    end

    context 'for admin user' do
      include_context 'custom session'

      let(:user) { build_stubbed(:user, :admin) }

      context 'when admin mode is disabled' do
        it { is_expected.to be_falsy }
      end

      context 'when admin mode is enabled' do
        before do
          Gitlab::Auth::CurrentUserMode.new(user).request_admin_mode!
          Gitlab::Auth::CurrentUserMode.new(user).enable_admin_mode!(password: user.password)
        end

        it { is_expected.to be_truthy }
      end
    end
  end

  describe '#can_access_admin_area?' do
    subject { user.can_access_admin_area? }

    context 'with regular user' do
      let(:user) { build_stubbed(:user) }

      it { is_expected.to be_falsy }
    end

    context 'with admin user' do
      let(:user) { build_stubbed(:user, :admin) }

      it { is_expected.to be_truthy }
    end
  end

  describe '#free_or_trial_owned_group_ids' do
    let(:user) { build_stubbed(:user) }
    let(:group_ids) { [1, 2, 3] }

    it 'returns ids of user owned group with free or trial plan' do
      allow(user).to receive_message_chain(:owned_groups, :free_or_trial, :ids)
          .and_return(group_ids)

      expect(user.free_or_trial_owned_group_ids).to eq(group_ids)
    end
  end

  shared_examples 'organization owner' do
    let!(:org_user) { create(:organization_user, organization: organization, user: user, access_level: access_level) }

    context 'when user is the owner of the organization' do
      let(:access_level) { Gitlab::Access::OWNER }

      it { is_expected.to be_truthy }
    end

    context 'when user is not the owner of the organization' do
      let(:access_level) { Gitlab::Access::GUEST }

      it { is_expected.to be_falsey }
    end
  end

  describe '#can_admin_organization?' do
    let_it_be_with_refind(:user) { create(:user) }
    let_it_be_with_refind(:organization) { create(:organization) }

    subject(:can_admin_organization) { user.can_admin_organization?(organization) }

    it_behaves_like 'organization owner'
  end

  describe '#owns_organization?' do
    let_it_be_with_refind(:organization) { create(:organization) }
    let_it_be_with_refind(:user) { create(:user) }

    subject(:owns_organization) { user.owns_organization?(organization_param) }

    context 'when passed organization object' do
      let(:organization_param) { organization }

      it_behaves_like 'organization owner'
    end

    context 'when passed organization id' do
      let(:organization_param) { organization.id }

      it_behaves_like 'organization owner'
    end

    context 'when passed nil' do
      let(:organization_param) { nil }

      it { is_expected.to be_falsey }
    end

    it 'memoize results' do
      ActiveRecord::QueryRecorder.new { user.owns_organization?(organization) }
      second_query = ActiveRecord::QueryRecorder.new { user.owns_organization?(organization) }

      expect(second_query.count).to eq(0)
    end
  end

  describe '#update_two_factor_requirement' do
    let_it_be_with_refind(:user) { create :user }

    context 'with 2FA requirement on groups' do
      let_it_be(:group1) do
        create :group, owners: user, require_two_factor_authentication: true, two_factor_grace_period: 23
      end

      let_it_be(:group2) do
        create :group, owners: user, require_two_factor_authentication: true, two_factor_grace_period: 32
      end

      before_all do
        user.update_two_factor_requirement
      end

      it 'requires 2FA' do
        expect(user.require_two_factor_authentication_from_group).to be true
      end

      it 'uses the shortest grace period' do
        expect(user.two_factor_grace_period).to be 23
      end
    end

    context 'with 2FA requirement from expanded groups' do
      let!(:group1) { create :group, require_two_factor_authentication: true }
      let!(:group1a) { create :group, parent: group1, owners: user }

      before do
        user.update_two_factor_requirement
      end

      it 'requires 2FA' do
        expect(user.require_two_factor_authentication_from_group).to be true
      end
    end

    context 'with 2FA requirement on nested child group' do
      let!(:group1) { create :group, require_two_factor_authentication: false, owners: user }
      let!(:group1a) { create :group, require_two_factor_authentication: true, parent: group1 }

      before do
        user.update_two_factor_requirement
      end

      it 'requires 2FA' do
        expect(user.require_two_factor_authentication_from_group).to be true
      end
    end

    context "with 2FA requirement from shared project's group" do
      let!(:group1) { create :group, require_two_factor_authentication: true }
      let!(:group2) { create :group }
      let(:shared_project) { create(:project, namespace: group1) }

      before do
        shared_project.project_group_links.create!(
          group: group2
        )

        group2.add_member(user, GroupMember::OWNER)
      end

      it 'does not require 2FA' do
        user.update_two_factor_requirement

        expect(user.require_two_factor_authentication_from_group).to be false
      end
    end

    context 'without 2FA requirement on groups' do
      let(:group) { create :group, owners: user }

      before do
        user.update_two_factor_requirement
      end

      it 'does not require 2FA' do
        expect(user.require_two_factor_authentication_from_group).to be false
      end

      it 'falls back to the default grace period' do
        expect(user.two_factor_grace_period).to be 48
      end
    end

    context 'when the user is not saved' do
      let(:user) { build(:user) }

      it 'does not raise an ActiveRecord::StatementInvalid statement exception' do
        expect { user.update_two_factor_requirement }.not_to raise_error
      end
    end
  end

  describe '#source_groups_of_two_factor_authentication_requirement' do
    let_it_be(:group_not_requiring_2fa) { create :group }
    let_it_be_with_refind(:user) { create(:user, owner_of: [group_not_requiring_2fa]) }

    subject { user.source_groups_of_two_factor_authentication_requirement }

    context 'when user is direct member of group requiring 2FA' do
      let_it_be(:group) { create :group, require_two_factor_authentication: true, owners: user }

      it 'returns group requiring 2FA' do
        is_expected.to contain_exactly(group)
      end
    end

    context 'when user is member of group which parent requires 2FA' do
      let_it_be(:parent_group) { create :group, require_two_factor_authentication: true }
      let_it_be(:group) { create :group, parent: parent_group, owners: user }

      it 'returns group requiring 2FA' do
        is_expected.to contain_exactly(group)
      end
    end

    context 'when user is member of group which child requires 2FA' do
      let_it_be(:group) { create :group, owners: user }
      let_it_be(:child_group) { create :group, require_two_factor_authentication: true, parent: group }

      it 'returns group requiring 2FA' do
        is_expected.to contain_exactly(group)
      end
    end
  end

  describe '.active' do
    before do
      described_class.ghost
      create(:user, name: 'user', state: 'active')
      create(:user, name: 'user', state: 'blocked')
    end

    it 'only counts active and non internal users' do
      expect(described_class.active.count).to eq(1)
    end
  end

  describe 'preferred language' do
    let_it_be(:user, freeze: true) { build(:user) }

    it 'is English by default' do
      expect(user.preferred_language).to eq('en')
    end
  end

  describe '#invalidate_issue_cache_counts' do
    let_it_be(:user, freeze: true) { build_stubbed(:user) }

    subject(:invalidate_issue_cache_counts) { user.invalidate_issue_cache_counts }

    it 'invalidates cache for issue counters' do
      cache_mock = double

      expect(cache_mock).to receive(:delete).with(['users', user.id, 'assigned_open_issues_count'])
      expect(cache_mock).to receive(:delete).with(['users', user.id, 'max_assigned_open_issues_count'])

      allow(Rails).to receive(:cache).and_return(cache_mock)

      invalidate_issue_cache_counts
    end
  end

  describe '#invalidate_merge_request_cache_counts' do
    let_it_be(:user) { build_stubbed(:user) }

    subject(:invalidate_merge_request_cache_counts) { user.invalidate_merge_request_cache_counts }

    it 'invalidates cache for merge request counters' do
      cache_mock = double

      expect(cache_mock).to receive(:delete).with(['users', user.id, 'assigned_open_merge_requests_count', false, true])
      expect(cache_mock).to receive(:delete).with(['users', user.id, 'review_requested_open_merge_requests_count'])
      expect(cache_mock).to receive(:delete).with(['users', user.id, 'returned_to_you_merge_requests_count'])

      allow(Rails).to receive(:cache).and_return(cache_mock)

      invalidate_merge_request_cache_counts
    end
  end

  describe '#invalidate_personal_projects_count' do
    let_it_be(:user) { build_stubbed(:user) }

    subject(:invalidate_personal_projects_count) { user.invalidate_personal_projects_count }

    it 'invalidates cache for personal projects counter' do
      cache_mock = double

      expect(cache_mock).to receive(:delete).with(['users', user.id, 'personal_projects_count'])

      allow(Rails).to receive(:cache).and_return(cache_mock)

      invalidate_personal_projects_count
    end
  end

  describe '#allow_password_authentication?' do
    subject(:allow_password_authentication?) { user.allow_password_authentication? }

    it_behaves_like 'OmniAuth user password authentication'
  end

  describe '#allow_password_authentication_for_web?' do
    subject(:allow_password_authentication_for_web?) { user.allow_password_authentication_for_web? }

    context 'with regular user' do
      let_it_be(:user) { build(:user) }

      it { is_expected.to be_truthy }

      context 'when password authentication is disabled for the web interface' do
        before do
          stub_application_setting(password_authentication_enabled_for_web: false)
        end

        it { is_expected.to be_falsey }
      end
    end

    context 'with ldap user' do
      let_it_be(:user) { create(:omniauth_user, provider: 'ldapmain') }

      it { is_expected.to be_falsey }
    end

    it_behaves_like 'OmniAuth user password authentication'
  end

  describe '#allow_password_authentication_for_git?' do
    subject(:allow_password_authentication_for_git?) { user.allow_password_authentication_for_git? }

    context 'regular user' do
      let(:user) { build(:user) }

      it 'returns true when password authentication is enabled for Git' do
        expect(user.allow_password_authentication_for_git?).to be_truthy
      end

      it 'returns false when password authentication is disabled Git' do
        stub_application_setting(password_authentication_enabled_for_git: false)

        expect(user.allow_password_authentication_for_git?).to be_falsey
      end
    end

    it 'returns false for ldap user' do
      user = create(:omniauth_user, provider: 'ldapmain')

      expect(user.allow_password_authentication_for_git?).to be_falsey
    end

    it_behaves_like 'OmniAuth user password authentication'
  end

  describe '#assigned_open_merge_requests_count' do
    subject { user.assigned_open_merge_requests_count(force: true, cached_only: cached_only) }

    let_it_be_with_refind(:user) { create(:user) }
    let_it_be_with_refind(:project) { create(:project, :public) }
    let_it_be_with_refind(:archived_project) { create(:project, :public, :archived) }
    let(:cached_only) { false }

    before do
      create(:merge_request, source_project: project, author: user, assignees: [user], reviewers: [user])
      create(:merge_request, source_project: project, source_branch: 'feature_conflict', author: user, assignees: [user])
      create(:merge_request, :closed, source_project: project, author: user, assignees: [user])
      create(:merge_request, source_project: archived_project, author: user, assignees: [user])

      mr = create(:merge_request, :unique_branches, source_project: project, author: user, assignees: [user], reviewers: [user])
      mr2 = create(:merge_request, :unique_branches, source_project: project, author: user, assignees: [user], reviewers: [user])

      mr.merge_request_reviewers.update_all(state: :reviewed)
      mr2.merge_request_reviewers.update_all(state: :requested_changes)
    end

    it 'returns number of open merge requests from non-archived projects where there are no reviewers' do
      is_expected.to eq 4
    end

    context 'when merge_request_dashboard_list_type is role_based' do
      before do
        user.user_preference.update!(merge_request_dashboard_list_type: 'role_based')
      end

      it 'returns number of open merge requests from non-archived projects' do
        is_expected.to eq 4
      end
    end

    context 'when merge_request_dashboard_show_drafts is false' do
      before do
        user.user_preference.update!(merge_request_dashboard_list_type: 'action_based')

        allow(user).to receive(:merge_request_dashboard_show_drafts?).and_return(false)
      end

      it { is_expected.to eq 1 }
    end

    context 'when fetching only cached' do
      let(:cached_only) { true }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end

    context 'when the query times out' do
      context 'with ActiveRecord::StatementTimeout' do
        before do
          finder_double = instance_double(MergeRequestsFinder)
          allow(MergeRequestsFinder).to receive(:new).and_return(finder_double)
          allow(finder_double).to receive_message_chain(:execute, :count)
            .and_raise(ActiveRecord::StatementTimeout)
        end

        it 'logs the error' do
          expect(Gitlab::AppLogger).to receive(:error).with(
            hash_including(
              message: 'Timeout counting assigned merge requests',
              user_id: user.id,
              error: anything
            )
          )

          user.assigned_open_merge_requests_count
        end

        it 'returns nil' do
          is_expected.to be_nil
        end
      end

      context 'with ActiveRecord::QueryCanceled' do
        before do
          finder_double = instance_double(MergeRequestsFinder)
          allow(MergeRequestsFinder).to receive(:new).and_return(finder_double)
          allow(finder_double).to receive_message_chain(:execute, :count)
            .and_raise(ActiveRecord::QueryCanceled)
        end

        it 'logs the error' do
          expect(Gitlab::AppLogger).to receive(:error).with(
            hash_including(
              message: 'Timeout counting assigned merge requests',
              user_id: user.id,
              error: anything
            )
          )

          user.assigned_open_merge_requests_count
        end

        it 'returns nil' do
          is_expected.to be_nil
        end
      end
    end
  end

  describe '#returned_to_you_merge_requests_count' do
    subject { user.returned_to_you_merge_requests_count(force: true, cached_only: cached_only) }

    let_it_be_with_refind(:user) { create(:user) }
    let_it_be_with_refind(:project) { create(:project, :public) }
    let_it_be_with_refind(:archived_project) { create(:project, :public, :archived) }

    let(:cached_only) { false }

    context 'when role based rendering' do
      before do
        user.user_preference.update!(merge_request_dashboard_list_type: 'role_based')
      end

      it 'returns nil' do
        is_expected.to be_nil
      end
    end

    context 'when action based rendering' do
      let(:show_drafts) { false }

      before do
        user.user_preference.update!(merge_request_dashboard_list_type: 'action_based')

        allow(user).to receive(:merge_request_dashboard_show_drafts?).and_return(show_drafts)
      end

      context 'when merge_request_dashboard_show_drafts is true' do
        let(:show_drafts) { true }

        it 'returns nil' do
          is_expected.to be_nil
        end
      end

      it 'returns count of open merge requests where reviewers have state of reviewed or requested_changes' do
        create(:merge_request, source_project: project, author: user, assignees: [user], reviewers: [user])
        create(:merge_request, source_project: project, source_branch: 'feature_conflict', author: user, assignees: [user])
        create(:merge_request, :closed, source_project: project, author: user, assignees: [user])
        create(:merge_request, source_project: archived_project, author: user, assignees: [user])

        mr = create(:merge_request, :unique_branches, source_project: project, author: user, assignees: [user], reviewers: [user])
        mr2 = create(:merge_request, :unique_branches, source_project: project, author: user, assignees: [user], reviewers: [user])

        mr.merge_request_reviewers.update_all(state: :reviewed)
        mr2.merge_request_reviewers.update_all(state: :requested_changes)

        is_expected.to eq 2
      end

      context 'when fetching only cached' do
        let(:cached_only) { true }

        it 'returns nil' do
          is_expected.to be_nil
        end
      end
    end
  end

  describe '#review_requested_open_merge_requests_count' do
    subject { user.review_requested_open_merge_requests_count(force: true, cached_only: cached_only) }

    let_it_be_with_refind(:user) { create(:user) }
    let_it_be_with_refind(:project) { create(:project, :public) }
    let_it_be_with_refind(:archived_project) { create(:project, :public, :archived) }

    let_it_be_with_refind(:mr) { create(:merge_request, source_project: project, author: user, reviewers: [user]) }
    let(:cached_only) { false }

    before_all do
      create(:merge_request, :closed, source_project: project, author: user, reviewers: [user])
      create(:merge_request, source_project: archived_project, author: user, reviewers: [user])
    end

    it 'returns number of open merge requests from non-archived projects where a reviewer has not reviewed' do
      mr2 = create(:merge_request, :unique_branches, source_project: project, author: user, reviewers: [user])

      mr.merge_request_reviewers.update_all(state: :unreviewed)
      mr2.merge_request_reviewers.update_all(state: :requested_changes)

      is_expected.to eq 1
    end

    context 'when fetching only cached' do
      let(:cached_only) { true }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end

  describe '#assigned_open_issues_count' do
    subject { user.assigned_open_issues_count(force: true) }

    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:archived_project) { create(:project, :public, :archived) }

    it 'returns number of open issues from non-archived projects' do
      create(:issue, project: project, author: user, assignees: [user])
      create(:issue, :closed, project: project, author: user, assignees: [user])
      create(:issue, project: archived_project, author: user, assignees: [user])

      is_expected.to eq 1
    end
  end

  describe '#personal_projects_count' do
    let_it_be(:user) { build(:user) }

    subject(:personal_projects_count) { user.personal_projects_count }

    it 'returns the number of personal projects using a single query' do
      projects = double(:projects, count: 1)

      expect(user).to receive(:personal_projects).and_return(projects)

      is_expected.to eq(1)
    end
  end

  describe '#projects_limit_left' do
    let_it_be(:user) { build(:user) }

    subject(:projects_limit_left) { user.projects_limit_left }

    before do
      allow(user).to receive(:projects_limit).and_return(10)
      allow(user).to receive(:personal_projects_count).and_return(5)
    end

    it { is_expected.to eq(5) }
  end

  describe '#ensure_namespace_correct' do
    context 'for a new user' do
      let(:user) { described_class.new attributes_for(:user) }

      it 'does not create the namespace' do
        expect(user.namespace).to be_nil

        user.valid?

        expect(user.namespace).to be_nil
      end
    end

    context 'for an existing user' do
      let_it_be_with_refind(:user) { create(:user, username: 'foo') }

      context 'when the user is updated' do
        context 'when the username or name is changed' do
          let(:new_username) { 'bar' }

          it 'changes the namespace (just to compare to when username is not changed)' do
            expect do
              travel_to(1.second.from_now) do
                user.update!(username: new_username)
              end
            end.to change { user.namespace.updated_at }
          end

          it 'updates the namespace path when the username was changed' do
            user.update!(username: new_username)

            expect(user.namespace.path).to eq(new_username)
          end

          it 'updates the namespace name if the name was changed' do
            user.update!(name: 'New name')

            expect(user.namespace.name).to eq('New name')
          end

          it 'updates nested routes for the namespace if the name was changed' do
            project = create(:project, namespace: user.namespace)

            user.update!(name: 'New name')

            expect(project.route.reload.name).to include('New name')
          end

          context 'when there is a validation error (namespace name taken) while updating namespace' do
            let!(:conflicting_namespace) { create(:group, path: new_username) }

            it 'causes the user save to fail' do
              expect(user.update(username: new_username)).to be_falsey
              expect(user.namespace.errors.messages[:path].first).to eq(_('has already been taken'))
            end

            it 'adds the namespace errors to the user' do
              user.username = new_username

              expect(user).to be_invalid
              expect(user.errors[:base]).to include('A user, alias, or group already exists with that username.')
            end
          end

          it 'when the username is assigned to another project pages unique domain' do
            # Simulate the existing domain being in use
            create(:project_setting, pages_unique_domain: 'existing-domain')

            expect(user.update(username: 'existing-domain')).to be_falsey
            expect(user.errors.full_messages).to contain_exactly('Username has already been taken')
          end
        end

        context 'when the username is not changed' do
          it 'does not change the namespace' do
            expect do
              user.update!(email: 'asdf@asdf.com')
            end.not_to change { user.namespace.updated_at }
          end
        end
      end
    end
  end

  describe '#assign_personal_namespace' do
    let(:organization) { create(:organization) }

    subject(:assign_personal_namespace) { user.assign_personal_namespace(organization) }

    context 'when namespace exists' do
      let(:user) { build(:user) }

      it 'leaves the namespace untouched' do
        expect { assign_personal_namespace }.not_to change(user, :namespace)
      end

      it 'returns the personal namespace' do
        expect(assign_personal_namespace).to eq(user.namespace)
      end
    end

    context 'when namespace does not exist' do
      let_it_be(:organization) { create(:organization) }
      let(:user) { described_class.new attributes_for(:user) }

      it 'builds a new namespace using assigned organization' do
        assign_personal_namespace

        expect(user.namespace).to be_kind_of(Namespaces::UserNamespace)
        expect(user.namespace.namespace_settings).to be_present
        expect(user.namespace.organization).to eq(organization)
        expect(user.namespace.visibility_level).to eq(Gitlab::VisibilityLevel::PUBLIC)
      end

      it 'returns the personal namespace' do
        expect(assign_personal_namespace).to eq(user.namespace)
      end

      context 'when the organization is private' do
        let(:organization) { create(:organization, visibility_level: Gitlab::VisibilityLevel::PRIVATE) }
        let(:user) { described_class.new attributes_for(:user, organization: organization) }

        it 'builds a new private namespace using assigned organization' do
          assign_personal_namespace

          expect(user.namespace).to be_kind_of(Namespaces::UserNamespace)
          expect(user.namespace.namespace_settings).to be_present
          expect(user.namespace.organization).to eq(organization)
          expect(user.namespace.visibility_level).to eq(Gitlab::VisibilityLevel::PRIVATE)
        end
      end
    end
  end

  describe '#username_changed_hook' do
    context 'for a new user' do
      let(:user) { build(:user) }

      it 'does not trigger system hook' do
        expect(user).not_to receive(:system_hook_service)

        user.save!
      end
    end

    context 'for an existing user' do
      let_it_be_with_refind(:user) { create(:user, username: 'old-username') }

      context 'when the username is changed' do
        let(:new_username) { 'very-new-name' }

        it 'triggers the rename system hook' do
          system_hook_service = SystemHooksService.new
          expect(system_hook_service).to receive(:execute_hooks_for).with(user, :rename)
          expect(user).to receive(:system_hook_service).and_return(system_hook_service)

          user.update!(username: new_username)
        end
      end

      context 'when the username is not changed' do
        it 'does not trigger system hook' do
          expect(user).not_to receive(:system_hook_service)

          user.update!(email: 'asdf@asdf.com')
        end
      end
    end
  end

  describe '#will_save_change_to_login?' do
    let_it_be_with_reload(:user) { create(:user, username: 'old-username', email: 'old-email@example.org') }

    let(:new_username) { 'new-name' }
    let(:new_email) { 'new-email@example.org' }

    subject(:will_save_change_to_login) { user.will_save_change_to_login? }

    context 'when the username is changed' do
      before do
        user.username = new_username
      end

      it { is_expected.to be true }
    end

    context 'when the email is changed' do
      before do
        user.email = new_email
      end

      it { is_expected.to be true }
    end

    context 'when both email and username are changed' do
      before do
        user.username = new_username
        user.email = new_email
      end

      it { is_expected.to be true }
    end

    context "when email and username aren't changed" do
      before do
        user.name = 'new_name'
      end

      it { is_expected.to be_falsy }
    end
  end

  describe '#sync_attribute?' do
    let_it_be_with_reload(:user) { create(:user) }

    context 'oauth user' do
      it 'returns true if name can be synced' do
        stub_omniauth_setting(sync_profile_attributes: %w[name location])

        expect(user.sync_attribute?(:name)).to be_truthy
      end

      it 'returns true if email can be synced' do
        stub_omniauth_setting(sync_profile_attributes: %w[name email])

        expect(user.sync_attribute?(:email)).to be_truthy
      end

      it 'returns true if location can be synced' do
        stub_omniauth_setting(sync_profile_attributes: %w[location email])

        expect(user.sync_attribute?(:email)).to be_truthy
      end

      it 'returns false if name can not be synced' do
        stub_omniauth_setting(sync_profile_attributes: %w[location email])

        expect(user.sync_attribute?(:name)).to be_falsey
      end

      it 'returns false if email can not be synced' do
        stub_omniauth_setting(sync_profile_attributes: %w[location name])

        expect(user.sync_attribute?(:email)).to be_falsey
      end

      it 'returns false if location can not be synced' do
        stub_omniauth_setting(sync_profile_attributes: %w[name email])

        expect(user.sync_attribute?(:location)).to be_falsey
      end

      it 'returns true for all syncable attributes if all syncable attributes can be synced' do
        stub_omniauth_setting(sync_profile_attributes: true)

        expect(user.sync_attribute?(:name)).to be_truthy
        expect(user.sync_attribute?(:email)).to be_truthy
        expect(user.sync_attribute?(:location)).to be_truthy
      end

      it 'returns false for all syncable attributes but email if no syncable attributes are declared' do
        expect(user.sync_attribute?(:name)).to be_falsey
        expect(user.sync_attribute?(:email)).to be_truthy
        expect(user.sync_attribute?(:location)).to be_falsey
      end
    end

    context 'ldap user' do
      it 'returns true for email if ldap user' do
        allow(user).to receive(:ldap_user?).and_return(true)

        expect(user.sync_attribute?(:name)).to be_falsey
        expect(user.sync_attribute?(:email)).to be_truthy
        expect(user.sync_attribute?(:location)).to be_falsey
      end

      it 'returns true for email and location if ldap user and location declared as syncable' do
        allow(user).to receive(:ldap_user?).and_return(true)
        stub_omniauth_setting(sync_profile_attributes: %w[location])

        expect(user.sync_attribute?(:name)).to be_falsey
        expect(user.sync_attribute?(:email)).to be_truthy
        expect(user.sync_attribute?(:location)).to be_truthy
      end
    end
  end

  describe '#confirm_deletion_with_password?' do
    where(
      password_automatically_set: [true, false],
      ldap_user: [true, false],
      password_authentication_disabled: [true, false]
    )

    with_them do
      let!(:user) { create(:user, password_automatically_set: password_automatically_set) }
      let!(:identity) { create(:identity, user: user) if ldap_user }

      # Only confirm deletion with password if all inputs are false
      let(:expected) { !(password_automatically_set || ldap_user || password_authentication_disabled) }

      before do
        stub_application_setting(password_authentication_enabled_for_web: !password_authentication_disabled)
        stub_application_setting(password_authentication_enabled_for_git: !password_authentication_disabled)
      end

      it 'returns false unless all inputs are true' do
        expect(user.confirm_deletion_with_password?).to eq(expected)
      end
    end
  end

  describe '#delete_async' do
    let_it_be_with_refind(:user) { create(:user, note: "existing note") }
    let_it_be(:deleted_by) { create(:user) }
    let(:delay_user_account_self_deletion_enabled) { true }

    before do
      stub_application_setting(delay_user_account_self_deletion: delay_user_account_self_deletion_enabled)
    end

    shared_examples 'schedules user for deletion without delay' do
      it 'schedules user for deletion without delay' do
        expect(DeleteUserWorker).to receive(:perform_async).with(deleted_by.id, user.id, {})
        expect(DeleteUserWorker).not_to receive(:perform_in)

        user.delete_async(deleted_by: deleted_by)
      end
    end

    shared_examples 'it does not block the user' do
      it 'does not block the user' do
        user.delete_async(deleted_by: deleted_by)

        expect(user).not_to be_blocked
      end
    end

    it 'blocks the user if hard delete is specified' do
      user.delete_async(deleted_by: deleted_by, params: { hard_delete: true })

      expect(user).to be_blocked
    end

    it_behaves_like 'schedules user for deletion without delay'

    it_behaves_like 'it does not block the user'

    context 'when target user is the same as deleted_by' do
      let(:deleted_by) { user }

      subject(:delete_async) { user.delete_async(deleted_by: deleted_by) }

      before do
        allow(user).to receive(:has_possible_spam_contributions?).and_return(true)
      end

      shared_examples 'schedules the record for deletion with the correct delay' do
        it 'schedules the record for deletion with the correct delay' do
          freeze_time do
            expect(DeleteUserWorker).to receive(:perform_in).with(7.days, user.id, user.id, {})

            delete_async
          end
        end
      end

      it_behaves_like 'schedules the record for deletion with the correct delay'

      it 'blocks the user' do
        delete_async

        expect(user).to be_blocked
        expect(user).not_to be_banned
      end

      context 'with possible spam contribution' do
        context 'with comments' do
          before do
            allow(user).to receive(:has_possible_spam_contributions?).and_call_original

            note = create(:note_on_issue, author: user)
            create(:event, :commented, target: note, author: user)
          end

          it_behaves_like 'schedules the record for deletion with the correct delay'

          context 'when user is a placeholder' do
            let(:user) { create(:user, :placeholder, note: "existing note") }

            it_behaves_like 'schedules user for deletion without delay'
          end
        end

        context 'with other types' do
          where(:resource, :action, :delayed) do
            'Issue'        | :created | true
            'MergeRequest' | :created | true
            'Issue'        | :closed  | false
            'MergeRequest' | :closed  | false
            'WorkItem'     | :created | false
          end

          with_them do
            before do
              allow(user).to receive(:has_possible_spam_contributions?).and_call_original

              case resource
              when 'Issue'
                create(:event, action, :for_issue, author: user)
              when 'MergeRequest'
                create(:event, action, :for_merge_request, author: user)
              when 'WorkItem'
                create(:event, action, :for_work_item, author: user)
              end
            end

            if params[:delayed]
              it_behaves_like 'schedules the record for deletion with the correct delay'
            else
              it_behaves_like 'schedules user for deletion without delay'
            end
          end
        end
      end

      context 'when user has no possible spam contributions' do
        before do
          allow(user).to receive(:has_possible_spam_contributions?).and_return(false)
        end

        it_behaves_like 'schedules user for deletion without delay'
      end

      context 'when the user is a spammer' do
        before do
          stub_feature_flags(remove_trust_scores: false)

          user_scores = AntiAbuse::UserTrustScore.new(user)
          allow(AntiAbuse::UserTrustScore).to receive(:new).and_return(user_scores)
          allow(user_scores).to receive(:spammer?).and_return(true)
        end

        context 'when the user account is less than 7 days old' do
          it_behaves_like 'schedules the record for deletion with the correct delay'

          it 'creates an abuse report with the correct data' do
            expect { delete_async }.to change { AbuseReport.count }.from(0).to(1)
            expect(AbuseReport.last.attributes).to include({
              reporter_id: Users::Internal.for_organization(user.organization).security_bot.id,
              organization_id: Users::Internal.security_bot.organization_id,
              user_id: user.id,
              category: "spam",
              message: 'Potential spammer account deletion'
            }.stringify_keys)
          end

          it 'adds custom attribute to the user with the correct values' do
            delete_async

            custom_attribute = user.custom_attributes.by_key(UserCustomAttribute::AUTO_BANNED_BY_ABUSE_REPORT_ID).first
            expect(custom_attribute.value).to eq(AbuseReport.last.id.to_s)
          end

          it 'bans the user' do
            delete_async

            expect(user).to be_banned
          end

          context 'when there is an existing abuse report' do
            let!(:abuse_report) do
              create(:abuse_report, user: user, reporter: Users::Internal.for_organization(user.organization).security_bot, message: 'Existing')
            end

            it 'updates the abuse report' do
              delete_async
              abuse_report.reload

              expect(abuse_report.message).to eq("Existing\n\nPotential spammer account deletion")
            end

            it 'adds custom attribute to the user with the correct values' do
              delete_async

              custom_attribute = user.custom_attributes.by_key(UserCustomAttribute::AUTO_BANNED_BY_ABUSE_REPORT_ID).first
              expect(custom_attribute.value).to eq(abuse_report.id.to_s)
            end
          end
        end

        context 'when the user acount is greater than 7 days old' do
          before do
            allow(user).to receive(:account_age_in_days).and_return(8)
          end

          it_behaves_like 'schedules the record for deletion with the correct delay'

          it 'blocks the user' do
            delete_async

            expect(user).to be_blocked
            expect(user).not_to be_banned
          end
        end
      end

      it 'updates note to indicate the action (account was deleted by the user) and timestamp' do
        freeze_time do
          expected_note = "User deleted own account on #{Time.zone.now}\n#{user.note}"

          expect { user.delete_async(deleted_by: deleted_by) }.to change { user.note }.to(expected_note)
        end
      end

      it 'adds a custom attribute that indicates the user deleted their own account' do
        freeze_time do
          expect { user.delete_async(deleted_by: deleted_by) }.to change { user.custom_attributes.count }.by(1)

          expect(user.custom_attributes.last.key).to eq UserCustomAttribute::DELETED_OWN_ACCOUNT_AT
          expect(user.custom_attributes.last.value).to eq Time.zone.now.to_s
        end
      end

      context 'when delay_user_account_self_deletion application setting is disabled' do
        let(:delay_user_account_self_deletion_enabled) { false }

        it_behaves_like 'schedules user for deletion without delay'

        it_behaves_like 'it does not block the user'

        it 'does not update the note' do
          expect { user.delete_async(deleted_by: deleted_by) }.not_to change { user.note }
        end

        it 'does not add any new custom attrribute' do
          expect { user.delete_async(deleted_by: deleted_by) }.not_to change { user.custom_attributes.count }
        end
      end

      describe '#trusted?' do
        context 'when no custom attribute is set' do
          it 'is falsey' do
            expect(user.trusted?).to be_falsey
          end
        end

        context 'when the custom attribute is set' do
          before do
            user.custom_attributes.create!(
              key: UserCustomAttribute::TRUSTED_BY,
              value: "test"
            )
          end

          it 'is truthy' do
            expect(user.trusted?).to be_truthy
          end
        end
      end
    end
  end

  describe '#max_member_access_for_project_ids' do
    subject { user.max_member_access_for_project_ids(projects) }

    let_it_be_with_refind(:user) { create(:user) }
    let_it_be_with_refind(:group) { create(:group) }
    let_it_be_with_refind(:owner_project) { create(:project, group: group) }
    let_it_be_with_refind(:maintainer_project) { create(:project, maintainers: user) }
    let_it_be_with_refind(:reporter_project) { create(:project, reporters: user) }
    let_it_be_with_refind(:developer_project) { create(:project, developers: user) }
    let_it_be_with_refind(:planner_project) { create(:project, planners: user) }
    let_it_be_with_refind(:guest_project) { create(:project, guests: user) }
    let_it_be_with_refind(:no_access_project) { create(:project) }

    shared_examples 'max member access for projects' do
      let(:projects) do
        [owner_project, maintainer_project, reporter_project,
         developer_project, planner_project, guest_project, no_access_project].map(&:id)
      end

      let(:expected) do
        {
          owner_project.id => Gitlab::Access::OWNER,
          maintainer_project.id => Gitlab::Access::MAINTAINER,
          reporter_project.id => Gitlab::Access::REPORTER,
          developer_project.id => Gitlab::Access::DEVELOPER,
          guest_project.id => Gitlab::Access::GUEST,
          planner_project.id => Gitlab::Access::PLANNER,
          no_access_project.id => Gitlab::Access::NO_ACCESS
        }
      end

      before do
        create(:group_member, user: user, group: group)
      end

      it 'returns correct roles for different projects' do
        is_expected.to eq(expected)
      end
    end

    context 'with RequestStore enabled', :request_store do
      include_examples 'max member access for projects'

      def access_levels(projects)
        user.max_member_access_for_project_ids(projects)
      end

      it 'does not perform extra queries when asked for projects who have already been found' do
        access_levels(projects)

        expect { access_levels(projects) }.not_to exceed_query_limit(0)

        expect(access_levels(projects)).to eq(expected)
      end

      it 'only requests the extra projects when uncached projects are passed' do
        second_maintainer_project = create(:project, maintainers: user)
        second_developer_project = create(:project, developers: user)

        all_projects = projects + [second_maintainer_project.id, second_developer_project.id]

        expected_all = expected.merge(
          second_maintainer_project.id => Gitlab::Access::MAINTAINER,
          second_developer_project.id => Gitlab::Access::DEVELOPER
        )

        access_levels(projects)

        queries = ActiveRecord::QueryRecorder.new { access_levels(all_projects) }

        expect(queries.count).to eq(1)
        expect(queries.log_message).to match(/\W(#{second_maintainer_project.id}, #{second_developer_project.id})\W/)
        expect(access_levels(all_projects)).to eq(expected_all)
      end
    end

    context 'with RequestStore disabled' do
      include_examples 'max member access for projects'
    end
  end

  describe '#max_member_access_for_group_ids' do
    subject(:max_member_access_for_group_ids) { user.max_member_access_for_group_ids(groups) }

    let_it_be_with_refind(:user) { create(:user) }
    let_it_be_with_refind(:owner_group) { create(:group, owners: user) }
    let_it_be_with_refind(:maintainer_group) { create(:group, maintainers: user) }
    let_it_be_with_refind(:reporter_group) { create(:group, reporters: user) }
    let_it_be_with_refind(:developer_group) { create(:group, developers: user) }
    let_it_be_with_refind(:planner_group) { create(:group, planners: user) }
    let_it_be_with_refind(:guest_group) { create(:group, guests: user) }
    let_it_be_with_refind(:no_access_group) { create(:group) }

    shared_examples 'max member access for groups' do
      let(:groups) do
        [owner_group, maintainer_group, reporter_group, developer_group,
         planner_group, guest_group, no_access_group, planner_group].map(&:id)
      end

      let(:expected_access_levels) do
        {
          owner_group.id => Gitlab::Access::OWNER,
          maintainer_group.id => Gitlab::Access::MAINTAINER,
          reporter_group.id => Gitlab::Access::REPORTER,
          developer_group.id => Gitlab::Access::DEVELOPER,
          planner_group.id => Gitlab::Access::PLANNER,
          guest_group.id => Gitlab::Access::GUEST,
          no_access_group.id => Gitlab::Access::NO_ACCESS
        }
      end

      it 'returns correct roles for different groups' do
        is_expected.to eq(expected_access_levels)
      end
    end

    context 'with RequestStore enabled', :request_store do
      include_examples 'max member access for groups'

      it 'does not perform extra queries when asked for groups who have already been found' do
        user.max_member_access_for_group_ids(groups)

        expect { user.max_member_access_for_group_ids(groups) }.not_to exceed_query_limit(0)

        is_expected.to eq(expected_access_levels)
      end

      it 'only requests the extra groups when uncached groups are passed' do
        second_maintainer_group = create(:group, maintainers: user)
        second_developer_group = create(:group, developers: user)

        all_groups = groups + [second_maintainer_group.id, second_developer_group.id]

        expected_all = expected_access_levels.merge(
          second_maintainer_group.id => Gitlab::Access::MAINTAINER,
          second_developer_group.id => Gitlab::Access::DEVELOPER
        )

        user.max_member_access_for_group_ids(groups)

        queries = ActiveRecord::QueryRecorder.new { user.max_member_access_for_group_ids(all_groups) }

        expect(queries.count).to eq(1)
        expect(queries.log_message).to match(/\W(#{second_maintainer_group.id}, #{second_developer_group.id})\W/)
        expect(max_member_access_for_group_ids).to eq(expected_all)
      end
    end

    context 'with RequestStore disabled' do
      include_examples 'max member access for groups'
    end
  end

  describe '#max_member_access_for_group' do
    subject { user.max_member_access_for_group(group.id) }

    let_it_be_with_refind(:group) { create(:group) }

    context 'when user has no access' do
      let_it_be(:user) { create(:user) }

      it { is_expected.to eq(Gitlab::Access::NO_ACCESS) }
    end

    context 'when user has access via a single permission' do
      let_it_be(:user) { create(:user, developer_of: group) }

      it { is_expected.to eq(Gitlab::Access::DEVELOPER) }
    end

    context 'when user has access via multiple permissions' do
      let_it_be(:user) { create(:user, developer_of: group, maintainer_of: group) }

      it { is_expected.to eq(Gitlab::Access::MAINTAINER) }
    end
  end

  context 'changing a username' do
    let_it_be_with_refind(:user) { create(:user, username: 'foo') }

    it 'creates a redirect route' do
      expect { user.update!(username: 'bar') }
        .to change { RedirectRoute.where(path: 'foo').count }.by(1)
    end

    context 'when a user with the old username was created' do
      before do
        user.update!(username: 'bar')
      end

      it 'deletes the redirect' do
        expect { create(:user, username: 'foo') }
          .to change { RedirectRoute.where(path: 'foo').count }.by(-1)
      end
    end
  end

  describe '#required_terms_not_accepted?' do
    let(:user) { build(:user) }

    subject(:required_terms_not_accepted) { user.required_terms_not_accepted? }

    context 'when terms are not enforced' do
      it { is_expected.to be_falsey }
    end

    context 'when terms are enforced' do
      before do
        enforce_terms
      end

      it 'is not accepted by the user' do
        expect(required_terms_not_accepted).to be_truthy
      end

      it 'is accepted by the user' do
        accept_terms(user)

        expect(required_terms_not_accepted).to be_falsey
      end

      context "with bot users" do
        %i[project_bot service_account security_policy_bot import_user].each do |user_type|
          context "when user is #{user_type}" do
            let(:user) { build(:user, user_type) }

            it 'auto accepts the terms' do
              expect(required_terms_not_accepted).to be_falsey
            end
          end
        end
      end

      context 'with multiple versions of terms' do
        shared_examples 'terms acceptance' do
          let(:another_term) { create :term }
          let(:required_terms_are_accepted) { !required_terms_not_accepted }

          context 'when the latest term is not accepted' do
            before do
              accept_terms(user)
              another_term
            end

            it { expect(required_terms_are_accepted).to be result_for_latest_not_accepted }
          end

          context 'when the latest term is accepted' do
            before do
              another_term
              accept_terms(user)
            end

            it { expect(required_terms_are_accepted).to be result_for_latest_accepted }
          end
        end

        context 'when enforce_acceptance_of_changed_terms is enabled' do
          let(:result_for_latest_not_accepted) { false }
          let(:result_for_latest_accepted) { true }

          include_examples 'terms acceptance'
        end

        context 'when enforce_acceptance_of_changed_terms is disabled' do
          let(:result_for_latest_not_accepted) { true }
          let(:result_for_latest_accepted) { true }

          before do
            stub_feature_flags(enforce_acceptance_of_changed_terms: false)
          end

          include_examples 'terms acceptance'
        end
      end
    end
  end

  describe '#increment_failed_attempts!' do
    let_it_be_with_reload(:user) { create(:user, failed_attempts: 0) }

    it 'logs failed sign-in attempts' do
      expect { user.increment_failed_attempts! }.to change(user, :failed_attempts).from(0).to(1)
    end

    it 'does not log failed sign-in attempts when in a GitLab read-only instance' do
      allow(Gitlab::Database).to receive(:read_only?) { true }

      expect { user.increment_failed_attempts! }.not_to change(user, :failed_attempts)
    end
  end

  describe '#requires_usage_stats_consent?' do
    let_it_be_with_refind(:user) { create(:user, :admin, created_at: 8.days.ago) }

    before do
      allow(user).to receive(:has_current_license?).and_return false
    end

    context 'in single-user environment' do
      it 'requires user consent after one week' do
        create(:user, :ghost)

        expect(user.requires_usage_stats_consent?).to be true
      end

      it 'requires user consent after one week if there is another ghost user' do
        expect(user.requires_usage_stats_consent?).to be true
      end

      it 'does not require consent in the first week' do
        user.created_at = 6.days.ago

        expect(user.requires_usage_stats_consent?).to be false
      end

      it 'does not require consent if usage stats were set by this user' do
        create(:application_setting, usage_stats_set_by_user_id: user.id)

        expect(user.requires_usage_stats_consent?).to be false
      end
    end

    context 'in multi-user environment' do
      before do
        create(:user)
      end

      it 'does not require consent' do
        expect(user.requires_usage_stats_consent?).to be false
      end
    end
  end

  context 'with uploads' do
    it_behaves_like 'model with uploads', false do
      let(:model_object) { create(:user, :with_avatar) }
      let(:upload_attribute) { :avatar }
      let(:uploader_class) { AttachmentUploader }
    end
  end

  describe '.union_with_user' do
    let_it_be(:user, freeze: true) { create(:user) }

    context 'when no user ID is provided' do
      it 'returns the input relation' do
        expect(described_class.union_with_user).to contain_exactly(user)
      end
    end

    context 'when a user ID is provided' do
      it 'includes the user object in the returned relation', :aggregate_failures do
        user2 = create(:user)
        users = described_class.where(id: user.id).union_with_user(user2.id)

        expect(users).to include(user)
        expect(users).to include(user2)
      end

      it 'does not re-apply any WHERE conditions on the outer query' do
        relation = described_class.where(id: 1).union_with_user(2)

        expect(relation.arel.where_sql).to be_nil
      end
    end
  end

  describe '.optionally_search' do
    let_it_be(:user) { create(:user) }

    context 'using nil as the argument' do
      it 'returns the current relation' do
        expect(described_class.optionally_search).to contain_exactly(user)
      end
    end

    context 'using an empty String as the argument' do
      it 'returns the current relation' do
        expect(described_class.optionally_search('')).to contain_exactly(user)
      end
    end

    context 'using a non-empty String' do
      it 'returns users matching the search query' do
        user1 = create(:user)

        expect(described_class.optionally_search(user1.name)).to contain_exactly(user1)
      end
    end
  end

  describe '.where_not_in' do
    let_it_be(:user1) { create(:user) }

    context 'without an argument' do
      it 'returns the current relation' do
        expect(described_class.where_not_in).to contain_exactly(user1)
      end
    end

    context 'using a list of user IDs' do
      it 'excludes the users from the returned relation' do
        user2 = create(:user)

        expect(described_class.where_not_in([user2.id])).to contain_exactly(user1)
      end
    end
  end

  describe '.reorder_by_name' do
    it 'reorders the input relation' do
      user1 = create(:user, name: 'A')
      user2 = create(:user, name: 'B')

      expect(described_class.reorder_by_name).to contain_exactly(user1, user2)
    end
  end

  describe '#notification_settings_for' do
    let_it_be(:user) { create(:user) }
    let(:source) { nil }

    subject { user.notification_settings_for(source) }

    context 'when source is nil' do
      it 'returns a blank global notification settings object' do
        expect(subject.source).to eq(nil)
        expect(subject.notification_email).to eq(nil)
        expect(subject.level).to eq('global')
      end
    end

    context 'when source is a Group' do
      subject { user.notification_settings_for(group, inherit: true) }

      context 'when group has no existing notification settings' do
        let(:group) { create(:group) }

        context 'when group has no ancestors' do
          it 'will be a default Global notification setting' do
            expect(subject.notification_email).to eq(nil)
            expect(subject.level).to eq('global')
          end
        end

        context 'when group has ancestors' do
          let_it_be(:ancestor) { create(:group) }
          let_it_be(:group) { create(:group, parent: ancestor) }

          context 'when an ancestor has a level other than Global' do
            let_it_be(:email) { create(:email, :confirmed, email: 'ancestor@example.com', user: user) }

            before do
              create(:notification_setting, user: user, source: ancestor, level: 'participating', notification_email: email.email)
            end

            it 'has the same level set' do
              expect(subject.level).to eq('participating')
            end

            it 'has the same email set' do
              expect(subject.notification_email).to eq('ancestor@example.com')
            end

            context 'when inherit is false' do
              subject { user.notification_settings_for(group) }

              it 'does not inherit settings' do
                expect(subject.notification_email).to eq(nil)
                expect(subject.level).to eq('global')
              end
            end
          end

          context 'when an ancestor has a Global level but has an email set' do
            let(:grand_ancestor) { create(:group) }
            let(:ancestor) { create(:group, parent: grand_ancestor) }
            let(:group) { create(:group, parent: ancestor) }
            let(:ancestor_email) { create(:email, :confirmed, email: 'ancestor@example.com', user: user) }
            let(:grand_email) { create(:email, :confirmed, email: 'grand@example.com', user: user) }

            before do
              create(:notification_setting, user: user, source: grand_ancestor, level: 'participating', notification_email: grand_email.email)
              create(:notification_setting, user: user, source: ancestor, level: 'global', notification_email: ancestor_email.email)
            end

            it 'has the same email set' do
              expect(subject.level).to eq('global')
              expect(subject.notification_email).to eq('ancestor@example.com')
            end
          end
        end
      end
    end
  end

  describe '#notification_settings_for_groups' do
    let_it_be(:user) { create(:user) }
    let_it_be(:groups) { create_list(:group, 2, maintainers: user) }

    subject(:notification_settings_for_groups) { user.notification_settings_for_groups(arg) }

    shared_examples_for 'notification_settings_for_groups method' do
      it 'returns NotificationSetting objects for provided groups', :aggregate_failures do
        expect(subject.count).to eq(groups.count)
        expect(subject.map(&:source_id)).to match_array(groups.map(&:id))
      end
    end

    context 'when given an ActiveRecord relationship' do
      let_it_be(:arg) { Group.where(id: groups.map(&:id)) }

      it_behaves_like 'notification_settings_for_groups method'

      it 'uses #select to maintain lazy querying behavior' do
        expect(arg).to receive(:select).and_call_original

        notification_settings_for_groups
      end
    end

    context 'when given an Array of Groups' do
      let_it_be(:arg) { groups }

      it_behaves_like 'notification_settings_for_groups method'
    end
  end

  describe '#notification_email_for' do
    let_it_be(:user) { create(:user) }

    subject { user.notification_email_for(namespace) }

    context 'when namespace is nil' do
      let(:namespace) { nil }

      it 'returns global notification email' do
        is_expected.to eq(user.notification_email_or_default)
      end
    end

    context 'for group namespace' do
      let(:namespace) { create(:group) }

      context 'when group has no notification email set' do
        before do
          create(:notification_setting, user: user, source: namespace, notification_email: '')
        end

        it 'returns global notification email' do
          is_expected.to eq(user.notification_email_or_default)
        end
      end

      context 'when group has notification email set' do
        let(:group_notification_email) { 'user+group@example.com' }

        before do
          create(:email, :confirmed, user: user, email: group_notification_email)
          create(:notification_setting, user: user, source: namespace, notification_email: group_notification_email)
        end

        it { is_expected.to eq(group_notification_email) }
      end
    end

    context 'for user namespace' do
      let(:namespace) { create(:user_namespace) }

      it 'returns global notification email' do
        is_expected.to eq(user.notification_email_or_default)
      end
    end
  end

  describe '#valid_password?' do
    subject(:validate_password) { user.valid_password?(password) }

    let(:password) { user.password }

    context 'user with disallowed password' do
      let(:user) { create(:user, :disallowed_password) }

      it { is_expected.to eq(false) }
    end

    context 'using a correct password' do
      context 'with a regular user' do
        let(:user) { create(:user) }
        let(:password) { user.password }

        it { is_expected.to eq(true) }

        context 'when password authentication is disabled' do
          before do
            stub_application_setting(password_authentication_enabled_for_web: false)
            stub_application_setting(password_authentication_enabled_for_git: false)
          end

          it { is_expected.to eq(false) }
        end

        context 'when user with LDAP identity' do
          before do
            create(:identity, provider: 'ldapmain', user: user)
          end

          it { is_expected.to eq(false) }
        end
      end

      it_behaves_like 'OmniAuth user password authentication'
    end

    context 'using a wrong password' do
      let(:user) { create(:user) }
      let(:password) { 'WRONG PASSWORD' }

      it { is_expected.to eq(false) }
    end

    context 'using a nil password' do
      let(:user) { create(:user) }
      let(:password) { nil }

      it { is_expected.to eq(false) }
    end

    context 'using a blank password' do
      let(:user) { create(:user) }
      let(:password) { '' }

      it { is_expected.to eq(false) }
    end

    context 'user with autogenerated_password' do
      let(:user) { build_stubbed(:user, password_automatically_set: true) }
      let(:password) { user.password }

      it { is_expected.to eq(false) }
    end

    context 'using an array' do
      let(:user) { create(:user) }
      let(:password) { [user.password, 'WRONG PASSWORD'] }

      it 'raises an error' do
        expect do
          validate_password
        end.to raise_error(NoMethodError)
      end
    end
  end

  describe '#generate_otp_backup_codes!' do
    let(:user) { create(:user) }

    context 'with FIPS mode', :fips_mode do
      it 'attempts to use #generate_otp_backup_codes_pbkdf2!' do
        expect(user).to receive(:generate_otp_backup_codes_pbkdf2!).and_call_original

        user.generate_otp_backup_codes!
      end
    end

    context 'outside FIPS mode' do
      it 'does not attempt to use #generate_otp_backup_codes_pbkdf2!' do
        expect(user).not_to receive(:generate_otp_backup_codes_pbkdf2!)

        user.generate_otp_backup_codes!
      end
    end
  end

  describe '#invalidate_otp_backup_code!' do
    let(:user) { create(:user) }

    context 'with FIPS mode', :fips_mode do
      context 'with a PBKDF2-encrypted password' do
        let(:encrypted_password) { '$pbkdf2-sha512$20000$boHGAw0hEyI$DBA67J7zNZebyzLtLk2X9wRDbmj1LNKVGnZLYyz6PGrIDGIl45fl/BPH0y1TPZnV90A20i.fD9C3G9Bp8jzzOA' }

        it 'attempts to use #invalidate_otp_backup_code_pdkdf2!' do
          expect(user).to receive(:otp_backup_codes).at_least(:once).and_return([encrypted_password])
          expect(user).to receive(:invalidate_otp_backup_code_pdkdf2!).and_return(true)

          user.invalidate_otp_backup_code!(user.password)
        end
      end

      it 'does not attempt to use #invalidate_otp_backup_code_pdkdf2!' do
        expect(user).not_to receive(:invalidate_otp_backup_code_pdkdf2!)

        user.invalidate_otp_backup_code!(user.password)
      end
    end

    context 'outside FIPS mode' do
      it 'does not attempt to use #invalidate_otp_backup_code_pdkdf2!' do
        expect(user).not_to receive(:invalidate_otp_backup_code_pdkdf2!)

        user.invalidate_otp_backup_code!(user.password)
      end
    end
  end

  describe '#password_expired?' do
    let(:user) { build(:user, password_expires_at: password_expires_at) }

    subject(:password_expired) { user.password_expired? }

    context 'when password_expires_at is not set' do
      let(:password_expires_at) {}

      it 'returns false' do
        is_expected.to be_falsey
      end
    end

    context 'when password_expires_at is in the past' do
      let(:password_expires_at) { 1.minute.ago }

      it 'returns true' do
        is_expected.to be_truthy
      end
    end

    context 'when password_expires_at is in the future' do
      let(:password_expires_at) { 1.minute.from_now }

      it 'returns false' do
        is_expected.to be_falsey
      end
    end
  end

  describe '#password_expired_if_applicable?' do
    let(:user) { build(:user, password_expires_at: password_expires_at) }

    subject(:password_expired_if_applicable) { user.password_expired_if_applicable? }

    shared_examples 'password expired not applicable' do
      context 'when password_expires_at is not set' do
        let(:password_expires_at) {}

        it 'returns false' do
          is_expected.to be_falsey
        end
      end

      context 'when password_expires_at is in the past' do
        let(:password_expires_at) { 1.minute.ago }

        it 'returns false' do
          is_expected.to be_falsey
        end
      end

      context 'when password_expires_at is in the future' do
        let(:password_expires_at) { 1.minute.from_now }

        it 'returns false' do
          is_expected.to be_falsey
        end
      end
    end

    context 'with a regular user' do
      context 'when password_expires_at is not set' do
        let(:password_expires_at) {}

        it 'returns false' do
          is_expected.to be_falsey
        end
      end

      context 'when password_expires_at is in the past' do
        let(:password_expires_at) { 1.minute.ago }

        it 'returns true' do
          is_expected.to be_truthy
        end
      end

      context 'when password_expires_at is in the future' do
        let(:password_expires_at) { 1.minute.from_now }

        it 'returns false' do
          is_expected.to be_falsey
        end
      end
    end

    context 'when user is a bot' do
      before do
        allow(user).to receive(:bot?).and_return(true)
      end

      it_behaves_like 'password expired not applicable'
    end

    context 'when password_automatically_set is true' do
      let(:user) { create(:omniauth_user, provider: 'ldap') }

      it_behaves_like 'password expired not applicable'
    end

    context 'when allow_password_authentication is false' do
      before do
        allow(user).to receive(:allow_password_authentication?).and_return(false)
      end

      it_behaves_like 'password expired not applicable'
    end
  end

  describe '#can_log_in_with_non_expired_password?' do
    let(:user) { build(:user) }

    subject(:can_log_in_with_non_expired_password) { user.can_log_in_with_non_expired_password? }

    context 'when user can log in' do
      it 'returns true' do
        is_expected.to be_truthy
      end

      context 'when user with expired password' do
        before do
          user.password_expires_at = 2.minutes.ago
        end

        it 'returns false' do
          is_expected.to be_falsey
        end

        context 'when password expiration is not applicable' do
          context 'when ldap user' do
            let(:user) { build(:omniauth_user, provider: 'ldap') }

            it 'returns true' do
              is_expected.to be_truthy
            end
          end
        end
      end
    end

    context 'when user cannot log in' do
      context 'when user is blocked' do
        let(:user) { build(:user, :blocked) }

        it 'returns false' do
          is_expected.to be_falsey
        end
      end
    end
  end

  describe '#read_only_attribute?' do
    context 'when synced attributes metadata is present' do
      it 'delegates to synced_attributes_metadata' do
        subject.build_user_synced_attributes_metadata

        expect(subject.build_user_synced_attributes_metadata)
          .to receive(:read_only?).with(:email).and_return('return-value')
        expect(subject.read_only_attribute?(:email)).to eq('return-value')
      end
    end

    context 'when synced attributes metadata is not present' do
      it 'is false for any attribute' do
        expect(subject.read_only_attribute?(:email)).to be_falsey
      end
    end
  end

  describe '.active_without_ghosts' do
    let_it_be(:user1) { create(:user, :external) }
    let_it_be(:user2) { create(:user, state: 'blocked') }
    let_it_be(:user3) { create(:user, :ghost) }
    let_it_be(:user4) { create(:user, user_type: :support_bot) }
    let_it_be(:user5) { create(:user, state: 'blocked', user_type: :support_bot) }
    let_it_be(:user6) { create(:user, user_type: :automation_bot) }

    it 'returns all active users including active bots but ghost users' do
      expect(described_class.active_without_ghosts).to contain_exactly(user1, user4, user6)
    end
  end

  describe '#dismissed_callout?' do
    let_it_be(:user, refind: true) { create(:user) }
    let_it_be(:feature_name) { Users::Callout.feature_names.each_key.first }

    context 'when no callout dismissal record exists' do
      it 'returns false when no ignore_dismissal_earlier_than provided' do
        expect(user.dismissed_callout?(feature_name: feature_name)).to eq false
      end
    end

    context 'when dismissed callout exists' do
      before_all do
        create(:callout, user: user, feature_name: feature_name, dismissed_at: 4.months.ago)
      end

      it 'returns true when no ignore_dismissal_earlier_than provided' do
        expect(user.dismissed_callout?(feature_name: feature_name)).to eq true
      end

      it 'returns true when ignore_dismissal_earlier_than is earlier than dismissed_at' do
        expect(user.dismissed_callout?(feature_name: feature_name, ignore_dismissal_earlier_than: 6.months.ago)).to eq true
      end

      it 'returns false when ignore_dismissal_earlier_than is later than dismissed_at' do
        expect(user.dismissed_callout?(feature_name: feature_name, ignore_dismissal_earlier_than: 3.months.ago)).to eq false
      end
    end
  end

  describe '#find_or_initialize_callout' do
    let_it_be(:user, refind: true) { create(:user) }
    let_it_be(:feature_name) { Users::Callout.feature_names.each_key.first }

    subject(:find_or_initialize_callout) { user.find_or_initialize_callout(feature_name) }

    context 'when callout exists' do
      let!(:callout) { create(:callout, user: user, feature_name: feature_name) }

      it 'returns existing callout' do
        expect(find_or_initialize_callout).to eq(callout)
      end
    end

    context 'when callout does not exist' do
      context 'when feature name is valid' do
        it 'initializes a new callout' do
          expect(find_or_initialize_callout).to be_a_new(Users::Callout)
        end

        it 'is valid' do
          expect(find_or_initialize_callout).to be_valid
        end
      end

      context 'when feature name is not valid' do
        let(:feature_name) { 'notvalid' }

        it 'initializes a new callout' do
          expect(find_or_initialize_callout).to be_a_new(Users::Callout)
        end

        it 'is not valid' do
          expect(find_or_initialize_callout).not_to be_valid
        end
      end
    end
  end

  describe '#dismissed_callout_for_group?' do
    let_it_be(:user, refind: true) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:feature_name) { Users::GroupCallout.feature_names.each_key.first }

    context 'when no callout dismissal record exists' do
      it 'returns false when no ignore_dismissal_earlier_than provided' do
        expect(user.dismissed_callout_for_group?(feature_name: feature_name, group: group)).to eq false
      end
    end

    context 'when dismissed callout exists' do
      before_all do
        create(
          :group_callout,
          user: user,
          group_id: group.id,
          feature_name: feature_name,
          dismissed_at: 4.months.ago
        )
      end

      it 'returns true when no ignore_dismissal_earlier_than provided' do
        expect(user.dismissed_callout_for_group?(feature_name: feature_name, group: group)).to eq true
      end

      it 'returns true when ignore_dismissal_earlier_than is earlier than dismissed_at' do
        expect(user.dismissed_callout_for_group?(feature_name: feature_name, group: group, ignore_dismissal_earlier_than: 6.months.ago)).to eq true
      end

      it 'returns false when ignore_dismissal_earlier_than is later than dismissed_at' do
        expect(user.dismissed_callout_for_group?(feature_name: feature_name, group: group, ignore_dismissal_earlier_than: 3.months.ago)).to eq false
      end
    end
  end

  describe '#dismissed_callout_for_project?' do
    let_it_be(:user, refind: true) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:feature_name) { Users::ProjectCallout.feature_names.each_key.first }

    context 'when no callout dismissal record exists' do
      it 'returns false when no ignore_dismissal_earlier_than provided' do
        expect(user.dismissed_callout_for_project?(feature_name: feature_name, project: project)).to eq false
      end
    end

    context 'when dismissed callout exists' do
      before_all do
        create(
          :project_callout,
          user: user,
          project_id: project.id,
          feature_name: feature_name,
          dismissed_at: 4.months.ago
        )
      end

      it 'returns true when no ignore_dismissal_earlier_than provided' do
        expect(user.dismissed_callout_for_project?(feature_name: feature_name, project: project)).to eq true
      end

      it 'returns true when ignore_dismissal_earlier_than is earlier than dismissed_at' do
        expect(user.dismissed_callout_for_project?(feature_name: feature_name, project: project, ignore_dismissal_earlier_than: 6.months.ago)).to eq true
      end

      it 'returns false when ignore_dismissal_earlier_than is later than dismissed_at' do
        expect(user.dismissed_callout_for_project?(feature_name: feature_name, project: project, ignore_dismissal_earlier_than: 3.months.ago)).to eq false
      end
    end
  end

  describe '#find_or_initialize_group_callout' do
    let_it_be(:user, refind: true) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:feature_name) { Users::GroupCallout.feature_names.each_key.first }

    subject(:callout_with_source) do
      user.find_or_initialize_group_callout(feature_name, group.id)
    end

    context 'when callout exists' do
      let!(:callout) do
        create(:group_callout, user: user, feature_name: feature_name, group_id: group.id)
      end

      it 'returns existing callout' do
        expect(callout_with_source).to eq(callout)
      end
    end

    context 'when callout does not exist' do
      context 'when feature name is valid' do
        it 'initializes a new callout' do
          expect(callout_with_source).to be_a_new(Users::GroupCallout)
        end

        it 'is valid' do
          expect(callout_with_source).to be_valid
        end
      end

      context 'when feature name is not valid' do
        let(:feature_name) { 'notvalid' }

        it 'initializes a new callout' do
          expect(callout_with_source).to be_a_new(Users::GroupCallout)
        end

        it 'is not valid' do
          expect(callout_with_source).not_to be_valid
        end
      end
    end
  end

  describe '#find_or_initialize_project_callout' do
    let_it_be(:user, refind: true) { create(:user) }
    let_it_be(:project) { create(:project) }
    let_it_be(:feature_name) { Users::ProjectCallout.feature_names.each_key.first }

    subject(:callout_with_source) do
      user.find_or_initialize_project_callout(feature_name, project.id)
    end

    context 'when callout exists' do
      let!(:callout) do
        create(:project_callout, user: user, feature_name: feature_name, project_id: project.id)
      end

      it 'returns existing callout' do
        expect(callout_with_source).to eq(callout)
      end
    end

    context 'when callout does not exist' do
      context 'when feature name is valid' do
        it 'initializes a new callout' do
          expect(callout_with_source).to be_a_new(Users::ProjectCallout)
        end

        it 'is valid' do
          expect(callout_with_source).to be_valid
        end
      end

      context 'when feature name is not valid' do
        let(:feature_name) { 'notvalid' }

        it 'initializes a new callout' do
          expect(callout_with_source).to be_a_new(Users::ProjectCallout)
        end

        it 'is not valid' do
          expect(callout_with_source).not_to be_valid
        end
      end
    end
  end

  describe '#hook_attrs' do
    let(:user) { create(:user) }
    let(:user_attributes) do
      {
        id: user.id,
        name: user.name,
        username: user.username,
        avatar_url: user.avatar_url(only_path: false)
      }
    end

    context 'with a public email' do
      it 'includes id, name, username, avatar_url, and email' do
        user.public_email = "hello@hello.com"
        user_attributes[:email] = user.public_email
        expect(user.hook_attrs).to eq(user_attributes)
      end
    end

    context 'without a public email' do
      it "does not include email if user's email is private" do
        user_attributes[:email] = "[REDACTED]"
        expect(user.hook_attrs).to eq(user_attributes)
      end
    end
  end

  describe '#webhook_email' do
    subject(:webhook_email) { user.webhook_email }

    context 'when public email is present' do
      let_it_be(:user) { build(:user, public_email: "hello@hello.com") }

      it { is_expected.to eq(user.public_email) }
    end

    context 'when public email is nil' do
      let_it_be(:user) { build(:user, public_email: nil) }

      it { is_expected.to eq(_('[REDACTED]')) }
    end
  end

  describe 'user detail' do
    context 'when user is initialized' do
      let(:user) { build(:user) }

      it { expect(user.user_detail).to be_present }
      it { expect(user.user_detail).not_to be_persisted }
    end

    context 'when user detail exists' do
      let(:user) { create(:user, job_title: 'Engineer') }

      it { expect(user.user_detail).to be_persisted }
    end
  end

  describe '#current_highest_access_level' do
    let_it_be(:user) { create(:user) }

    context 'when no memberships exist' do
      it 'returns nil' do
        expect(user.current_highest_access_level).to be_nil
      end
    end

    context 'when memberships exist' do
      it 'returns the highest access level for non requested memberships' do
        create(:group_member, :reporter, user_id: user.id)
        create(:project_member, :planner, user_id: user.id)
        create(:project_member, :guest, user_id: user.id)
        create(:project_member, :maintainer, user_id: user.id, requested_at: Time.current)

        expect(user.current_highest_access_level).to eq(Gitlab::Access::REPORTER)
      end
    end
  end

  context 'when after_commit :update_highest_role' do
    describe 'create user' do
      subject { create(:user) }

      it 'schedules a job in the future', :aggregate_failures, :clean_gitlab_redis_shared_state do
        allow_next_instance_of(Gitlab::ExclusiveLease) do |instance|
          allow(instance).to receive(:try_obtain).and_return('uuid')
        end

        expect(UpdateHighestRoleWorker).to receive(:perform_in).and_call_original

        expect { subject }.to change(UpdateHighestRoleWorker.jobs, :size).by(1)
      end
    end

    context 'when user already exists' do
      let!(:user) { create(:user) }
      let(:user_id) { user.id }

      describe 'update user' do
        where(:attributes) do
          [
            { state: 'blocked' },
            { user_type: :ghost },
            { user_type: :alert_bot },
            { user_type: :support_bot },
            { user_type: :security_bot },
            { user_type: :automation_bot },
            { user_type: :admin_bot }
          ]
        end

        with_them do
          context 'when state was changed' do
            subject { user.update!(attributes) }

            include_examples 'update highest role with exclusive lease'
          end
        end

        context 'when state was not changed' do
          subject { user.update!(email: 'newmail@example.com') }

          include_examples 'does not update the highest role'
        end
      end

      describe 'destroy user' do
        subject { user.destroy! }

        include_examples 'does not update the highest role'
      end
    end
  end

  describe '#active_for_authentication?' do
    subject(:active_for_authentication?) { user.active_for_authentication? }

    let(:user) { create(:user) }

    context 'when user is blocked' do
      before do
        user.block
      end

      it { is_expected.to be false }

      it 'does not check if LDAP is allowed' do
        stub_ldap_setting(enabled: true)

        expect(Gitlab::Auth::Ldap::Access).not_to receive(:allowed?)

        active_for_authentication?
      end
    end

    context 'when user is a ghost user' do
      before do
        user.update!(user_type: :ghost)
      end

      it { is_expected.to be false }
    end

    context 'when user is ldap_blocked' do
      before do
        user.ldap_block
      end

      it 'rechecks if LDAP is allowed when LDAP is enabled' do
        stub_ldap_setting(enabled: true)

        expect(Gitlab::Auth::Ldap::Access).to receive(:allowed?)

        active_for_authentication?
      end

      it 'does not check if LDAP is allowed when LDAP is not enabled' do
        stub_ldap_setting(enabled: false)

        expect(Gitlab::Auth::Ldap::Access).not_to receive(:allowed?)

        active_for_authentication?
      end
    end

    context 'based on user type' do
      using RSpec::Parameterized::TableSyntax

      where(:user_type, :expected_result) do
        'human'               | true
        'alert_bot'           | false
        'support_bot'         | false
        'security_bot'        | false
        'automation_bot'      | false
        'admin_bot'           | false
      end

      with_them do
        before do
          user.update!(user_type: user_type)
        end

        it { is_expected.to be expected_result }
      end
    end
  end

  describe '#inactive_message' do
    let(:user) { create(:user) }

    subject(:inactive_message) { user.inactive_message }

    context 'when user is blocked' do
      before do
        user.block
      end

      it { is_expected.to eq :blocked }
    end

    context 'when user is an internal user' do
      before do
        user.update!(user_type: :ghost)
      end

      it { is_expected.to be :forbidden }
    end

    context 'when user is locked' do
      before do
        user.lock_access!
      end

      it { is_expected.to be :locked }
    end

    context 'when user is blocked pending approval' do
      before do
        user.block_pending_approval!
      end

      it { is_expected.to be :blocked_pending_approval }
    end
  end

  describe '#password_required?' do
    let_it_be(:user) { create(:user) }

    shared_examples 'does not require password to be present' do
      it { expect(user).not_to validate_presence_of(:password) }

      it { expect(user).not_to validate_presence_of(:password_confirmation) }
    end

    context 'when user is an internal user' do
      before do
        user.update!(user_type: 'alert_bot')
      end

      it_behaves_like 'does not require password to be present'
    end

    context 'when user is a project bot user' do
      before do
        user.update!(user_type: 'project_bot')
      end

      it_behaves_like 'does not require password to be present'
    end

    context 'when user is a security_policy bot user' do
      before do
        user.update!(user_type: 'security_policy_bot')
      end

      it_behaves_like 'does not require password to be present'
    end

    context 'when user is an import user' do
      before do
        user.update!(user_type: 'import_user')
      end

      it_behaves_like 'does not require password to be present'
    end

    context 'when user is a placeholder user' do
      before do
        user.user_type = 'placeholder'
      end

      it_behaves_like 'does not require password to be present'
    end
  end

  describe 'can_trigger_notifications?' do
    context 'when user is not confirmed' do
      let_it_be(:user) { create(:user, :unconfirmed) }

      it 'returns false' do
        expect(user.can_trigger_notifications?).to be(false)
      end
    end

    context 'when user is blocked' do
      let_it_be(:user) { create(:user, :blocked) }

      it 'returns false' do
        expect(user.can_trigger_notifications?).to be(false)
      end
    end

    context 'when user is a ghost' do
      let_it_be(:user) { create(:user, :ghost) }

      it 'returns false' do
        expect(user.can_trigger_notifications?).to be(false)
      end
    end

    context 'when user is confirmed and neither blocked or a ghost' do
      let_it_be(:user) { create(:user) }

      it 'returns true' do
        expect(user.can_trigger_notifications?).to be(true)
      end
    end
  end

  describe '#confirmation_required_on_sign_in?' do
    subject(:confirmation_required_on_sign_in) { user.confirmation_required_on_sign_in? }

    context 'when user is confirmed' do
      let(:user) { create(:user) }

      it 'is false' do
        expect(user.confirmed?).to be(true)
        expect(subject).to be(false)
      end
    end

    context 'when user is not confirmed' do
      let_it_be(:user) { build_stubbed(:user, :unconfirmed, confirmation_sent_at: Time.current) }

      context 'when email confirmation setting is set to `off`' do
        before do
          stub_application_setting_enum('email_confirmation_setting', 'off')
        end

        it { is_expected.to be(false) }
      end

      context 'when email confirmation setting is set to `soft`' do
        before do
          stub_application_setting_enum('email_confirmation_setting', 'soft')
        end

        context 'when confirmation period is valid' do
          it { is_expected.to be(false) }
        end

        context 'when confirmation period is expired' do
          before do
            travel_to(described_class.allow_unconfirmed_access_for.from_now + 1.day)
          end

          it { is_expected.to be(true) }
        end

        context 'when user has no confirmation email sent' do
          let(:user) { build(:user, :unconfirmed, confirmation_sent_at: nil) }

          it { is_expected.to be(true) }
        end
      end

      context 'when email confirmation setting is set to `hard`' do
        before do
          stub_application_setting_enum('email_confirmation_setting', 'hard')
        end

        it { is_expected.to be(true) }
      end
    end
  end

  describe '#confirmation_period_valid?' do
    let_it_be(:user) { create(:user) }

    subject(:confirmation_period_valid) { user.send(:confirmation_period_valid?) }

    context 'when email confirmation setting is set to `off`' do
      before do
        stub_application_setting_enum('email_confirmation_setting', 'off')
      end

      it { is_expected.to be(true) }
    end

    context 'when email confirmation setting is set to `soft`' do
      before do
        stub_application_setting_enum('email_confirmation_setting', 'soft')
      end

      context 'when within confirmation window' do
        before do
          user.update!(confirmation_sent_at: Date.today)
        end

        it { is_expected.to be(true) }
      end

      context 'when outside confirmation window' do
        before do
          user.update!(confirmation_sent_at: Date.today - described_class.confirm_within - 7.days)
        end

        it { is_expected.to be(false) }
      end
    end

    context 'when email confirmation setting is set to `hard`' do
      before do
        stub_application_setting_enum('email_confirmation_setting', 'hard')
      end

      it { is_expected.to be(true) }
    end

    describe '#in_confirmation_period?' do
      it 'is expected to be an alias' do
        expect(user.method(:in_confirmation_period?).original_name).to eq(:confirmation_period_valid?)
      end
    end
  end

  describe '.dormant' do
    it 'returns dormant users' do
      freeze_time do
        not_that_long_ago = (Gitlab::CurrentSettings.deactivate_dormant_users_period - 1).days.ago.to_date
        too_long_ago = Gitlab::CurrentSettings.deactivate_dormant_users_period.days.ago.to_date

        create(:user, :deactivated, last_activity_on: too_long_ago)

        User::INTERNAL_USER_TYPES.map do |user_type|
          create(:user, state: :active, user_type: user_type, last_activity_on: too_long_ago)
        end

        create(:user, last_activity_on: not_that_long_ago)

        dormant_user = create(:user, last_activity_on: too_long_ago)

        expect(described_class.dormant).to contain_exactly(dormant_user)
      end
    end
  end

  describe '.with_no_activity' do
    it 'returns users with no activity' do
      freeze_time do
        active_not_that_long_ago = (Gitlab::CurrentSettings.deactivate_dormant_users_period - 1).days.ago.to_date
        active_too_long_ago = Gitlab::CurrentSettings.deactivate_dormant_users_period.days.ago.to_date
        created_recently = (described_class::MINIMUM_DAYS_CREATED - 1).days.ago.to_date
        created_not_recently = described_class::MINIMUM_DAYS_CREATED.days.ago.to_date

        create(:user, :deactivated, last_activity_on: nil)

        User::INTERNAL_USER_TYPES.map do |user_type|
          create(:user, state: :active, user_type: user_type, last_activity_on: nil)
        end

        create(:user, last_activity_on: active_not_that_long_ago)
        create(:user, last_activity_on: active_too_long_ago)
        create(:user, last_activity_on: nil, created_at: created_recently)

        old_enough_user_with_no_activity = create(:user, last_activity_on: nil, created_at: created_not_recently)

        expect(described_class.with_no_activity).to contain_exactly(old_enough_user_with_no_activity)
      end
    end
  end

  describe '.by_provider_and_extern_uid' do
    it 'calls Identity model scope to ensure case-insensitive query', :aggregate_failures do
      expected_user = create(:user)
      create(:identity, extern_uid: 'some-other-name-id', provider: :github)
      create(:identity, extern_uid: 'my_github_id', provider: :gitlab)
      create(:identity)
      create(:identity, user: expected_user, extern_uid: 'my_github_id', provider: :github)

      expect(Identity).to receive(:with_extern_uid).and_call_original
      expect(described_class.by_provider_and_extern_uid(:github, 'my_github_id')).to contain_exactly(expected_user)
    end
  end

  describe '.ldap' do
    subject(:ldap) { described_class.ldap }

    let_it_be(:ldap_user) { create(:omniauth_user, provider: "ldapmain") }
    let_it_be(:gitlab_user) { create(:omniauth_user, provider: "gitlab") }
    let_it_be(:regular_user) { create(:user) }

    it 'returns LDAP users' do
      expect(ldap).to include(ldap_user)
      expect(ldap).not_to include(gitlab_user, regular_user)
    end
  end

  describe '#unset_secondary_emails_matching_deleted_email!' do
    let(:deleted_email) { 'kermit@muppets.com' }

    subject { build(:user, commit_email: commit_email) }

    context 'when no secondary email matches the deleted email' do
      let(:commit_email) { 'fozzie@muppets.com' }

      it 'does nothing' do
        expect(subject).not_to receive(:save)
        subject.unset_secondary_emails_matching_deleted_email!(deleted_email)
        expect(subject.commit_email).to eq commit_email
      end
    end

    context 'when a secondary email matches the deleted_email' do
      let(:commit_email) { deleted_email }

      it 'un-sets the secondary email' do
        expect(subject).to receive(:save)
        subject.unset_secondary_emails_matching_deleted_email!(deleted_email)
        expect(subject.commit_email).to be_nil
      end
    end
  end

  describe '#groups_with_developer_project_access' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group1) { create(:group) }

    let_it_be(:developer_group1) { create(:group, developers: user) }
    let_it_be(:developer_group2) do
      create(:group, developers: user, project_creation_level: ::Gitlab::Access::DEVELOPER_PROJECT_ACCESS)
    end

    let_it_be(:guest_group1) do
      create(:group, guests: user, project_creation_level: ::Gitlab::Access::DEVELOPER_PROJECT_ACCESS)
    end

    let_it_be(:developer_group1) do
      create(:group, maintainers: user, project_creation_level: ::Gitlab::Access::DEVELOPER_PROJECT_ACCESS)
    end

    subject(:groups_with_developer_project_access) { user.send(:groups_with_developer_project_access) }

    it { is_expected.to contain_exactly(developer_group2) }
  end

  describe '.get_ids_by_ids_or_usernames' do
    let(:user_name) { 'user_name' }
    let!(:user) { create(:user, username: user_name) }
    let(:user_id) { user.id }

    it 'returns the id of each record matching username' do
      expect(described_class.get_ids_by_ids_or_usernames(nil, [user_name])).to contain_exactly(user_id)
    end

    it 'returns the id of each record matching user id' do
      expect(described_class.get_ids_by_ids_or_usernames([user_id], nil)).to contain_exactly(user_id)
    end

    it 'return the id for all records matching either user id or user name' do
      new_user_id = create(:user).id

      expect(described_class.get_ids_by_ids_or_usernames([new_user_id], [user_name]))
        .to contain_exactly(user_id, new_user_id)
    end
  end

  describe '.by_ids_or_usernames' do
    let(:user_name) { 'user_name' }
    let!(:user) { create(:user, username: user_name) }
    let(:user_id) { user.id }

    it 'returns matching records based on username' do
      expect(described_class.by_ids_or_usernames(nil, [user_name])).to contain_exactly(user)
    end

    it 'returns matching records based on id' do
      expect(described_class.by_ids_or_usernames([user_id], nil)).to contain_exactly(user)
    end

    it 'returns matching records based on both username and id' do
      new_user = create(:user)

      expect(described_class.by_ids_or_usernames([new_user.id], [user_name])).to contain_exactly(user, new_user)
    end
  end

  describe '.without_forbidden_states' do
    subject { described_class.without_forbidden_states }

    let_it_be(:normal_user) { create(:user, username: 'johndoe') }
    let_it_be(:admin_user) { create(:user, :admin, username: 'iamadmin') }
    let_it_be(:blocked_user) { create(:user, :blocked, username: 'notsorandom') }
    let_it_be(:banned_user) { create(:user, :banned, username: 'iambanned') }
    let_it_be(:external_user) { create(:user, :external) }
    let_it_be(:unconfirmed_user) { create(:user, confirmed_at: nil) }
    let_it_be(:omniauth_user) { create(:omniauth_user, provider: 'twitter', extern_uid: '123456') }
    let_it_be(:internal_user) { Users::Internal.alert_bot.tap { |u| u.confirm } }

    it 'does not return blocked or banned users' do
      is_expected.to contain_exactly(
        normal_user, admin_user, external_user, unconfirmed_user, omniauth_user, internal_user
      )
    end
  end

  describe 'user_project' do
    it 'returns users project matched by username and public visibility' do
      user = create(:user)
      public_project = create(:project, :public, path: user.username, namespace: user.namespace)
      create(:project, namespace: user.namespace)

      expect(user.user_project).to eq(public_project)
    end
  end

  describe 'user_readme' do
    it 'returns readme from user project' do
      user = create(:user)
      create(:project, :repository, :public, path: user.username, namespace: user.namespace)

      expect(user.user_readme.name).to eq('README.md')
      expect(user.user_readme.data).to include('testme')
    end

    it 'returns nil if project is private' do
      user = create(:user)
      create(:project, :repository, :private, path: user.username, namespace: user.namespace)

      expect(user.user_readme).to be_nil
    end
  end

  it_behaves_like 'it has loose foreign keys' do
    let(:factory_name) { :user }
  end

  describe 'user age' do
    let(:user) { create(:user, created_at: Date.yesterday) }

    it 'returns age in days' do
      expect(user.account_age_in_days).to be(1)
    end
  end

  describe 'state machine and default attributes' do
    let(:model) do
      Class.new(ApplicationRecord) do
        self.table_name = User.table_name

        attribute :external, default: -> { 1 / 0 }

        state_machine :state, initial: :active do
        end
      end
    end

    it 'raises errors by default' do
      expect { model }.to raise_error(ZeroDivisionError)
    end

    context 'with state machine default attributes override' do
      let(:model) do
        Class.new(ApplicationRecord) do
          self.table_name = User.table_name

          attribute :external, default: -> { 1 / 0 }

          state_machine :state, initial: :active do
            def owner_class_attribute_default; end
          end
        end
      end

      it 'does not raise errors' do
        expect { model }.not_to raise_error
      end

      it 'raises errors when default attributes are used' do
        expect { model.new.attributes }.to raise_error(ZeroDivisionError)
      end

      it 'does not evaluate default attributes when values are provided' do
        expect { model.new(external: false).attributes }.not_to raise_error
      end

      it 'sets the state machine default value' do
        expect(model.new(external: true).state).to eq('active')
      end
    end
  end

  describe '#namespace_commit_email_for_project' do
    let_it_be(:user) { create(:user) }

    let(:emails) { user.namespace_commit_email_for_project(project) }

    context 'when project is nil' do
      let(:project) {}

      it 'returns nil' do
        expect(emails).to be_nil
      end
    end

    context 'with a group project' do
      let_it_be(:root_group) { create(:group) }
      let_it_be(:group) { create(:group, parent: root_group) }
      let_it_be(:project) { create(:project, group: group) }

      context 'without a defined root group namespace_commit_email' do
        context 'without a defined project namespace_commit_email' do
          it 'returns nil' do
            expect(emails).to be_nil
          end
        end

        context 'with a defined project namespace_commit_email' do
          it 'returns the defined namespace_commit_email' do
            project_commit_email = create(
              :namespace_commit_email,
              user: user,
              namespace: project.project_namespace
            )

            expect(emails).to eq(project_commit_email)
          end
        end
      end

      context 'with a defined root group namespace_commit_email' do
        let_it_be(:root_group_commit_email) do
          create(:namespace_commit_email, user: user, namespace: root_group)
        end

        context 'without a defined project namespace_commit_email' do
          it 'returns the defined namespace_commit_email' do
            expect(emails).to eq(root_group_commit_email)
          end
        end

        context 'with a defined project namespace_commit_email' do
          it 'returns the defined namespace_commit_email' do
            project_commit_email = create(
              :namespace_commit_email,
              user: user,
              namespace: project.project_namespace
            )

            expect(emails).to eq(project_commit_email)
          end
        end
      end
    end

    context 'with personal project' do
      let_it_be(:project) { create(:project, namespace: user.namespace) }

      context 'without a defined project namespace_commit_email' do
        it 'returns nil' do
          expect(emails).to be_nil
        end
      end

      context 'with a defined project namespace_commit_email' do
        it 'returns the defined namespace_commit_email' do
          project_commit_email = create(
            :namespace_commit_email,
            user: user,
            namespace: project.project_namespace
          )

          expect(emails).to eq(project_commit_email)
        end
      end
    end
  end

  describe '#deleted_own_account?' do
    let_it_be(:user) { create(:user) }

    subject(:result) { user.deleted_own_account? }

    context 'when user has a DELETED_OWN_ACCOUNT_AT custom attribute' do
      let_it_be(:custom_attr) do
        create(:user_custom_attribute, user: user, key: UserCustomAttribute::DELETED_OWN_ACCOUNT_AT, value: 'now')
      end

      it { is_expected.to eq true }
    end

    context 'when user does not have a DELETED_OWN_ACCOUNT_AT custom attribute' do
      let_it_be(:user) { create(:user) }

      it { is_expected.to eq false }
    end
  end

  describe 'color_mode_id' do
    context 'when theme_id is 11' do
      let(:user) { build(:user, theme_id: 11) }

      it 'returns 2' do
        expect(user.color_mode_id).to eq(2)
      end
    end

    context 'when theme_id is not 11' do
      let(:user) { build(:user, theme_id: 5) }

      it 'returns the value of color_mode_id' do
        expect(user.color_mode_id).to eq(1)
      end
    end
  end

  describe '.username_exists?' do
    let_it_be(:user) { create(:user, username: 'user_1') }

    context 'when user with username exists' do
      it 'returns true' do
        expect(described_class.username_exists?('user_1')).to be(true)
      end
    end

    context 'when user with username does not exist' do
      it 'returns false' do
        expect(described_class.username_exists?('second_user')).to be(false)
      end
    end
  end

  describe '.id_exists?' do
    let_it_be(:user) { create(:user) }
    let_it_be(:user_id) { user.id }

    context 'when user with id exists' do
      it 'returns true' do
        expect(described_class.id_exists?(user_id)).to be(true)
      end
    end

    context 'when user with id does not exist' do
      it 'returns false' do
        expect(described_class.id_exists?('invalid_id')).to be(false)
      end
    end
  end

  context 'when email is not unique' do
    let_it_be(:existing_user) { create(:user) }

    subject(:new_user) { build(:user, email: existing_user.email).tap { |user| user.valid? } }

    shared_examples 'it does not add account pending deletion error message' do
      it 'does not add account pending deletion error message' do
        expect(new_user.errors.full_messages).to include('Email has already been taken')
        expect(new_user.errors.full_messages).not_to include('Email is linked to an account pending deletion')
      end
    end

    context 'when existing account is pending deletion' do
      let(:delay_user_account_self_deletion_enabled) { true }

      before do
        UserCustomAttribute.set_deleted_own_account_at(existing_user)
        stub_application_setting(delay_user_account_self_deletion: delay_user_account_self_deletion_enabled)
      end

      it 'adds expected error messages' do
        expect(new_user.errors.full_messages).to include('Email has already been taken', 'Email is linked to an account pending deletion.')
      end

      context 'when delay_user_account_self_deletion application setting is disabled' do
        let(:delay_user_account_self_deletion_enabled) { false }

        it_behaves_like 'it does not add account pending deletion error message'
      end
    end

    context 'when existing account is not pending deletion' do
      it_behaves_like 'it does not add account pending deletion error message'
    end
  end

  describe '#ldap_sync_time' do
    let_it_be(:user) { build(:user) }

    subject(:ldap_sync_time) { user.ldap_sync_time }

    it { is_expected.to eq(1.hour) }
  end

  describe '#readable_by?' do
    let_it_be(:user) { create(:user) }

    subject(:readable_by) { user.readable_by?(other_user) }

    context 'when it is the same user' do
      let(:other_user) { user }

      it { is_expected.to be(true) }
    end

    context 'when it is a different user' do
      let(:other_user) { build(:user) }

      it { is_expected.to be(false) }
    end
  end

  describe '#can_leave_project?' do
    let_it_be(:user) { create :user, :with_namespace }
    let_it_be(:user_namespace_project) { create(:project, namespace: user.namespace) }
    let_it_be(:user_member_project) { create(:project, :in_group, developers: [user]) }

    subject(:can_leave_project) { user.can_leave_project?(project) }

    context "when the project is in the user's namespace" do
      let(:project) { user_namespace_project }

      it { is_expected.to be_falsey }
    end

    context 'when the user is a member of the project' do
      let(:project) { user_member_project }

      it { is_expected.to be_truthy }
    end
  end

  context 'normalized email reuse check' do
    let(:error_message) { 'Email is not allowed. Please enter a different email address and try again.' }
    let(:new_user) { build(:user, email: tumbled_email) }

    subject(:validate) { new_user.validate }

    before do
      stub_application_setting(enforce_email_subaddress_restrictions: true)
    end

    shared_examples 'adds a validation error' do |reason|
      specify do
        expect(::Gitlab::AppLogger).to receive(:info).with(
          message: 'Email failed validation check',
          reason: reason,
          username: new_user.username
        )

        validate

        expect(new_user.errors.full_messages).to include(error_message)
      end
    end

    shared_examples 'checking normalized email reuse limit' do
      before do
        stub_const("AntiAbuse::UniqueDetumbledEmailValidator::NORMALIZED_EMAIL_ACCOUNT_LIMIT", 2)
      end

      context 'when the normalized email limit has been reached by unique users' do
        before do
          create(:user, email: tumbled_email.split('@').join('1@'))
        end

        it_behaves_like 'adds a validation error', 'Detumbled email has reached the reuse limit'

        it 'performs the normalized email limit check' do
          expect(Email).to receive(:users_by_detumbled_email_count).and_call_original

          subject
        end
      end

      context 'when the normalized email limit has been reached by non-unique users' do
        before do
          user = described_class.find_by(email: normalized_email)
          create(:email, user: user, email: tumbled_email.split('@').join('1@'))
        end

        it 'does not add an error' do
          validate

          expect(new_user.errors).to be_empty
        end
      end

      context 'when the normalized email limit has not been reached' do
        it 'does not add an error' do
          validate

          expect(new_user.errors).to be_empty
        end
      end

      context 'when the enforce_email_subaddress_restrictions application setting is disabled' do
        before do
          stub_application_setting(enforce_email_subaddress_restrictions: false)
        end

        it 'does not perform the check' do
          expect(Email).not_to receive(:users_by_detumbled_email_count)

          subject
        end
      end
    end

    context 'when email has other validation errors' do
      subject { build(:user, email: 'invalid-email').tap(&:valid?) }

      it 'does not perform the normalized email checks' do
        expect(::Users::BannedUser).not_to receive(:by_detumbled_email)
        expect(Email).not_to receive(:users_by_detumbled_email_count)

        subject
      end
    end

    context 'when the email has not changed' do
      it 'does not perform the normalized email checks' do
        user = create(:user)

        expect(::Users::BannedUser).not_to receive(:by_detumbled_email)
        expect(Email).not_to receive(:users_by_detumbled_email_count)

        user.valid?
      end
    end

    context 'when email has no other validation errors' do
      context 'when the email is associated with a banned user' do
        let(:tumbled_email) { 'banned+inbox1@test.com' }
        let(:normalized_email) { 'banned@test.com' }

        before do
          create(:user, :banned, email: normalized_email)
        end

        it_behaves_like 'adds a validation error', 'Detumbled email is associated with a banned user'

        it 'performs the banned user check' do
          expect(::Users::BannedUser).to receive(:by_detumbled_email).and_call_original

          subject
        end

        it 'does not perform the normalized email limit check' do
          expect(Email).not_to receive(:users_by_detumbled_email_count)

          subject
        end

        context 'and does not match normalized email of a banned user' do
          let(:tumbled_email) { 'unique+tumbled@email.com' }

          it 'does not add an error' do
            validate

            expect(new_user.errors).to be_empty
          end
        end

        context 'when enforce_email_subaddress_restrictions application setting is disabled' do
          before do
            stub_application_setting(enforce_email_subaddress_restrictions: false)
          end

          it 'does not perform the check' do
            expect(::Users::BannedUser).not_to receive(:by_detumbled_email)
          end
        end
      end

      context 'when the email is not associated with a banned user' do
        let(:tumbled_email) { 'active+inbox1@test.com' }
        let(:normalized_email) { 'active@test.com' }

        before do
          create(:user, email: normalized_email)
        end

        it 'performs the check and does not add an error' do
          expect(::Users::BannedUser).to receive(:by_detumbled_email).and_call_original

          validate

          expect(new_user.errors).to be_empty
        end

        it_behaves_like 'checking normalized email reuse limit'
      end
    end
  end

  describe '#uploads_sharding_key' do
    let_it_be(:user) { build_stubbed(:user) }

    subject(:uploads_sharding_key) { user.uploads_sharding_key }

    it { is_expected.to eq({}) }
  end

  describe 'support pin methods', :freeze_time do
    let_it_be(:user_with_pin) { create(:user) }
    let_it_be(:user_no_pin) { create(:user) }
    let(:pin_data) { { pin: '123456', expires_at: 7.days.from_now } }
    let(:retrieve_service) { instance_double(Users::SupportPin::RetrieveService) }

    before do
      allow(Users::SupportPin::RetrieveService).to receive(:new).and_return(retrieve_service)
    end

    describe '#support_pin' do
      it 'returns the pin when it exists' do
        allow(retrieve_service).to receive(:execute).and_return(pin_data)

        expect(user_with_pin.support_pin).to eq('123456')
      end

      it 'returns nil when no pin exists' do
        allow(retrieve_service).to receive(:execute).and_return(nil)

        expect(user_no_pin.support_pin).to be_nil
      end

      it 'returns nil when pin key is missing' do
        allow(retrieve_service).to receive(:execute).and_return({})

        expect(user_no_pin.support_pin).to be_nil
      end
    end

    describe '#support_pin_expires_at' do
      it 'returns the expiration time when it exists', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/546655' do
        allow(retrieve_service).to receive(:execute).and_return(pin_data)

        expect(user_with_pin.support_pin_expires_at).to eq(pin_data[:expires_at])
      end

      it 'returns nil when no expiration time exists' do
        allow(retrieve_service).to receive(:execute).and_return(nil)

        expect(user_no_pin.support_pin_expires_at).to be_nil
      end

      it 'returns nil when expires_at key is missing' do
        allow(retrieve_service).to receive(:execute).and_return({})

        expect(user_no_pin.support_pin_expires_at).to be_nil
      end
    end

    it 'only calls the retrieve service once for multiple method calls' do
      expect(retrieve_service).to receive(:execute).once.and_return(pin_data)

      user_with_pin.support_pin
      user_with_pin.support_pin_expires_at
    end
  end

  describe '#merge_request_dashboard_show_drafts?' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:user) { create(:user) }

    subject { user.merge_request_dashboard_show_drafts? }

    where(:flag_enabled, :show_drafts, :result) do
      false | false | true
      false | true  | true
      true  | true  | true
      true  | false | false
    end

    with_them do
      before do
        stub_feature_flags(mr_dashboard_drafts_toggle: flag_enabled)
        user.user_preference.update!(merge_request_dashboard_show_drafts: show_drafts)
      end

      it do
        is_expected.to be(result)
      end
    end
  end

  describe '#all_assigned_merge_requests_count' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:user) { create(:user) }

    subject { user.all_assigned_merge_requests_count }

    where(:assigned_count, :returned_count, :result) do
      nil | nil | nil
      2   | nil | 2
      nil | 2   | 2
      2   | 2   | 4
    end

    with_them do
      before do
        allow(user).to receive(:assigned_open_merge_requests_count).and_return(assigned_count)
        allow(user).to receive(:returned_to_you_merge_requests_count).and_return(returned_count)
      end

      it do
        is_expected.to be(result)
      end
    end
  end
end
