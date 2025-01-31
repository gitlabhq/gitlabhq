# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UsersHelper, feature_category: :user_management do
  include TermsHelper

  let_it_be(:user) { create(:user, timezone: ActiveSupport::TimeZone::MAPPING['UTC']) }

  def filter_ee_badges(badges)
    badges.reject { |badge| badge[:text] == 'Is using seat' }
  end

  describe 'has_contact_info?' do
    subject { helper.has_contact_info?(user) }

    context 'when user has skype profile' do
      let_it_be(:user) { create(:user, bluesky: 'did:plc:ewvi7nxzyoun6zhxrhs64oiz') }

      it { is_expected.to be true }
    end

    context 'when user has public email' do
      let_it_be(:user) { create(:user, :public_email) }

      it { is_expected.to be true }
    end

    context 'when user public email is blank' do
      let_it_be(:user) { create(:user, public_email: '') }

      it { is_expected.to be false }
    end
  end

  describe 'display_public_email?' do
    let_it_be(:user) { create(:user, :public_email) }

    subject { helper.display_public_email?(user) }

    it { is_expected.to be true }

    context 'when user public email is blank' do
      let_it_be(:user) { create(:user, public_email: '') }

      it { is_expected.to be false }
    end
  end

  describe '#user_link' do
    subject { helper.user_link(user) }

    it "links to the user's profile" do
      is_expected.to include("href=\"#{user_path(user)}\"")
    end

    it "has the user's email as title" do
      is_expected.to include("title=\"#{user.email}\"")
    end
  end

  describe '#user_clear_status_at' do
    context 'when status exists' do
      context 'with clear_status_at set' do
        it 'has the correct iso formatted date', time_travel_to: '2020-01-01 00:00:00 +0000' do
          clear_status_at = 1.day.from_now
          status = build_stubbed(:user_status, clear_status_at: clear_status_at)

          expect(user_clear_status_at(status.user)).to eq('2020-01-02T00:00:00Z')
        end
      end

      context 'without clear_status_at set' do
        it 'returns nil' do
          status = build_stubbed(:user_status, clear_status_at: nil)

          expect(user_clear_status_at(status.user)).to be_nil
        end
      end
    end

    context 'without status' do
      it 'returns nil' do
        user = build_stubbed(:user)

        expect(user_clear_status_at(user)).to be_nil
      end
    end
  end

  describe '#profile_actions' do
    subject(:profile_actions) { helper.profile_actions(other_user) }

    let_it_be(:other_user) { create(:user) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(user).to receive(:bot?).and_return(false)
      allow(helper).to receive(:can?).with(user, :read_user_profile, other_user).and_return(true)
    end

    context 'with public profile' do
      it 'contains all profile actions' do
        expect(profile_actions).to match_array [:overview, :activity, :groups, :contributed, :projects, :starred, :snippets, :followers, :following]
      end
    end

    context 'with private profile' do
      before do
        allow(helper).to receive(:can?).with(user, :read_user_profile, other_user).and_return(false)
      end

      it 'is empty' do
        expect(profile_actions).to be_empty
      end
    end

    context 'with a public bot user' do
      let_it_be(:other_user) { create(:user, :bot) }

      it 'contains bot profile actions' do
        expect(profile_actions).to match_array [:overview, :activity]
      end
    end
  end

  describe '#user_internal_regex_data' do
    using RSpec::Parameterized::TableSyntax

    where(:user_default_external, :user_default_internal_regex, :result) do
      false | nil                | { user_internal_regex_pattern: nil, user_internal_regex_options: nil }
      false | ''                 | { user_internal_regex_pattern: nil, user_internal_regex_options: nil }
      false | 'mockRegexPattern' | { user_internal_regex_pattern: nil, user_internal_regex_options: nil }
      true  | nil                | { user_internal_regex_pattern: nil, user_internal_regex_options: nil }
      true  | ''                 | { user_internal_regex_pattern: nil, user_internal_regex_options: nil }
      true  | 'mockRegexPattern' | { user_internal_regex_pattern: 'mockRegexPattern', user_internal_regex_options: 'i' }
    end

    with_them do
      before do
        stub_application_setting(user_default_external: user_default_external)
        stub_application_setting(user_default_internal_regex: user_default_internal_regex)
      end

      subject { helper.user_internal_regex_data }

      it { is_expected.to eq(result) }
    end
  end

  describe '#current_user_menu_items' do
    subject(:items) { helper.current_user_menu_items }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:can?).and_return(false)
    end

    it 'includes all default items' do
      expect(items).to include(:help, :sign_out)
    end

    it 'includes the profile tab if the user can read themself' do
      expect(helper).to receive(:can?).with(user, :read_user, user) { true }

      expect(items).to include(:profile)
    end

    it 'includes the settings tab if the user can update themself' do
      expect(helper).to receive(:can?).with(user, :update_user, user) { true }

      expect(items).to include(:settings)
    end

    context 'when terms are enforced' do
      before do
        enforce_terms
      end

      it 'hides the profile and the settings tab' do
        expect(items).not_to include(:settings, :profile, :help)
      end
    end
  end

  describe '#impersonation_enabled' do
    context 'when impersonation is enabled' do
      before do
        stub_config_setting(impersonation_enabled: true)
      end

      it 'allows the admin to impersonate a  user' do
        expect(helper.impersonation_enabled?).to eq(true)
      end

      it 'allows impersonation tokens' do
        expect(helper.impersonation_tokens_enabled?).to eq(true)
      end
    end
  end

  describe '#can_impersonate_user' do
    let(:user) { create(:user) }
    let(:impersonation_in_progress) { false }

    subject { helper.can_impersonate_user(user, impersonation_in_progress) }

    context 'when password is expired' do
      let(:user) { create(:user, password_expires_at: 1.minute.ago) }

      it { is_expected.to be false }
    end

    context 'when impersonation is in progress' do
      let(:impersonation_in_progress) { true }

      it { is_expected.to be false }
    end

    context 'when user is blocked' do
      let(:user) { create(:user, :blocked) }

      it { is_expected.to be false }
    end

    context 'when user is internal' do
      let(:user) { create(:user, :bot) }

      it { is_expected.to be false }
    end

    it { is_expected.to be true }
  end

  describe '#impersonation_error_text' do
    let(:user) { create(:user) }
    let(:impersonation_in_progress) { false }

    subject { helper.impersonation_error_text(user, impersonation_in_progress) }

    context 'when password is expired' do
      let(:user) { create(:user, password_expires_at: 1.minute.ago) }

      it { is_expected.to eq(_("You cannot impersonate a user with an expired password")) }
    end

    context 'when impersonation is in progress' do
      let(:impersonation_in_progress) { true }

      it { is_expected.to eq(_("You are already impersonating another user")) }
    end

    context 'when user is blocked' do
      let(:user) { create(:user, :blocked) }

      it { is_expected.to eq(_("You cannot impersonate a blocked user")) }
    end

    context 'when user is internal' do
      let(:user) { create(:user, :bot) }

      it { is_expected.to eq(_("You cannot impersonate an internal user")) }
    end

    context 'when user is inactive' do
      let(:user) { create(:user, :deactivated) }

      it { is_expected.to eq(_("You cannot impersonate a user who cannot log in")) }
    end
  end

  describe '#user_badges_in_admin_section' do
    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    context 'with a blocked user' do
      it "returns the blocked badge" do
        blocked_user = create(:user, state: 'blocked')

        badges = helper.user_badges_in_admin_section(blocked_user)

        expect(filter_ee_badges(badges)).to match_array([text: s_("AdminUsers|Blocked"), variant: "danger"])
      end
    end

    context 'with a pending approval user' do
      it 'returns the pending approval badge' do
        blocked_pending_approval_user = create(:user, :blocked_pending_approval)

        badges = helper.user_badges_in_admin_section(blocked_pending_approval_user)

        expect(filter_ee_badges(badges)).to match_array([text: s_('AdminUsers|Pending approval'), variant: 'info'])
      end
    end

    context 'with a banned user' do
      it 'returns the banned badge' do
        banned_user = create(:user, :banned)

        badges = helper.user_badges_in_admin_section(banned_user)

        expect(filter_ee_badges(badges)).to match_array([text: s_('AdminUsers|Banned'), variant: 'danger'])
      end
    end

    context 'with an admin user' do
      it "returns the admin badge" do
        admin_user = create(:admin)

        badges = helper.user_badges_in_admin_section(admin_user)

        expect(filter_ee_badges(badges)).to match_array([text: s_("AdminUsers|Admin"), variant: "success"])
      end
    end

    context 'with a bot' do
      it "returns the bot badge" do
        bot = create(:user, :bot)

        badges = helper.user_badges_in_admin_section(bot)

        expect(filter_ee_badges(badges)).to match_array([text: s_('AdminUsers|Bot'), variant: "muted"])
      end
    end

    context 'with a deactivated user' do
      it "returns the deactivated badge" do
        deactivated = create(:user, :deactivated)

        badges = helper.user_badges_in_admin_section(deactivated)

        expect(filter_ee_badges(badges)).to match_array([text: s_('AdminUsers|Deactivated'), variant: "danger"])
      end
    end

    context 'with an external user' do
      it 'returns the external badge' do
        external_user = create(:user, external: true)

        badges = helper.user_badges_in_admin_section(external_user)

        expect(filter_ee_badges(badges)).to match_array([text: s_("AdminUsers|External"), variant: "secondary"])
      end
    end

    context 'with the current user' do
      it 'returns the "It\'s You" badge' do
        badges = helper.user_badges_in_admin_section(user)

        expect(filter_ee_badges(badges)).to match_array([text: s_("AdminUsers|It's you!"), variant: "muted"])
      end
    end

    context 'with an external blocked admin' do
      it 'returns the blocked, admin and external badges' do
        user = create(:admin, state: 'blocked', external: true)

        badges = helper.user_badges_in_admin_section(user)

        expect(badges).to match_array(
          [
            { text: s_("AdminUsers|Blocked"), variant: "danger" },
            { text: s_("AdminUsers|Admin"), variant: "success" },
            { text: s_("AdminUsers|External"), variant: "secondary" }
          ])
      end
    end

    context 'with a locked user', time_travel_to: '2020-02-25 10:30:45 -0700' do
      it 'returns the "Locked" badge' do
        locked_user = create(:user, locked_at: DateTime.parse('2020-02-25 10:30:00 -0700'))

        badges = helper.user_badges_in_admin_section(locked_user)

        expect(filter_ee_badges(badges)).to match_array([text: s_("AdminUsers|Locked"), variant: "warning"])
      end
    end

    context 'get badges for normal user' do
      it 'returns no badges' do
        user = create(:user)

        badges = helper.user_badges_in_admin_section(user)

        expect(filter_ee_badges(badges)).to be_empty
      end
    end
  end

  describe '#can_force_email_confirmation?' do
    subject { helper.can_force_email_confirmation?(user) }

    context 'for a user that is already confirmed' do
      it { is_expected.to eq(false) }
    end

    context 'for a user that is not confirmed' do
      let(:user) { create(:user, :unconfirmed) }

      it { is_expected.to eq(true) }
    end
  end

  describe '#work_information' do
    let(:with_schema_markup) { false }

    subject { helper.work_information(user, with_schema_markup: with_schema_markup) }

    context 'when neither organization nor job_title are present' do
      it { is_expected.to be_nil }
    end

    context 'when user parameter is nil' do
      let(:user) { nil }

      it { is_expected.to be_nil }
    end

    context 'without schema markup' do
      context 'when both job_title and organization are present' do
        let(:user) { build(:user, organization: 'GitLab', job_title: 'Frontend Engineer') }

        it 'returns job title concatenated with organization' do
          is_expected.to eq('Frontend Engineer at GitLab')
        end
      end

      context 'when only organization is present' do
        let(:user) { build(:user, organization: 'GitLab') }

        it "returns organization" do
          is_expected.to eq('GitLab')
        end
      end

      context 'when only job_title is present' do
        let(:user) { build(:user, job_title: 'Frontend Engineer') }

        it 'returns job title' do
          is_expected.to eq('Frontend Engineer')
        end
      end
    end

    context 'with schema markup' do
      let(:with_schema_markup) { true }

      context 'when both job_title and organization are present' do
        let(:user) { build(:user, organization: 'GitLab', job_title: 'Frontend Engineer') }

        it 'returns job title concatenated with organization' do
          is_expected.to eq('<span itemprop="jobTitle">Frontend Engineer</span> at <span itemprop="worksFor">GitLab</span>')
        end
      end

      context 'when only organization is present' do
        let(:user) { build(:user, organization: 'GitLab') }

        it "returns organization" do
          is_expected.to eq('<span itemprop="worksFor">GitLab</span>')
        end
      end

      context 'when only job_title is present' do
        let(:user) { build(:user, job_title: 'Frontend Engineer') }

        it 'returns job title' do
          is_expected.to eq('<span itemprop="jobTitle">Frontend Engineer</span>')
        end
      end
    end
  end

  describe '#user_display_name' do
    subject { helper.user_display_name(user) }

    before do
      stub_current_user(nil)
    end

    context 'for a confirmed user' do
      let(:user) { create(:user) }

      before do
        stub_profile_permission_allowed(true)
      end

      it { is_expected.to eq(user.name) }
    end

    context 'for an unconfirmed user' do
      let(:user) { create(:user, :unconfirmed) }

      before do
        stub_profile_permission_allowed(false)
      end

      it { is_expected.to eq('Unconfirmed user') }

      context 'when current user is an admin' do
        before do
          admin_user = create(:admin)
          stub_current_user(admin_user)
          stub_profile_permission_allowed(true, admin_user)
        end

        it { is_expected.to eq(user.name) }
      end

      context 'when the current user is self' do
        before do
          stub_current_user(user)
          stub_profile_permission_allowed(true, user)
        end

        it { is_expected.to eq(user.name) }
      end
    end

    context 'for a blocked user' do
      let(:user) { create(:user, :blocked) }

      it { is_expected.to eq('Blocked user') }
    end

    def stub_current_user(user)
      allow(helper).to receive(:current_user).and_return(user)
    end

    def stub_profile_permission_allowed(allowed, current_user = nil)
      allow(helper).to receive(:can?).with(current_user, :read_user_profile, user).and_return(allowed)
    end
  end

  describe '#admin_users_data_attributes' do
    subject(:data) { helper.admin_users_data_attributes([user]) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    it 'users matches the serialized json' do
      entity = double
      expect_next_instance_of(Admin::UserSerializer) do |instance|
        expect(instance).to receive(:represent).with([user], { current_user: user }).and_return(entity)
      end
      expect(entity).to receive(:to_json).and_return("{\"username\":\"admin\"}")
      expect(data[:users]).to eq "{\"username\":\"admin\"}"
    end

    it 'paths matches the schema' do
      expect(data[:paths]).to match_schema('entities/admin_users_data_attributes_paths')
    end
  end

  describe '#confirm_user_data' do
    confirm_admin_user_path = '/admin/users/root/confirm'

    before do
      allow(helper).to receive(:confirm_admin_user_path).with(user).and_return(confirm_admin_user_path)
    end

    subject(:confirm_user_data) { helper.confirm_user_data(user) }

    it 'sets `path` key correctly' do
      expect(confirm_user_data[:path]).to eq(confirm_admin_user_path)
    end

    it 'sets `modal_attributes` key to valid json' do
      expect(confirm_user_data[:modal_attributes]).to be_valid_json
    end

    context 'when `user.unconfirmed_email` is set' do
      let(:user) { create(:user, :unconfirmed, unconfirmed_email: 'foo@bar.com') }

      it 'sets `modal_attributes.messageHtml` correctly' do
        expect(Gitlab::Json.parse(confirm_user_data[:modal_attributes])['messageHtml']).to eq('This user has an unconfirmed email address (foo@bar.com). You may force a confirmation.')
      end
    end

    context 'when `user.unconfirmed_email` is not set' do
      it 'sets `modal_attributes.messageHtml` correctly' do
        expect(Gitlab::Json.parse(confirm_user_data[:modal_attributes])['messageHtml']).to eq('This user has an unconfirmed email address. You may force a confirmation.')
      end
    end
  end

  describe '#user_email_help_text' do
    subject(:user_email_help_text) { helper.user_email_help_text(user) }

    context 'when `user.unconfirmed_email` is not set' do
      it 'contains avatar detection text' do
        expect(user_email_help_text).to include _('We also use email for avatar detection if no avatar is uploaded.')
      end
    end

    context 'when `user.unconfirmed_email` is set' do
      let(:user) { create(:user, :unconfirmed, unconfirmed_email: 'foo@bar.com') }

      it 'contains resend confirmation e-mail text' do
        expect(user_email_help_text).to include _('Resend confirmation e-mail')
        expect(user_email_help_text).to match(/Please click the link in the confirmation email before continuing. It was sent to.*#{user.unconfirmed_email}/)
      end
    end
  end

  describe '#admin_user_actions_data_attributes' do
    subject(:data) { helper.admin_user_actions_data_attributes(user) }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(Admin::UserEntity).to receive(:represent).and_call_original
    end

    it 'user matches the serialized json' do
      expect(data[:user]).to be_valid_json
      expect(Admin::UserEntity).to have_received(:represent).with(user, hash_including({ current_user: user }))
    end

    it 'paths matches the schema' do
      expect(data[:paths]).to match_schema('entities/admin_users_data_attributes_paths')
    end
  end

  describe '#user_profile_app_data' do
    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:user_calendar_path).with(user, :json).and_return('/users/root/calendar.json')
      allow(helper).to receive(:user_activity_path).with(user, :json).and_return('/users/root/activity.json')
      allow(helper).to receive(:new_snippet_path).and_return('/-/snippets/new')
      allow(user).to receive_message_chain(:followers, :count).and_return(2)
      allow(user).to receive_message_chain(:followees, :count).and_return(3)
    end

    it 'returns expected hash' do
      allow(helper).to receive(:can?).with(user, :create_snippet).and_return(true)

      expect(helper.user_profile_app_data(user)).to match({
        followees_count: 3,
        followers_count: 2,
        user_calendar_path: '/users/root/calendar.json',
        user_activity_path: '/users/root/activity.json',
        utc_offset: 0,
        user_id: user.id,
        new_snippet_path: '/-/snippets/new',
        snippets_empty_state: match_asset_path('illustrations/empty-state/empty-snippets-md.svg'),
        follow_empty_state: match_asset_path('illustrations/empty-state/empty-friends-md.svg')
      })
    end

    context 'when user does not have create_snippet permissions' do
      before do
        allow(helper).to receive(:can?).with(user, :create_snippet).and_return(false)
      end

      it 'returns nil for new_snippet_path property' do
        expect(helper.user_profile_app_data(user)[:new_snippet_path]).to be_nil
      end
    end
  end

  describe '#load_max_project_member_accesses' do
    let_it_be(:projects) { create_list(:project, 3) }

    before_all do
      projects.first.add_developer(user)
    end

    context 'without current_user' do
      before do
        allow(helper).to receive(:current_user).and_return(nil)
      end

      it 'executes no queries', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/444713' do
        sample = ActiveRecord::QueryRecorder.new do
          helper.load_max_project_member_accesses(projects)
        end

        expect(sample).not_to exceed_query_limit(0)
      end
    end

    context 'when current_user is present', :request_store do
      before do
        allow(helper).to receive(:current_user).and_return(user)
      end

      it 'preloads ProjectPolicy#lookup_access_level! and UsersHelper#max_member_project_member_access for current_user in two queries', :aggregate_failures, quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/446111' do
        preload_queries = ActiveRecord::QueryRecorder.new do
          helper.load_max_project_member_accesses(projects)
        end

        helper_queries = ActiveRecord::QueryRecorder.new do
          projects.each do |project|
            helper.max_project_member_access(project)
          end
        end

        access_queries = ActiveRecord::QueryRecorder.new do
          projects.each do |project|
            user.can?(:read_code, project)
          end
        end

        expect(preload_queries).not_to exceed_query_limit(2)
        expect(helper_queries).not_to exceed_query_limit(0)
        expect(access_queries).not_to exceed_query_limit(1)
      end
    end
  end

  describe '#moderation_status', feature_category: :instance_resiliency do
    let(:user) { create(:user) }

    subject { moderation_status(user) }

    context 'when user is nil' do
      let(:user) { nil }

      it { is_expected.to be_nil }
    end

    context 'when a user is banned' do
      before do
        user.ban!
      end

      it { is_expected.to eq('Banned') }
    end

    context 'when a user is blocked' do
      before do
        user.block!
      end

      it { is_expected.to eq('Blocked') }
    end

    context 'when a user is active' do
      it { is_expected.to eq('Active') }
    end
  end

  describe '#user_profile_actions_data' do
    let(:user_1) { create(:user) }
    let(:user_2) { create(:user) }
    let(:user_path) { '/users/root' }

    subject { helper.user_profile_actions_data(user_1) }

    before do
      allow(helper).to receive(:user_path).and_return(user_path)
      allow(helper).to receive(:user_url).and_return(user_path)
    end

    shared_examples 'user cannot report' do
      it 'returns data without reporting related data' do
        is_expected.to match({
          user_id: user_1.id,
          rss_subscription_path: user_path
        })
      end
    end

    context 'user is current user' do
      before do
        allow(helper).to receive(:current_user).and_return(user_1)
      end

      it_behaves_like 'user cannot report'
    end

    context 'user is not current user' do
      before do
        allow(helper).to receive(:current_user).and_return(user_2)
      end

      it 'returns data for reporting related data' do
        is_expected.to match({
          user_id: user_1.id,
          rss_subscription_path: user_path,
          report_abuse_path: add_category_abuse_reports_path,
          reported_user_id: user_1.id,
          reported_from_url: user_path
        })
      end
    end

    context 'when logged out' do
      before do
        allow(helper).to receive(:current_user).and_return(nil)
      end

      it_behaves_like 'user cannot report'
    end
  end
end
