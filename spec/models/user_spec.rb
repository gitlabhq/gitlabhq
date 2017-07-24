require 'spec_helper'

describe User, models: true do
  include Gitlab::CurrentSettings

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Gitlab::ConfigHelper) }
    it { is_expected.to include_module(Gitlab::CurrentSettings) }
    it { is_expected.to include_module(Referable) }
    it { is_expected.to include_module(Sortable) }
    it { is_expected.to include_module(TokenAuthenticatable) }
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:path).to(:namespace).with_prefix }

    # EE
    it { is_expected.to delegate_method(:shared_runners_minutes_limit).to(:namespace) }
    it { is_expected.to delegate_method(:shared_runners_minutes_limit=).to(:namespace).with_arguments(133) }
  end

  describe 'associations' do
    it { is_expected.to have_one(:namespace) }
    it { is_expected.to have_many(:snippets).dependent(:destroy) }
    it { is_expected.to have_many(:project_members).dependent(:destroy) }
    it { is_expected.to have_many(:groups) }
    it { is_expected.to have_many(:keys).dependent(:destroy) }
    it { is_expected.to have_many(:deploy_keys).dependent(:destroy) }
    it { is_expected.to have_many(:events).dependent(:destroy) }
    it { is_expected.to have_many(:recent_events).class_name('Event') }
    it { is_expected.to have_many(:issues).dependent(:destroy) }
    it { is_expected.to have_many(:notes).dependent(:destroy) }
    it { is_expected.to have_many(:merge_requests).dependent(:destroy) }
    it { is_expected.to have_many(:identities).dependent(:destroy) }
    it { is_expected.to have_many(:spam_logs).dependent(:destroy) }
    it { is_expected.to have_many(:todos).dependent(:destroy) }
    it { is_expected.to have_many(:award_emoji).dependent(:destroy) }
    it { is_expected.to have_many(:path_locks).dependent(:destroy) }
    it { is_expected.to have_many(:triggers).dependent(:destroy) }
    it { is_expected.to have_many(:builds).dependent(:nullify) }
    it { is_expected.to have_many(:pipelines).dependent(:nullify) }
    it { is_expected.to have_many(:chat_names).dependent(:destroy) }
    it { is_expected.to have_many(:uploads).dependent(:destroy) }
    it { is_expected.to have_many(:reported_abuse_reports).dependent(:destroy).class_name('AbuseReport') }

    describe "#abuse_report" do
      let(:current_user) { create(:user) }
      let(:other_user) { create(:user) }

      it { is_expected.to have_one(:abuse_report) }

      it "refers to the abuse report whose user_id is the current user" do
        abuse_report = create(:abuse_report, reporter: other_user, user: current_user)

        expect(current_user.abuse_report).to eq(abuse_report)
      end

      it "does not refer to the abuse report whose reporter_id is the current user" do
        create(:abuse_report, reporter: current_user, user: other_user)

        expect(current_user.abuse_report).to be_nil
      end

      it "does not update the user_id of an abuse report when the user is updated" do
        abuse_report = create(:abuse_report, reporter: current_user, user: other_user)

        current_user.block

        expect(abuse_report.reload.user).to eq(other_user)
      end
    end

    describe '#group_members' do
      it 'does not include group memberships for which user is a requester' do
        user = create(:user)
        group = create(:group, :public, :access_requestable)
        group.request_access(user)

        expect(user.group_members).to be_empty
      end
    end

    describe '#project_members' do
      it 'does not include project memberships for which user is a requester' do
        user = create(:user)
        project = create(:empty_project, :public, :access_requestable)
        project.request_access(user)

        expect(user.project_members).to be_empty
      end
    end
  end

  describe 'nested attributes' do
    it { is_expected.to respond_to(:namespace_attributes=) }
  end

  describe 'validations' do
    describe 'username' do
      it 'validates presence' do
        expect(subject).to validate_presence_of(:username)
      end

      it 'rejects blacklisted names' do
        user = build(:user, username: 'dashboard')

        expect(user).not_to be_valid
        expect(user.errors.values).to eq [['dashboard is a reserved name']]
      end

      it 'allows child names' do
        user = build(:user, username: 'avatar')

        expect(user).to be_valid
      end

      it 'allows wildcard names' do
        user = build(:user, username: 'blob')

        expect(user).to be_valid
      end

      it 'validates uniqueness' do
        expect(subject).to validate_uniqueness_of(:username).case_insensitive
      end
    end

    it { is_expected.to validate_presence_of(:projects_limit) }
    it { is_expected.to validate_numericality_of(:projects_limit) }
    it { is_expected.to allow_value(0).for(:projects_limit) }
    it { is_expected.not_to allow_value(-1).for(:projects_limit) }
    it { is_expected.not_to allow_value(Gitlab::Database::MAX_INT_VALUE + 1).for(:projects_limit) }

    it { is_expected.to validate_length_of(:bio).is_at_most(255) }

    it_behaves_like 'an object with email-formated attributes', :email do
      subject { build(:user) }
    end

    it_behaves_like 'an object with email-formated attributes', :public_email, :notification_email do
      subject { build(:user).tap { |user| user.emails << build(:email, email: email_value) } }
    end

    describe 'email' do
      context 'when no signup domains whitelisted' do
        before do
          allow_any_instance_of(ApplicationSetting).to receive(:domain_whitelist).and_return([])
        end

        it 'accepts any email' do
          user = build(:user, email: "info@example.com")
          expect(user).to be_valid
        end
      end

      context 'when a signup domain is whitelisted and subdomains are allowed' do
        before do
          allow_any_instance_of(ApplicationSetting).to receive(:domain_whitelist).and_return(['example.com', '*.example.com'])
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
        end
      end

      context 'when a signup domain is whitelisted and subdomains are not allowed' do
        before do
          allow_any_instance_of(ApplicationSetting).to receive(:domain_whitelist).and_return(['example.com'])
        end

        it 'accepts info@example.com' do
          user = build(:user, email: "info@example.com")
          expect(user).to be_valid
        end

        it 'rejects info@test.example.com' do
          user = build(:user, email: "info@test.example.com")
          expect(user).to be_invalid
        end

        it 'rejects example@test.com' do
          user = build(:user, email: "example@test.com")
          expect(user).to be_invalid
        end

        it 'accepts example@test.com when added by another user' do
          user = build(:user, email: "example@test.com", created_by_id: 1)
          expect(user).to be_valid
        end
      end

      context 'domain blacklist' do
        before do
          allow_any_instance_of(ApplicationSetting).to receive(:domain_blacklist_enabled?).and_return(true)
          allow_any_instance_of(ApplicationSetting).to receive(:domain_blacklist).and_return(['example.com'])
        end

        context 'when a signup domain is blacklisted' do
          it 'accepts info@test.com' do
            user = build(:user, email: 'info@test.com')
            expect(user).to be_valid
          end

          it 'rejects info@example.com' do
            user = build(:user, email: 'info@example.com')
            expect(user).not_to be_valid
          end

          it 'accepts info@example.com when added by another user' do
            user = build(:user, email: 'info@example.com', created_by_id: 1)
            expect(user).to be_valid
          end
        end

        context 'when a signup domain is blacklisted but a wildcard subdomain is allowed' do
          before do
            allow_any_instance_of(ApplicationSetting).to receive(:domain_blacklist).and_return(['test.example.com'])
            allow_any_instance_of(ApplicationSetting).to receive(:domain_whitelist).and_return(['*.example.com'])
          end

          it 'gives priority to whitelist and allow info@test.example.com' do
            user = build(:user, email: 'info@test.example.com')
            expect(user).to be_valid
          end
        end

        context 'with both lists containing a domain' do
          before do
            allow_any_instance_of(ApplicationSetting).to receive(:domain_whitelist).and_return(['test.com'])
          end

          it 'accepts info@test.com' do
            user = build(:user, email: 'info@test.com')
            expect(user).to be_valid
          end

          it 'rejects info@example.com' do
            user = build(:user, email: 'info@example.com')
            expect(user).not_to be_valid
          end
        end
      end

      context 'owns_notification_email' do
        it 'accepts temp_oauth_email emails' do
          user = build(:user, email: "temp-email-for-oauth@example.com")
          expect(user).to be_valid
        end
      end
    end

    it 'does not allow a user to be both an auditor and an admin' do
      user = build(:user, :admin, :auditor)

      expect(user).to be_invalid
    end
  end

  describe "non_ldap" do
    it "retuns non-ldap user" do
      User.delete_all
      create :user
      ldap_user = create :omniauth_user, provider: "ldapmain"
      create :omniauth_user, provider: "gitlub"

      users = User.non_ldap
      expect(users.count).to eq 2
      expect(users.detect { |user| user.username == ldap_user.username }).to be_nil
    end
  end

  describe "scopes" do
    describe ".with_two_factor" do
      it "returns users with 2fa enabled via OTP" do
        user_with_2fa = create(:user, :two_factor_via_otp)
        user_without_2fa = create(:user)
        users_with_two_factor = User.with_two_factor.pluck(:id)

        expect(users_with_two_factor).to include(user_with_2fa.id)
        expect(users_with_two_factor).not_to include(user_without_2fa.id)
      end

      it "returns users with 2fa enabled via U2F" do
        user_with_2fa = create(:user, :two_factor_via_u2f)
        user_without_2fa = create(:user)
        users_with_two_factor = User.with_two_factor.pluck(:id)

        expect(users_with_two_factor).to include(user_with_2fa.id)
        expect(users_with_two_factor).not_to include(user_without_2fa.id)
      end

      it "returns users with 2fa enabled via OTP and U2F" do
        user_with_2fa = create(:user, :two_factor_via_otp, :two_factor_via_u2f)
        user_without_2fa = create(:user)
        users_with_two_factor = User.with_two_factor.pluck(:id)

        expect(users_with_two_factor).to eq([user_with_2fa.id])
        expect(users_with_two_factor).not_to include(user_without_2fa.id)
      end
    end

    describe ".without_two_factor" do
      it "excludes users with 2fa enabled via OTP" do
        user_with_2fa = create(:user, :two_factor_via_otp)
        user_without_2fa = create(:user)
        users_without_two_factor = User.without_two_factor.pluck(:id)

        expect(users_without_two_factor).to include(user_without_2fa.id)
        expect(users_without_two_factor).not_to include(user_with_2fa.id)
      end

      it "excludes users with 2fa enabled via U2F" do
        user_with_2fa = create(:user, :two_factor_via_u2f)
        user_without_2fa = create(:user)
        users_without_two_factor = User.without_two_factor.pluck(:id)

        expect(users_without_two_factor).to include(user_without_2fa.id)
        expect(users_without_two_factor).not_to include(user_with_2fa.id)
      end

      it "excludes users with 2fa enabled via OTP and U2F" do
        user_with_2fa = create(:user, :two_factor_via_otp, :two_factor_via_u2f)
        user_without_2fa = create(:user)
        users_without_two_factor = User.without_two_factor.pluck(:id)

        expect(users_without_two_factor).to include(user_without_2fa.id)
        expect(users_without_two_factor).not_to include(user_with_2fa.id)
      end
    end

    describe '.todo_authors' do
      it 'filters users' do
        create :user
        user_2 = create :user
        user_3 = create :user
        current_user = create :user
        create(:todo, user: current_user, author: user_2, state: :done)
        create(:todo, user: current_user, author: user_3, state: :pending)

        expect(User.todo_authors(current_user.id, 'pending')).to eq [user_3]
        expect(User.todo_authors(current_user.id, 'done')).to eq [user_2]
      end
    end
  end

  describe "Respond to" do
    it { is_expected.to respond_to(:admin?) }
    it { is_expected.to respond_to(:name) }
    it { is_expected.to respond_to(:private_token) }
    it { is_expected.to respond_to(:external?) }
  end

  describe 'before save hook' do
    context 'when saving an external user' do
      let(:user)          { create(:user) }
      let(:external_user) { create(:user, external: true) }

      it "sets other properties aswell" do
        expect(external_user.can_create_team).to be_falsey
        expect(external_user.can_create_group).to be_falsey
        expect(external_user.projects_limit).to be 0
      end
    end
  end

  describe '#update_tracked_fields!', :clean_gitlab_redis_shared_state do
    let(:request) { OpenStruct.new(remote_ip: "127.0.0.1") }
    let(:user) { create(:user) }

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

  describe '#deploy_keys' do
    include_context 'user keys'

    context 'with key and deploy key stored' do
      it 'returns stored deploy key, but not normal key' do
        expect(user.deploy_keys).to include deploy_key
        expect(user.deploy_keys).not_to include key
      end
    end
  end

  describe '#confirm' do
    before do
      allow_any_instance_of(ApplicationSetting).to receive(:send_user_confirmation_email).and_return(true)
    end

    let(:user) { create(:user, confirmed_at: nil, unconfirmed_email: 'test@gitlab.com') }

    it 'returns unconfirmed' do
      expect(user.confirmed?).to be_falsey
    end

    it 'confirms a user' do
      user.confirm
      expect(user.confirmed?).to be_truthy
    end
  end

  describe '#to_reference' do
    let(:user) { create(:user) }

    it 'returns a String reference to the object' do
      expect(user.to_reference).to eq "@#{user.username}"
    end
  end

  describe '#generate_password' do
    it "does not generate password by default" do
      user = create(:user, password: 'abcdefghe')
      expect(user.password).to eq('abcdefghe')
    end
  end

  describe 'authentication token' do
    it "has authentication token" do
      user = create(:user)
      expect(user.authentication_token).not_to be_blank
    end
  end

  describe 'ensure incoming email token' do
    it 'has incoming email token' do
      user = create(:user)
      expect(user.incoming_email_token).not_to be_blank
    end
  end

  describe '#ensure_user_rights_and_limits' do
    describe 'with external user' do
      let(:user) { create(:user, external: true) }

      it 'receives callback when external changes' do
        expect(user).to receive(:ensure_user_rights_and_limits)

        user.update_attributes(external: false)
      end

      it 'ensures correct rights and limits for user' do
        stub_config_setting(default_can_create_group: true)

        expect { user.update_attributes(external: false) }.to change { user.can_create_group }.to(true)
          .and change { user.projects_limit }.to(current_application_settings.default_projects_limit)
      end
    end

    describe 'without external user' do
      let(:user) { create(:user, external: false) }

      it 'receives callback when external changes' do
        expect(user).to receive(:ensure_user_rights_and_limits)

        user.update_attributes(external: true)
      end

      it 'ensures correct rights and limits for user' do
        expect { user.update_attributes(external: true) }.to change { user.can_create_group }.to(false)
          .and change { user.projects_limit }.to(0)
      end
    end
  end

  describe 'rss token' do
    it 'ensures an rss token on read' do
      user = create(:user, rss_token: nil)
      rss_token = user.rss_token
      expect(rss_token).not_to be_blank
      expect(user.reload.rss_token).to eq rss_token
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
      user = build_stubbed(:user, reset_password_sent_at: Time.now)

      expect(user.recently_sent_password_reset?).to eq true
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
    end
  end

  describe 'projects' do
    before do
      @user = create(:user)

      @project = create(:empty_project, namespace: @user.namespace)
      @project_2 = create(:empty_project, group: create(:group)) do |project|
        project.add_master(@user)
      end
      @project_3 = create(:empty_project, group: create(:group)) do |project|
        project.add_developer(@user)
      end
    end

    it { expect(@user.authorized_projects).to include(@project) }
    it { expect(@user.authorized_projects).to include(@project_2) }
    it { expect(@user.authorized_projects).to include(@project_3) }
    it { expect(@user.owned_projects).to include(@project) }
    it { expect(@user.owned_projects).not_to include(@project_2) }
    it { expect(@user.owned_projects).not_to include(@project_3) }
    it { expect(@user.personal_projects).to include(@project) }
    it { expect(@user.personal_projects).not_to include(@project_2) }
    it { expect(@user.personal_projects).not_to include(@project_3) }
  end

  describe 'groups' do
    before do
      @user = create :user
      @group = create :group
      @group.add_owner(@user)
    end

    it { expect(@user.several_namespaces?).to be_truthy }
    it { expect(@user.authorized_groups).to eq([@group]) }
    it { expect(@user.owned_groups).to eq([@group]) }
    it { expect(@user.namespaces).to match_array([@user.namespace, @group]) }
  end

  describe 'group multiple owners' do
    before do
      @user = create :user
      @user2 = create :user
      @group = create :group
      @group.add_owner(@user)

      @group.add_user(@user2, GroupMember::OWNER)
    end

    it { expect(@user2.several_namespaces?).to be_truthy }
  end

  describe 'namespaced' do
    before do
      @user = create :user
      @project = create(:empty_project, namespace: @user.namespace)
    end

    it { expect(@user.several_namespaces?).to be_falsey }
    it { expect(@user.namespaces).to eq([@user.namespace]) }
  end

  describe 'blocking user' do
    let(:user) { create(:user, name: 'John Smith') }

    it "blocks user" do
      user.block
      expect(user.blocked?).to be_truthy
    end
  end

  describe '.filter' do
    let(:user) { double }

    it 'filters by active users by default' do
      expect(User).to receive(:active).and_return([user])

      expect(User.filter(nil)).to include user
    end

    it 'filters by admins' do
      expect(User).to receive(:admins).and_return([user])

      expect(User.filter('admins')).to include user
    end

    it 'filters by blocked' do
      expect(User).to receive(:blocked).and_return([user])

      expect(User.filter('blocked')).to include user
    end

    it 'filters by two_factor_disabled' do
      expect(User).to receive(:without_two_factor).and_return([user])

      expect(User.filter('two_factor_disabled')).to include user
    end

    it 'filters by two_factor_enabled' do
      expect(User).to receive(:with_two_factor).and_return([user])

      expect(User.filter('two_factor_enabled')).to include user
    end

    it 'filters by wop' do
      expect(User).to receive(:without_projects).and_return([user])

      expect(User.filter('wop')).to include user
    end
  end

  describe '.without_projects' do
    let!(:project) { create(:empty_project, :public, :access_requestable) }
    let!(:user) { create(:user) }
    let!(:user_without_project) { create(:user) }
    let!(:user_without_project2) { create(:user) }

    before do
      # add user to project
      project.team << [user, :master]

      # create invite to projet
      create(:project_member, :developer, project: project, invite_token: '1234', invite_email: 'inviteduser1@example.com')

      # create request to join project
      project.request_access(user_without_project2)
    end

    it { expect(User.without_projects).not_to include user }
    it { expect(User.without_projects).to include user_without_project }
    it { expect(User.without_projects).to include user_without_project2 }
  end

  describe 'user creation' do
    describe 'normal user' do
      let(:user) { create(:user, name: 'John Smith') }

      it { expect(user.admin?).to be_falsey }
      it { expect(user.require_ssh_key?).to be_truthy }
      it { expect(user.can_create_group?).to be_truthy }
      it { expect(user.can_create_project?).to be_truthy }
      it { expect(user.first_name).to eq('John') }
      it { expect(user.external).to be_falsey }
    end

    describe 'with defaults' do
      let(:user) { User.new }

      it "applies defaults to user" do
        expect(user.projects_limit).to eq(Gitlab.config.gitlab.default_projects_limit)
        expect(user.can_create_group).to eq(Gitlab.config.gitlab.default_can_create_group)
        expect(user.external).to be_falsey
      end
    end

    describe 'with default overrides' do
      let(:user) { User.new(projects_limit: 123, can_create_group: false, can_create_team: true) }

      it "applies defaults to user" do
        expect(user.projects_limit).to eq(123)
        expect(user.can_create_group).to be_falsey
      end
    end

    context 'when current_application_settings.user_default_external is true' do
      before do
        stub_application_setting(user_default_external: true)
      end

      it "creates external user by default" do
        user = build(:user)

        expect(user.external).to be_truthy
      end

      describe 'with default overrides' do
        it "creates a non-external user" do
          user = build(:user, external: false)

          expect(user.external).to be_falsey
        end
      end
    end

    describe '#require_ssh_key?' do
      protocol_and_expectation = {
        'http' => false,
        'ssh' => true,
        '' => true
      }

      protocol_and_expectation.each do |protocol, expected|
        it "has correct require_ssh_key?" do
          stub_application_setting(enabled_git_access_protocol: protocol)
          user = build(:user)

          expect(user.require_ssh_key?).to eq(expected)
        end
      end
    end
  end

  describe '.find_by_any_email' do
    it 'finds by primary email' do
      user = create(:user, email: 'foo@example.com')

      expect(User.find_by_any_email(user.email)).to eq user
    end

    it 'finds by secondary email' do
      email = create(:email, email: 'foo@example.com')
      user  = email.user

      expect(User.find_by_any_email(email.email)).to eq user
    end

    it 'returns nil when nothing found' do
      expect(User.find_by_any_email('')).to be_nil
    end
  end

  describe '.search' do
    let!(:user) { create(:user, name: 'user', username: 'usern', email: 'email@gmail.com') }
    let!(:user2) { create(:user, name: 'user name', username: 'username', email: 'someemail@gmail.com') }

    describe 'name matching' do
      it 'returns users with a matching name with exact match first' do
        expect(described_class.search(user.name)).to eq([user, user2])
      end

      it 'returns users with a partially matching name' do
        expect(described_class.search(user.name[0..2])).to eq([user, user2])
      end

      it 'returns users with a matching name regardless of the casing' do
        expect(described_class.search(user2.name.upcase)).to eq([user2])
      end
    end

    describe 'email matching' do
      it 'returns users with a matching Email' do
        expect(described_class.search(user.email)).to eq([user, user2])
      end

      it 'returns users with a partially matching Email' do
        expect(described_class.search(user.email[0..2])).to eq([user, user2])
      end

      it 'returns users with a matching Email regardless of the casing' do
        expect(described_class.search(user2.email.upcase)).to eq([user2])
      end
    end

    describe 'username matching' do
      it 'returns users with a matching username' do
        expect(described_class.search(user.username)).to eq([user, user2])
      end

      it 'returns users with a partially matching username' do
        expect(described_class.search(user.username[0..2])).to eq([user, user2])
      end

      it 'returns users with a matching username regardless of the casing' do
        expect(described_class.search(user2.username.upcase)).to eq([user2])
      end
    end
  end

  describe '.search_with_secondary_emails' do
    delegate :search_with_secondary_emails, to: :described_class

    let!(:user) { create(:user, name: 'John Doe', username: 'john.doe', email: 'john.doe@example.com' ) }
    let!(:another_user) { create(:user, name: 'Albert Smith', username: 'albert.smith', email: 'albert.smith@example.com' ) }
    let!(:email) do
      create(:email, user: another_user, email: 'alias@example.com')
    end

    it 'returns users with a matching name' do
      expect(search_with_secondary_emails(user.name)).to eq([user])
    end

    it 'returns users with a partially matching name' do
      expect(search_with_secondary_emails(user.name[0..2])).to eq([user])
    end

    it 'returns users with a matching name regardless of the casing' do
      expect(search_with_secondary_emails(user.name.upcase)).to eq([user])
    end

    it 'returns users with a matching email' do
      expect(search_with_secondary_emails(user.email)).to eq([user])
    end

    it 'returns users with a partially matching email' do
      expect(search_with_secondary_emails(user.email[0..2])).to eq([user])
    end

    it 'returns users with a matching email regardless of the casing' do
      expect(search_with_secondary_emails(user.email.upcase)).to eq([user])
    end

    it 'returns users with a matching username' do
      expect(search_with_secondary_emails(user.username)).to eq([user])
    end

    it 'returns users with a partially matching username' do
      expect(search_with_secondary_emails(user.username[0..2])).to eq([user])
    end

    it 'returns users with a matching username regardless of the casing' do
      expect(search_with_secondary_emails(user.username.upcase)).to eq([user])
    end

    it 'returns users with a matching whole secondary email' do
      expect(search_with_secondary_emails(email.email)).to eq([email.user])
    end

    it 'returns users with a matching part of secondary email' do
      expect(search_with_secondary_emails(email.email[1..4])).to eq([email.user])
    end

    it 'return users with a matching part of secondary email regardless of case' do
      expect(search_with_secondary_emails(email.email[1..4].upcase)).to eq([email.user])
      expect(search_with_secondary_emails(email.email[1..4].downcase)).to eq([email.user])
      expect(search_with_secondary_emails(email.email[1..4].capitalize)).to eq([email.user])
    end

    it 'returns multiple users with matching secondary emails' do
      email1 = create(:email, email: '1_testemail@example.com')
      email2 = create(:email, email: '2_testemail@example.com')
      email3 = create(:email, email: 'other@email.com')
      email3.user.update_attributes!(email: 'another@mail.com')

      expect(
        search_with_secondary_emails('testemail@example.com').map(&:id)
      ).to include(email1.user.id, email2.user.id)

      expect(
        search_with_secondary_emails('testemail@example.com').map(&:id)
      ).not_to include(email3.user.id)
    end
  end

  describe '.find_by_ssh_key_id' do
    context 'using an existing SSH key ID' do
      let(:user) { create(:user) }
      let(:key) { create(:key, user: user) }

      it 'returns the corresponding User' do
        expect(described_class.find_by_ssh_key_id(key.id)).to eq(user)
      end
    end

    context 'using an invalid SSH key ID' do
      it 'returns nil' do
        expect(described_class.find_by_ssh_key_id(-1)).to be_nil
      end
    end
  end

  describe '.by_login' do
    let(:username) { 'John' }
    let!(:user) { create(:user, username: username) }

    it 'gets the correct user' do
      expect(User.by_login(user.email.upcase)).to eq user
      expect(User.by_login(user.email)).to eq user
      expect(User.by_login(username.downcase)).to eq user
      expect(User.by_login(username)).to eq user
      expect(User.by_login(nil)).to be_nil
      expect(User.by_login('')).to be_nil
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
    let!(:user) { create(:user) }

    context 'with a route matching the given path' do
      let!(:route) { user.namespace.route }

      it 'returns the user' do
        expect(User.find_by_full_path(route.path)).to eq(user)
      end

      it 'is case-insensitive' do
        expect(User.find_by_full_path(route.path.upcase)).to eq(user)
        expect(User.find_by_full_path(route.path.downcase)).to eq(user)
      end
    end

    context 'with a redirect route matching the given path' do
      let!(:redirect_route) { user.namespace.redirect_routes.create(path: 'foo') }

      context 'without the follow_redirects option' do
        it 'returns nil' do
          expect(User.find_by_full_path(redirect_route.path)).to eq(nil)
        end
      end

      context 'with the follow_redirects option set to true' do
        it 'returns the user' do
          expect(User.find_by_full_path(redirect_route.path, follow_redirects: true)).to eq(user)
        end

        it 'is case-insensitive' do
          expect(User.find_by_full_path(redirect_route.path.upcase, follow_redirects: true)).to eq(user)
          expect(User.find_by_full_path(redirect_route.path.downcase, follow_redirects: true)).to eq(user)
        end
      end
    end

    context 'without a route or a redirect route matching the given path' do
      context 'without the follow_redirects option' do
        it 'returns nil' do
          expect(User.find_by_full_path('unknown')).to eq(nil)
        end
      end
      context 'with the follow_redirects option set to true' do
        it 'returns nil' do
          expect(User.find_by_full_path('unknown', follow_redirects: true)).to eq(nil)
        end
      end
    end

    context 'with a group route matching the given path' do
      context 'when the group namespace has an owner_id (legacy data)' do
        let!(:group) { create(:group, path: 'group_path', owner: user) }

        it 'returns nil' do
          expect(User.find_by_full_path('group_path')).to eq(nil)
        end
      end

      context 'when the group namespace does not have an owner_id' do
        let!(:group) { create(:group, path: 'group_path') }

        it 'returns nil' do
          expect(User.find_by_full_path('group_path')).to eq(nil)
        end
      end
    end
  end

  describe 'all_ssh_keys' do
    it { is_expected.to have_many(:keys).dependent(:destroy) }

    it "has all ssh keys" do
      user = create :user
      key = create :key, key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD33bWLBxu48Sev9Fert1yzEO4WGcWglWF7K/AwblIUFselOt/QdOL9DSjpQGxLagO1s9wl53STIO8qGS4Ms0EJZyIXOEFMjFJ5xmjSy+S37By4sG7SsltQEHMxtbtFOaW5LV2wCrX+rUsRNqLMamZjgjcPO0/EgGCXIGMAYW4O7cwGZdXWYIhQ1Vwy+CsVMDdPkPgBXqK7nR/ey8KMs8ho5fMNgB5hBw/AL9fNGhRw3QTD6Q12Nkhl4VZES2EsZqlpNnJttnPdp847DUsT6yuLRlfiQfz5Cn9ysHFdXObMN5VYIiPFwHeYCZp1X2S4fDZooRE8uOLTfxWHPXwrhqSH", user_id: user.id

      expect(user.all_ssh_keys).to include(a_string_starting_with(key.key))
    end
  end

  describe '#avatar_type' do
    let(:user) { create(:user) }

    it 'is true if avatar is image' do
      user.update_attribute(:avatar, 'uploads/avatar.png')
      expect(user.avatar_type).to be_truthy
    end

    it 'is false if avatar is html page' do
      user.update_attribute(:avatar, 'uploads/avatar.html')
      expect(user.avatar_type).to eq(['only images allowed'])
    end
  end

  describe '#avatar_url' do
    let(:user) { create(:user, :with_avatar) }

    context 'when avatar file is uploaded' do
      let(:gitlab_host) { "http://#{Gitlab.config.gitlab.host}" }
      let(:avatar_path) { "/uploads/-/system/user/avatar/#{user.id}/dk.png" }

      it 'shows correct avatar url' do
        expect(user.avatar_url).to eq(avatar_path)
        expect(user.avatar_url(only_path: false)).to eq([gitlab_host, avatar_path].join)

        allow(ActionController::Base).to receive(:asset_host).and_return(gitlab_host)

        expect(user.avatar_url).to eq([gitlab_host, avatar_path].join)
      end

      context 'when in a geo secondary node' do
        let(:geo_host) { 'http://geo.example.com' }
        let(:geo_avatar_url) { [geo_host, avatar_path].join }

        before do
          allow(Gitlab::Geo).to receive(:secondary?) { true }
          allow(Gitlab::Geo).to receive_message_chain(:primary_node, :url) { geo_host }
        end

        it 'shows correct avatar url' do
          expect(user.avatar_url).to eq(geo_avatar_url)
          expect(user.avatar_url(only_path: false)).to eq(geo_avatar_url)

          allow(ActionController::Base).to receive(:asset_host).and_return(geo_host)

          expect(user.avatar_url).to eq(geo_avatar_url)
        end
      end
    end
  end

  describe '#requires_ldap_check?' do
    let(:user) { User.new }

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
        user = create :omniauth_user
        expect(user.ldap_identity.provider).not_to be_empty
      end
    end

    describe '#ldap_block' do
      let(:user) { create(:omniauth_user, provider: 'ldapmain', name: 'John Smith') }

      it 'blocks user flaging the action caming from ldap' do
        user.ldap_block
        expect(user.blocked?).to be_truthy
        expect(user.ldap_blocked?).to be_truthy
      end
    end
  end

  describe '#full_website_url' do
    let(:user) { create(:user) }

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
    let(:user) { create(:user) }

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
    let(:user) { build(:user, name: 'test & user', skype: 'test&user') }

    it 'encodes HTML entities in the Skype attribute' do
      expect { user.sanitize_attrs }.to change { user.skype }.to('test&amp;user')
    end

    it 'does not encode HTML entities in the name attribute' do
      expect { user.sanitize_attrs }.not_to change { user.name }
    end
  end

  describe '#starred?' do
    it 'determines if user starred a project' do
      user = create :user
      project1 = create(:empty_project, :public)
      project2 = create(:empty_project, :public)

      expect(user.starred?(project1)).to be_falsey
      expect(user.starred?(project2)).to be_falsey

      star1 = UsersStarProject.create!(project: project1, user: user)
      expect(user.starred?(project1)).to be_truthy
      expect(user.starred?(project2)).to be_falsey

      star2 = UsersStarProject.create!(project: project2, user: user)
      expect(user.starred?(project1)).to be_truthy
      expect(user.starred?(project2)).to be_truthy

      star1.destroy
      expect(user.starred?(project1)).to be_falsey
      expect(user.starred?(project2)).to be_truthy

      star2.destroy
      expect(user.starred?(project1)).to be_falsey
      expect(user.starred?(project2)).to be_falsey
    end
  end

  describe '#toggle_star' do
    it 'toggles stars' do
      user = create :user
      project = create(:empty_project, :public)

      expect(user.starred?(project)).to be_falsey
      user.toggle_star(project)
      expect(user.starred?(project)).to be_truthy
      user.toggle_star(project)
      expect(user.starred?(project)).to be_falsey
    end
  end

  describe "#existing_member?" do
    it "returns true for exisitng user" do
      create :user, email: "bruno@example.com"

      expect(User.existing_member?("bruno@example.com")).to be_truthy
    end

    it "returns false for unknown exisitng user" do
      create :user, email: "bruno@example.com"

      expect(User.existing_member?("rendom@example.com")).to be_falsey
    end

    it "returns true if additional email exists" do
      user = create :user
      user.emails.create(email: "bruno@example.com")

      expect(User.existing_member?("bruno@example.com")).to be_truthy
    end
  end

  describe '#sort' do
    before do
      User.delete_all
      @user = create :user, created_at: Date.today, last_sign_in_at: Date.today, name: 'Alpha'
      @user1 = create :user, created_at: Date.today - 1, last_sign_in_at: Date.today - 1, name: 'Omega'
      @user2 = create :user, created_at: Date.today - 2, last_sign_in_at: nil, name: 'Beta'
    end

    context 'when sort by recent_sign_in' do
      it 'sorts users by the recent sign-in time' do
        expect(User.sort('recent_sign_in').first).to eq(@user)
      end

      it 'pushes users who never signed in to the end' do
        expect(User.sort('recent_sign_in').third).to eq(@user2)
      end
    end

    context 'when sort by oldest_sign_in' do
      it 'sorts users by the oldest sign-in time' do
        expect(User.sort('oldest_sign_in').first).to eq(@user1)
      end

      it 'pushes users who never signed in to the end' do
        expect(User.sort('oldest_sign_in').third).to eq(@user2)
      end
    end

    it 'sorts users in descending order by their creation time' do
      expect(User.sort('created_desc').first).to eq(@user)
    end

    it 'sorts users in ascending order by their creation time' do
      expect(User.sort('created_asc').first).to eq(@user2)
    end

    it 'sorts users by id in descending order when nil is passed' do
      expect(User.sort(nil).first).to eq(@user2)
    end
  end

  describe "#contributed_projects" do
    subject { create(:user) }
    let!(:project1) { create(:empty_project) }
    let!(:project2) { create(:empty_project, forked_from_project: project3) }
    let!(:project3) { create(:empty_project) }
    let!(:merge_request) { create(:merge_request, source_project: project2, target_project: project3, author: subject) }
    let!(:push_event) { create(:event, :pushed, project: project1, target: project1, author: subject) }
    let!(:merge_event) { create(:event, :created, project: project3, target: merge_request, author: subject) }

    before do
      project1.team << [subject, :master]
      project2.team << [subject, :master]
    end

    it "includes IDs for projects the user has pushed to" do
      expect(subject.contributed_projects).to include(project1)
    end

    it "includes IDs for projects the user has had merge requests merged into" do
      expect(subject.contributed_projects).to include(project3)
    end

    it "doesn't include IDs for unrelated projects" do
      expect(subject.contributed_projects).not_to include(project2)
    end
  end

  describe '#can_be_removed?' do
    subject { create(:user) }

    context 'no owned groups' do
      it { expect(subject.can_be_removed?).to be_truthy }
    end

    context 'has owned groups' do
      before do
        group = create(:group)
        group.add_owner(subject)
      end

      it { expect(subject.can_be_removed?).to be_falsey }
    end
  end

  describe "#recent_push" do
    subject { create(:user) }
    let!(:project1) { create(:project, :repository) }
    let!(:project2) { create(:project, :repository, forked_from_project: project1) }
    let!(:push_data) do
      Gitlab::DataBuilder::Push.build_sample(project2, subject)
    end
    let!(:push_event) { create(:event, :pushed, project: project2, target: project1, author: subject, data: push_data) }

    before do
      project1.team << [subject, :master]
      project2.team << [subject, :master]
    end

    it "includes push event" do
      expect(subject.recent_push).to eq(push_event)
    end

    it "excludes push event if branch has been deleted" do
      allow_any_instance_of(Repository).to receive(:branch_names).and_return(['foo'])

      expect(subject.recent_push).to eq(nil)
    end

    it "excludes push event if MR is opened for it" do
      create(:merge_request, source_project: project2, target_project: project1, source_branch: project2.default_branch, target_branch: 'fix', author: subject)

      expect(subject.recent_push).to eq(nil)
    end

    it "includes push events on any of the provided projects" do
      expect(subject.recent_push(project1)).to eq(nil)
      expect(subject.recent_push(project2)).to eq(push_event)

      push_data1 = Gitlab::DataBuilder::Push.build_sample(project1, subject)
      push_event1 = create(:event, :pushed, project: project1, target: project1, author: subject, data: push_data1)

      expect(subject.recent_push([project1, project2])).to eq(push_event1) # Newest
    end
  end

  describe '#authorized_groups' do
    let!(:user) { create(:user) }
    let!(:private_group) { create(:group) }

    before do
      private_group.add_user(user, Gitlab::Access::MASTER)
    end

    subject { user.authorized_groups }

    it { is_expected.to eq([private_group]) }
  end

  describe '#authorized_projects', truncate: true do
    context 'with a minimum access level' do
      it 'includes projects for which the user is an owner' do
        user = create(:user)
        project = create(:empty_project, :private, namespace: user.namespace)

        expect(user.authorized_projects(Gitlab::Access::REPORTER))
          .to contain_exactly(project)
      end

      it 'includes projects for which the user is a master' do
        user = create(:user)
        project = create(:empty_project, :private)

        project.team << [user, Gitlab::Access::MASTER]

        expect(user.authorized_projects(Gitlab::Access::REPORTER))
          .to contain_exactly(project)
      end
    end

    it "includes user's personal projects" do
      user    = create(:user)
      project = create(:empty_project, :private, namespace: user.namespace)

      expect(user.authorized_projects).to include(project)
    end

    it "includes personal projects user has been given access to" do
      user1   = create(:user)
      user2   = create(:user)
      project = create(:empty_project, :private, namespace: user1.namespace)

      project.team << [user2, Gitlab::Access::DEVELOPER]

      expect(user2.authorized_projects).to include(project)
    end

    it "includes projects of groups user has been added to" do
      group   = create(:group)
      project = create(:empty_project, group: group)
      user    = create(:user)

      group.add_developer(user)

      expect(user.authorized_projects).to include(project)
    end

    it "does not include projects of groups user has been removed from" do
      group   = create(:group)
      project = create(:empty_project, group: group)
      user    = create(:user)

      member = group.add_developer(user)
      expect(user.authorized_projects).to include(project)

      member.destroy
      expect(user.authorized_projects).not_to include(project)
    end

    it "includes projects shared with user's group" do
      user    = create(:user)
      project = create(:empty_project, :private)
      group   = create(:group)

      group.add_reporter(user)
      project.project_group_links.create(group: group)

      expect(user.authorized_projects).to include(project)
    end

    it "does not include destroyed projects user had access to" do
      user1   = create(:user)
      user2   = create(:user)
      project = create(:empty_project, :private, namespace: user1.namespace)

      project.team << [user2, Gitlab::Access::DEVELOPER]
      expect(user2.authorized_projects).to include(project)

      project.destroy
      expect(user2.authorized_projects).not_to include(project)
    end

    it "does not include projects of destroyed groups user had access to" do
      group   = create(:group)
      project = create(:empty_project, namespace: group)
      user    = create(:user)

      group.add_developer(user)
      expect(user.authorized_projects).to include(project)

      group.destroy
      expect(user.authorized_projects).not_to include(project)
    end
  end

  describe '#projects_where_can_admin_issues' do
    let(:user) { create(:user) }

    it 'includes projects for which the user access level is above or equal to reporter' do
      reporter_project  = create(:empty_project) { |p| p.add_reporter(user) }
      developer_project = create(:empty_project) { |p| p.add_developer(user) }
      master_project    = create(:empty_project) { |p| p.add_master(user) }

      expect(user.projects_where_can_admin_issues.to_a).to eq([master_project, developer_project, reporter_project])
      expect(user.can?(:admin_issue, master_project)).to eq(true)
      expect(user.can?(:admin_issue, developer_project)).to eq(true)
      expect(user.can?(:admin_issue, reporter_project)).to eq(true)
    end

    it 'does not include for which the user access level is below reporter' do
      project = create(:empty_project)
      guest_project = create(:empty_project) { |p| p.add_guest(user) }

      expect(user.projects_where_can_admin_issues.to_a).to be_empty
      expect(user.can?(:admin_issue, guest_project)).to eq(false)
      expect(user.can?(:admin_issue, project)).to eq(false)
    end

    it 'does not include archived projects' do
      project = create(:empty_project, :archived)

      expect(user.projects_where_can_admin_issues.to_a).to be_empty
      expect(user.can?(:admin_issue, project)).to eq(false)
    end

    it 'does not include projects for which issues are disabled' do
      project = create(:empty_project, :issues_disabled)

      expect(user.projects_where_can_admin_issues.to_a).to be_empty
      expect(user.can?(:admin_issue, project)).to eq(false)
    end
  end

  describe '#ci_authorized_runners' do
    let(:user) { create(:user) }
    let(:runner) { create(:ci_runner) }

    before do
      project.runners << runner
    end

    context 'without any projects' do
      let(:project) { create(:empty_project) }

      it 'does not load' do
        expect(user.ci_authorized_runners).to be_empty
      end
    end

    context 'with personal projects runners' do
      let(:namespace) { create(:namespace, owner: user) }
      let(:project) { create(:empty_project, namespace: namespace) }

      it 'loads' do
        expect(user.ci_authorized_runners).to contain_exactly(runner)
      end
    end

    shared_examples :member do
      context 'when the user is a master' do
        before do
          add_user(Gitlab::Access::MASTER)
        end

        it 'loads' do
          expect(user.ci_authorized_runners).to contain_exactly(runner)
        end
      end

      context 'when the user is a developer' do
        before do
          add_user(Gitlab::Access::DEVELOPER)
        end

        it 'does not load' do
          expect(user.ci_authorized_runners).to be_empty
        end
      end
    end

    context 'with groups projects runners' do
      let(:group) { create(:group) }
      let(:project) { create(:empty_project, group: group) }

      def add_user(access)
        group.add_user(user, access)
      end

      it_behaves_like :member
    end

    context 'with other projects runners' do
      let(:project) { create(:empty_project) }

      def add_user(access)
        project.team << [user, access]
      end

      it_behaves_like :member
    end
  end

  describe '#projects_with_reporter_access_limited_to' do
    let(:project1) { create(:empty_project) }
    let(:project2) { create(:empty_project) }
    let(:user) { create(:user) }

    before do
      project1.team << [user, :reporter]
      project2.team << [user, :guest]
    end

    it 'returns the projects when using a single project ID' do
      projects = user.projects_with_reporter_access_limited_to(project1.id)

      expect(projects).to eq([project1])
    end

    it 'returns the projects when using an Array of project IDs' do
      projects = user.projects_with_reporter_access_limited_to([project1.id])

      expect(projects).to eq([project1])
    end

    it 'returns the projects when using an ActiveRecord relation' do
      projects = user
        .projects_with_reporter_access_limited_to(Project.select(:id))

      expect(projects).to eq([project1])
    end

    it 'does not return projects you do not have reporter access to' do
      projects = user.projects_with_reporter_access_limited_to(project2.id)

      expect(projects).to be_empty
    end
  end

  describe '#all_expanded_groups' do
    # foo/bar would also match foo/barbaz instead of just foo/bar and foo/bar/baz
    let!(:user) { create(:user) }

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
    let!(:group) { create :group }
    let!(:nested_group_1) { create :group, parent: group, name: 'bar' }
    let!(:nested_group_1_1) { create :group, parent: nested_group_1, name: 'baz' }
    let!(:nested_group_2) { create :group, parent: group, name: 'barbaz' }
    let!(:nested_group_2_1) { create :group, parent: nested_group_2, name: 'baz' }

    subject { user.all_expanded_groups }

    context 'user is not a member of any group' do
      it 'returns an empty array' do
        is_expected.to eq([])
      end
    end

    context 'user is member of all groups' do
      before do
        group.add_owner(user)
        nested_group_1.add_owner(user)
        nested_group_1_1.add_owner(user)
        nested_group_2.add_owner(user)
        nested_group_2_1.add_owner(user)
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
      before do
        group.add_owner(user)
      end

      if Group.supports_nested_groups?
        it 'returns all groups' do
          is_expected.to match_array [
            group,
            nested_group_1, nested_group_1_1,
            nested_group_2, nested_group_2_1
          ]
        end
      else
        it 'returns the top-level groups' do
          is_expected.to match_array [group]
        end
      end
    end

    context 'user is member of the first child (internal node), branch 1', :nested_groups do
      before do
        nested_group_1.add_owner(user)
      end

      it 'returns the groups in the hierarchy' do
        is_expected.to match_array [
          group,
          nested_group_1, nested_group_1_1
        ]
      end
    end

    context 'user is member of the first child (internal node), branch 2', :nested_groups do
      before do
        nested_group_2.add_owner(user)
      end

      it 'returns the groups in the hierarchy' do
        is_expected.to match_array [
          group,
          nested_group_2, nested_group_2_1
        ]
      end
    end

    context 'user is member of the last child (leaf node)', :nested_groups do
      before do
        nested_group_1_1.add_owner(user)
      end

      it 'returns the groups in the hierarchy' do
        is_expected.to match_array [
          group,
          nested_group_1, nested_group_1_1
        ]
      end
    end
  end

  describe '#refresh_authorized_projects', clean_gitlab_redis_shared_state: true do
    let(:project1) { create(:empty_project) }
    let(:project2) { create(:empty_project) }
    let(:user) { create(:user) }

    before do
      project1.team << [user, :reporter]
      project2.team << [user, :guest]

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

    it "accepts string values in addition to symbols" do
      user.access_level = 'admin'

      expect(user.access_level).to eq(:admin)
      expect(user.admin).to be true
    end
  end

  describe '#full_private_access?' do
    it 'returns false for regular user' do
      user = build(:user)

      expect(user.full_private_access?).to be_falsy
    end

    it 'returns true for admin user' do
      user = build(:user, :admin)

      expect(user.full_private_access?).to be_truthy
    end
  end

  describe 'the GitLab_Auditor_User add-on' do
    context 'creating an auditor user' do
      it "does not allow creating an auditor user if the addon isn't enabled" do
        stub_licensed_features(auditor_user: false)

        expect(build(:user, :auditor)).to be_invalid
      end

      it "does not allow creating an auditor user if no license is present" do
        allow(License).to receive(:current).and_return nil

        expect(build(:user, :auditor)).to be_invalid
      end

      it "allows creating an auditor user if the addon is enabled" do
        stub_licensed_features(auditor_user: true)

        expect(build(:user, :auditor)).to be_valid
      end

      it "allows creating a regular user if the addon isn't enabled" do
        stub_licensed_features(auditor_user: false)

        expect(build(:user)).to be_valid
      end
    end

    context '#auditor?' do
      it "returns true for an auditor user if the addon is enabled" do
        stub_licensed_features(auditor_user: true)

        expect(build(:user, :auditor)).to be_auditor
      end

      it "returns false for an auditor user if the addon is not enabled" do
        stub_licensed_features(auditor_user: false)

        expect(build(:user, :auditor)).not_to be_auditor
      end

      it "returns false for an auditor user if a license is not present" do
        stub_licensed_features(auditor_user: false)

        expect(build(:user, :auditor)).not_to be_auditor
      end

      it "returns false for a non-auditor user even if the addon is present" do
        stub_licensed_features(auditor_user: true)

        expect(build(:user)).not_to be_auditor
      end
    end
  end

  describe '.ghost' do
    it "creates a ghost user if one isn't already present" do
      ghost = User.ghost

      expect(ghost).to be_ghost
      expect(ghost).to be_persisted
    end

    it "does not create a second ghost user if one is already present" do
      expect do
        User.ghost
        User.ghost
      end.to change { User.count }.by(1)
      expect(User.ghost).to eq(User.ghost)
    end

    context "when a regular user exists with the username 'ghost'" do
      it "creates a ghost user with a non-conflicting username" do
        create(:user, username: 'ghost')
        ghost = User.ghost

        expect(ghost).to be_persisted
        expect(ghost.username).to eq('ghost1')
      end
    end

    context "when a regular user exists with the email 'ghost@example.com'" do
      it "creates a ghost user with a non-conflicting email" do
        create(:user, email: 'ghost@example.com')
        ghost = User.ghost

        expect(ghost).to be_persisted
        expect(ghost.email).to eq('ghost1@example.com')
      end
    end

    context 'when a domain whitelist is in place' do
      before do
        stub_application_setting(domain_whitelist: ['gitlab.com'])
      end

      it 'creates a ghost user' do
        expect(User.ghost).to be_persisted
      end
    end
  end

  describe '#update_two_factor_requirement' do
    let(:user) { create :user }

    context 'with 2FA requirement on groups' do
      let(:group1) { create :group, require_two_factor_authentication: true, two_factor_grace_period: 23 }
      let(:group2) { create :group, require_two_factor_authentication: true, two_factor_grace_period: 32 }

      before do
        group1.add_user(user, GroupMember::OWNER)
        group2.add_user(user, GroupMember::OWNER)

        user.update_two_factor_requirement
      end

      it 'requires 2FA' do
        expect(user.require_two_factor_authentication_from_group).to be true
      end

      it 'uses the shortest grace period' do
        expect(user.two_factor_grace_period).to be 23
      end
    end

    context 'with 2FA requirement on nested parent group', :nested_groups do
      let!(:group1) { create :group, require_two_factor_authentication: true }
      let!(:group1a) { create :group, require_two_factor_authentication: false, parent: group1 }

      before do
        group1a.add_user(user, GroupMember::OWNER)

        user.update_two_factor_requirement
      end

      it 'requires 2FA' do
        expect(user.require_two_factor_authentication_from_group).to be true
      end
    end

    context 'with 2FA requirement on nested child group', :nested_groups do
      let!(:group1) { create :group, require_two_factor_authentication: false }
      let!(:group1a) { create :group, require_two_factor_authentication: true, parent: group1 }

      before do
        group1.add_user(user, GroupMember::OWNER)

        user.update_two_factor_requirement
      end

      it 'requires 2FA' do
        expect(user.require_two_factor_authentication_from_group).to be true
      end
    end

    context 'without 2FA requirement on groups' do
      let(:group) { create :group }

      before do
        group.add_user(user, GroupMember::OWNER)

        user.update_two_factor_requirement
      end

      it 'does not require 2FA' do
        expect(user.require_two_factor_authentication_from_group).to be false
      end

      it 'falls back to the default grace period' do
        expect(user.two_factor_grace_period).to be 48
      end
    end
  end

  context '.active' do
    before do
      User.ghost
      create(:user, name: 'user', state: 'active')
      create(:user, name: 'user', state: 'blocked')
    end

    it 'only counts active and non internal users' do
      expect(User.active.count).to eq(1)
    end
  end

  describe 'preferred language' do
    it 'is English by default' do
      user = create(:user)

      expect(user.preferred_language).to eq('en')
    end
  end

  context '#invalidate_issue_cache_counts' do
    let(:user) { build_stubbed(:user) }

    it 'invalidates cache for issue counter' do
      cache_mock = double

      expect(cache_mock).to receive(:delete).with(['users', user.id, 'assigned_open_issues_count'])

      allow(Rails).to receive(:cache).and_return(cache_mock)

      user.invalidate_issue_cache_counts
    end
  end

  context '#invalidate_merge_request_cache_counts' do
    let(:user) { build_stubbed(:user) }

    it 'invalidates cache for Merge Request counter' do
      cache_mock = double

      expect(cache_mock).to receive(:delete).with(['users', user.id, 'assigned_open_merge_requests_count'])

      allow(Rails).to receive(:cache).and_return(cache_mock)

      user.invalidate_merge_request_cache_counts
    end
  end

  describe '#allow_password_authentication?' do
    context 'regular user' do
      let(:user) { build(:user) }

      it 'returns true when sign-in is enabled' do
        expect(user.allow_password_authentication?).to be_truthy
      end

      it 'returns false when sign-in is disabled' do
        stub_application_setting(password_authentication_enabled: false)

        expect(user.allow_password_authentication?).to be_falsey
      end
    end

    it 'returns false for ldap user' do
      user = create(:omniauth_user, provider: 'ldapmain')

      expect(user.allow_password_authentication?).to be_falsey
    end
  end
end
