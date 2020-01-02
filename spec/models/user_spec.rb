# frozen_string_literal: true

require 'spec_helper'

describe User, :do_not_mock_admin_mode do
  include ProjectForksHelper
  include TermsHelper

  it_behaves_like 'having unique enum values'

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Gitlab::ConfigHelper) }
    it { is_expected.to include_module(Referable) }
    it { is_expected.to include_module(Sortable) }
    it { is_expected.to include_module(TokenAuthenticatable) }
    it { is_expected.to include_module(BlocksJsonSerialization) }
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:path).to(:namespace).with_prefix }
  end

  describe 'associations' do
    it { is_expected.to have_one(:namespace) }
    it { is_expected.to have_one(:status) }
    it { is_expected.to have_many(:snippets).dependent(:destroy) }
    it { is_expected.to have_many(:members) }
    it { is_expected.to have_many(:project_members) }
    it { is_expected.to have_many(:group_members) }
    it { is_expected.to have_many(:groups) }
    it { is_expected.to have_many(:keys).dependent(:destroy) }
    it { is_expected.to have_many(:deploy_keys).dependent(:nullify) }
    it { is_expected.to have_many(:events).dependent(:delete_all) }
    it { is_expected.to have_many(:issues).dependent(:destroy) }
    it { is_expected.to have_many(:notes).dependent(:destroy) }
    it { is_expected.to have_many(:merge_requests).dependent(:destroy) }
    it { is_expected.to have_many(:identities).dependent(:destroy) }
    it { is_expected.to have_many(:spam_logs).dependent(:destroy) }
    it { is_expected.to have_many(:todos) }
    it { is_expected.to have_many(:award_emoji).dependent(:destroy) }
    it { is_expected.to have_many(:triggers).dependent(:destroy) }
    it { is_expected.to have_many(:builds).dependent(:nullify) }
    it { is_expected.to have_many(:pipelines).dependent(:nullify) }
    it { is_expected.to have_many(:chat_names).dependent(:destroy) }
    it { is_expected.to have_many(:uploads) }
    it { is_expected.to have_many(:reported_abuse_reports).dependent(:destroy).class_name('AbuseReport') }
    it { is_expected.to have_many(:custom_attributes).class_name('UserCustomAttribute') }
    it { is_expected.to have_many(:releases).dependent(:nullify) }

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

  describe 'validations' do
    describe 'name' do
      it { is_expected.to validate_presence_of(:name) }
      it { is_expected.to validate_length_of(:name).is_at_most(128) }
    end

    describe 'first name' do
      it { is_expected.to validate_length_of(:first_name).is_at_most(255) }
    end

    describe 'last name' do
      it { is_expected.to validate_length_of(:last_name).is_at_most(255) }
    end

    describe 'username' do
      it 'validates presence' do
        expect(subject).to validate_presence_of(:username)
      end

      it 'rejects blacklisted names' do
        user = build(:user, username: 'dashboard')

        expect(user).not_to be_valid
        expect(user.errors.messages[:username]).to eq ['dashboard is a reserved name']
      end

      it 'allows child names' do
        user = build(:user, username: 'avatar')

        expect(user).to be_valid
      end

      it 'allows wildcard names' do
        user = build(:user, username: 'blob')

        expect(user).to be_valid
      end

      context 'when username is changed' do
        let(:user) { build_stubbed(:user, username: 'old_path', namespace: build_stubbed(:namespace)) }

        it 'validates move_dir is allowed for the namespace' do
          expect(user.namespace).to receive(:any_project_has_container_registry_tags?).and_return(true)
          user.username = 'new_path'
          expect(user).to be_invalid
          expect(user.errors.messages[:username].first).to match('cannot be changed if a personal project has container registry tags')
        end
      end

      context 'when the username is in use by another user' do
        let(:username) { 'foo' }
        let!(:other_user) { create(:user, username: username) }

        it 'is invalid' do
          user = build(:user, username: username)

          expect(user).not_to be_valid
          expect(user.errors.full_messages).to eq(['Username has already been taken'])
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

    describe '#commit_email' do
      subject(:user) { create(:user) }

      it 'defaults to the primary email' do
        expect(user.email).to be_present
        expect(user.commit_email).to eq(user.email)
      end

      it 'defaults to the primary email when the column in the database is null' do
        user.update_column(:commit_email, nil)

        found_user = described_class.find_by(id: user.id)

        expect(found_user.commit_email).to eq(user.email)
      end

      it 'returns the private commit email when commit_email has _private' do
        user.update_column(:commit_email, Gitlab::PrivateCommitEmail::TOKEN)

        expect(user.commit_email).to eq(user.private_commit_email)
      end

      it 'can be set to a confirmed email' do
        confirmed = create(:email, :confirmed, user: user)
        user.commit_email = confirmed.email

        expect(user).to be_valid
        expect(user.commit_email).to eq(confirmed.email)
      end

      it 'can not be set to an unconfirmed email' do
        unconfirmed = create(:email, user: user)
        user.commit_email = unconfirmed.email

        # This should set the commit_email attribute to the primary email
        expect(user).to be_valid
        expect(user.commit_email).to eq(user.email)
      end

      it 'can not be set to a non-existent email' do
        user.commit_email = 'non-existent-email@nonexistent.nonexistent'

        # This should set the commit_email attribute to the primary email
        expect(user).to be_valid
        expect(user.commit_email).to eq(user.email)
      end

      it 'can not be set to an invalid email, even if confirmed' do
        confirmed = create(:email, :confirmed, :skip_validate, user: user, email: 'invalid')
        user.commit_email = confirmed.email

        expect(user).not_to be_valid
      end
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

      context 'set_commit_email' do
        it 'keeps commit email when private commit email is being used' do
          user = create(:user, commit_email: Gitlab::PrivateCommitEmail::TOKEN)

          expect(user.read_attribute(:commit_email)).to eq(Gitlab::PrivateCommitEmail::TOKEN)
        end

        it 'keeps the commit email when nil' do
          user = create(:user, commit_email: nil)

          expect(user.read_attribute(:commit_email)).to be_nil
        end

        it 'reverts to nil when email is not verified' do
          user = create(:user, commit_email: "foo@bar.com")

          expect(user.read_attribute(:commit_email)).to be_nil
        end
      end

      context 'owns_commit_email' do
        it 'accepts private commit email' do
          user = build(:user, commit_email: Gitlab::PrivateCommitEmail::TOKEN)

          expect(user).to be_valid
        end

        it 'accepts nil commit email' do
          user = build(:user, commit_email: nil)

          expect(user).to be_valid
        end
      end
    end
  end

  describe "scopes" do
    describe ".with_two_factor" do
      it "returns users with 2fa enabled via OTP" do
        user_with_2fa = create(:user, :two_factor_via_otp)
        user_without_2fa = create(:user)
        users_with_two_factor = described_class.with_two_factor.pluck(:id)

        expect(users_with_two_factor).to include(user_with_2fa.id)
        expect(users_with_two_factor).not_to include(user_without_2fa.id)
      end

      it "returns users with 2fa enabled via U2F" do
        user_with_2fa = create(:user, :two_factor_via_u2f)
        user_without_2fa = create(:user)
        users_with_two_factor = described_class.with_two_factor.pluck(:id)

        expect(users_with_two_factor).to include(user_with_2fa.id)
        expect(users_with_two_factor).not_to include(user_without_2fa.id)
      end

      it "returns users with 2fa enabled via OTP and U2F" do
        user_with_2fa = create(:user, :two_factor_via_otp, :two_factor_via_u2f)
        user_without_2fa = create(:user)
        users_with_two_factor = described_class.with_two_factor.pluck(:id)

        expect(users_with_two_factor).to eq([user_with_2fa.id])
        expect(users_with_two_factor).not_to include(user_without_2fa.id)
      end

      it 'works with ORDER BY' do
        user_with_2fa = create(:user, :two_factor_via_otp, :two_factor_via_u2f)

        expect(described_class
          .with_two_factor
          .reorder_by_name).to eq([user_with_2fa])
      end
    end

    describe ".without_two_factor" do
      it "excludes users with 2fa enabled via OTP" do
        user_with_2fa = create(:user, :two_factor_via_otp)
        user_without_2fa = create(:user)
        users_without_two_factor = described_class.without_two_factor.pluck(:id)

        expect(users_without_two_factor).to include(user_without_2fa.id)
        expect(users_without_two_factor).not_to include(user_with_2fa.id)
      end

      it "excludes users with 2fa enabled via U2F" do
        user_with_2fa = create(:user, :two_factor_via_u2f)
        user_without_2fa = create(:user)
        users_without_two_factor = described_class.without_two_factor.pluck(:id)

        expect(users_without_two_factor).to include(user_without_2fa.id)
        expect(users_without_two_factor).not_to include(user_with_2fa.id)
      end

      it "excludes users with 2fa enabled via OTP and U2F" do
        user_with_2fa = create(:user, :two_factor_via_otp, :two_factor_via_u2f)
        user_without_2fa = create(:user)
        users_without_two_factor = described_class.without_two_factor.pluck(:id)

        expect(users_without_two_factor).to include(user_without_2fa.id)
        expect(users_without_two_factor).not_to include(user_with_2fa.id)
      end
    end

    describe '.limit_to_todo_authors' do
      context 'when filtering by todo authors' do
        let(:user1) { create(:user) }
        let(:user2) { create(:user) }

        before do
          create(:todo, user: user1, author: user1, state: :done)
          create(:todo, user: user2, author: user2, state: :pending)
        end

        it 'only returns users that have authored todos' do
          users = described_class.limit_to_todo_authors(
            user: user2,
            with_todos: true,
            todo_state: :pending
          )

          expect(users).to eq([user2])
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
          user1 = create(:user)
          user2 = create(:user)
          rel = described_class.limit_to_todo_authors(user: user1)

          expect(rel).to include(user1, user2)
        end
      end

      context 'when no user is provided' do
        it 'returns the input relation' do
          user1 = create(:user)
          user2 = create(:user)
          rel = described_class.limit_to_todo_authors

          expect(rel).to include(user1, user2)
        end
      end
    end

    describe '.by_username' do
      it 'finds users regardless of the case passed' do
        user = create(:user, username: 'CaMeLcAsEd')
        user2 = create(:user, username: 'UPPERCASE')

        expect(described_class.by_username(%w(CAMELCASED uppercase)))
          .to contain_exactly(user, user2)
      end

      it 'finds a single user regardless of the case passed' do
        user = create(:user, username: 'CaMeLcAsEd')

        expect(described_class.by_username('CAMELCASED'))
          .to contain_exactly(user)
      end
    end
  end

  describe "Respond to" do
    it { is_expected.to respond_to(:admin?) }
    it { is_expected.to respond_to(:name) }
    it { is_expected.to respond_to(:external?) }
  end

  describe 'before save hook' do
    context '#default_private_profile_to_false' do
      let(:user) { create(:user, private_profile: true) }

      it 'converts nil to false' do
        user.private_profile = nil
        user.save!

        expect(user.private_profile).to eq false
      end
    end

    context 'when saving an external user' do
      let(:user)          { create(:user) }
      let(:external_user) { create(:user, external: true) }

      it "sets other properties aswell" do
        expect(external_user.can_create_team).to be_falsey
        expect(external_user.can_create_group).to be_falsey
        expect(external_user.projects_limit).to be 0
      end
    end

    describe '#check_for_verified_email' do
      let(:user)      { create(:user) }
      let(:secondary) { create(:email, :confirmed, email: 'secondary@example.com', user: user) }

      it 'allows a verfied secondary email to be used as the primary without needing reconfirmation' do
        user.update!(email: secondary.email)
        user.reload
        expect(user.email).to eq secondary.email
        expect(user.unconfirmed_email).to eq nil
        expect(user.confirmed?).to be_truthy
      end
    end
  end

  describe 'after commit hook' do
    describe '#update_emails_with_primary_email' do
      before do
        @user = create(:user, email: 'primary@example.com').tap do |user|
          user.skip_reconfirmation!
        end
        @secondary = create :email, email: 'secondary@example.com', user: @user
        @user.reload
      end

      it 'gets called when email updated' do
        expect(@user).to receive(:update_emails_with_primary_email)

        @user.update!(email: 'new_primary@example.com')
      end

      it 'adds old primary to secondary emails when secondary is a new email ' do
        @user.update!(email: 'new_primary@example.com')
        @user.reload

        expect(@user.emails.count).to eq 2
        expect(@user.emails.pluck(:email)).to match_array([@secondary.email, 'primary@example.com'])
      end

      it 'adds old primary to secondary emails if secondary is becoming a primary' do
        @user.update!(email: @secondary.email)
        @user.reload

        expect(@user.emails.count).to eq 1
        expect(@user.emails.first.email).to eq 'primary@example.com'
      end

      it 'transfers old confirmation values into new secondary' do
        @user.update!(email: @secondary.email)
        @user.reload

        expect(@user.emails.count).to eq 1
        expect(@user.emails.first.confirmed_at).not_to eq nil
      end
    end

    describe '#update_notification_email' do
      # Regression: https://gitlab.com/gitlab-org/gitlab-foss/issues/22846
      context 'when changing :email' do
        let(:user) { create(:user) }
        let(:new_email) { 'new-email@example.com' }

        it 'sets :unconfirmed_email' do
          expect do
            user.tap { |u| u.update!(email: new_email) }.reload
          end.to change(user, :unconfirmed_email).to(new_email)
        end

        it 'does not change :notification_email' do
          expect do
            user.tap { |u| u.update!(email: new_email) }.reload
          end.not_to change(user, :notification_email)
        end

        it 'updates :notification_email to the new email once confirmed' do
          user.update!(email: new_email)

          expect do
            user.tap(&:confirm).reload
          end.to change(user, :notification_email).to eq(new_email)
        end

        context 'and :notification_email is set to a secondary email' do
          let!(:email_attrs) { attributes_for(:email, :confirmed, user: user) }
          let(:secondary) { create(:email, :confirmed, email: 'secondary@example.com', user: user) }

          before do
            user.emails.create(email_attrs)
            user.tap { |u| u.update!(notification_email: email_attrs[:email]) }.reload
          end

          it 'does not change :notification_email to :email' do
            expect do
              user.tap { |u| u.update!(email: new_email) }.reload
            end.not_to change(user, :notification_email)
          end

          it 'does not change :notification_email to :email once confirmed' do
            user.update!(email: new_email)

            expect do
              user.tap(&:confirm).reload
            end.not_to change(user, :notification_email)
          end
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
    let(:user) { create(:user, name: 'Kane Martin William') }

    it 'derives first name from full name, if not present' do
      expect(user.first_name).to eq('Kane')
    end

    it 'derives last name from full name, if not present' do
      expect(user.last_name).to eq('Martin William')
    end
  end

  describe '#highest_role' do
    let(:user) { create(:user) }

    let(:group) { create(:group) }

    it 'returns NO_ACCESS if none has been set' do
      expect(user.highest_role).to eq(Gitlab::Access::NO_ACCESS)
    end

    it 'returns MAINTAINER if user is maintainer of a project' do
      create(:project, group: group) do |project|
        project.add_maintainer(user)
      end

      expect(user.highest_role).to eq(Gitlab::Access::MAINTAINER)
    end

    it 'returns the highest role if user is member of multiple projects' do
      create(:project, group: group) do |project|
        project.add_maintainer(user)
      end

      create(:project, group: group) do |project|
        project.add_developer(user)
      end

      expect(user.highest_role).to eq(Gitlab::Access::MAINTAINER)
    end

    it 'returns MAINTAINER if user is maintainer of a group' do
      create(:group) do |group|
        group.add_user(user, GroupMember::MAINTAINER)
      end

      expect(user.highest_role).to eq(Gitlab::Access::MAINTAINER)
    end

    it 'returns the highest role if user is member of multiple groups' do
      create(:group) do |group|
        group.add_user(user, GroupMember::MAINTAINER)
      end

      create(:group) do |group|
        group.add_user(user, GroupMember::DEVELOPER)
      end

      expect(user.highest_role).to eq(Gitlab::Access::MAINTAINER)
    end

    it 'returns the highest role if user is member of multiple groups and projects' do
      create(:group) do |group|
        group.add_user(user, GroupMember::DEVELOPER)
      end

      create(:project, group: group) do |project|
        project.add_maintainer(user)
      end

      expect(user.highest_role).to eq(Gitlab::Access::MAINTAINER)
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
    let(:user) { create(:user) }
    let(:project) { create(:project) }
    let!(:private_deploy_keys_project) { create(:deploy_keys_project) }
    let!(:public_deploy_keys_project) { create(:deploy_keys_project) }
    let!(:accessible_deploy_keys_project) { create(:deploy_keys_project, project: project) }

    before do
      public_deploy_keys_project.deploy_key.update(public: true)
      project.add_developer(user)
    end

    it 'user can only see deploy keys accessible to right projects' do
      expect(user.accessible_deploy_keys).to match_array([public_deploy_keys_project.deploy_key,
                                                          accessible_deploy_keys_project.deploy_key])
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
      expect(SecureRandom).to receive(:hex).and_return('3b8ca303')

      user = create(:user)

      expect(user.incoming_email_token).to eql('gitlab')
    end
  end

  describe '#ensure_user_rights_and_limits' do
    describe 'with external user' do
      let(:user) { create(:user, external: true) }

      it 'receives callback when external changes' do
        expect(user).to receive(:ensure_user_rights_and_limits)

        user.update(external: false)
      end

      it 'ensures correct rights and limits for user' do
        stub_config_setting(default_can_create_group: true)

        expect { user.update(external: false) }.to change { user.can_create_group }.to(true)
          .and change { user.projects_limit }.to(Gitlab::CurrentSettings.default_projects_limit)
      end
    end

    describe 'without external user' do
      let(:user) { create(:user, external: false) }

      it 'receives callback when external changes' do
        expect(user).to receive(:ensure_user_rights_and_limits)

        user.update(external: true)
      end

      it 'ensures correct rights and limits for user' do
        expect { user.update(external: true) }.to change { user.can_create_group }.to(false)
          .and change { user.projects_limit }.to(0)
      end
    end
  end

  describe 'feed token' do
    it 'ensures a feed token on read' do
      user = create(:user, feed_token: nil)
      feed_token = user.feed_token

      expect(feed_token).not_to be_blank
      expect(user.reload.feed_token).to eq feed_token
    end
  end

  describe 'static object token' do
    it 'ensures a static object token on read' do
      user = create(:user, static_object_token: nil)
      static_object_token = user.static_object_token

      expect(static_object_token).not_to be_blank
      expect(user.reload.static_object_token).to eq static_object_token
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

      @project = create(:project, namespace: @user.namespace)
      @project_2 = create(:project, group: create(:group)) do |project|
        project.add_maintainer(@user)
      end
      @project_3 = create(:project, group: create(:group)) do |project|
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
    let(:user) { create(:user) }
    let(:group) { create(:group) }

    before do
      group.add_owner(user)
    end

    it { expect(user.several_namespaces?).to be_truthy }
    it { expect(user.authorized_groups).to eq([group]) }
    it { expect(user.owned_groups).to eq([group]) }
    it { expect(user.namespaces).to contain_exactly(user.namespace, group) }
    it { expect(user.manageable_namespaces).to contain_exactly(user.namespace, group) }

    context 'with child groups' do
      let!(:subgroup) { create(:group, parent: group) }

      describe '#manageable_namespaces' do
        it 'includes all the namespaces the user can manage' do
          expect(user.manageable_namespaces).to contain_exactly(user.namespace, group, subgroup)
        end
      end

      describe '#manageable_groups' do
        it 'includes all the namespaces the user can manage' do
          expect(user.manageable_groups).to contain_exactly(group, subgroup)
        end

        it 'does not include duplicates if a membership was added for the subgroup' do
          subgroup.add_owner(user)

          expect(user.manageable_groups).to contain_exactly(group, subgroup)
        end
      end

      describe '#manageable_groups_with_routes' do
        it 'eager loads routes from manageable groups' do
          control_count =
            ActiveRecord::QueryRecorder.new(skip_cached: false) do
              user.manageable_groups_with_routes.map(&:route)
            end.count

          create(:group, parent: subgroup)

          expect do
            user.manageable_groups_with_routes.map(&:route)
          end.not_to exceed_all_query_limit(control_count)
        end
      end
    end
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
      @project = create(:project, namespace: @user.namespace)
    end

    it { expect(@user.several_namespaces?).to be_falsey }
    it { expect(@user.namespaces).to eq([@user.namespace]) }
  end

  describe 'blocking user' do
    let(:user) { create(:user, name: 'John Smith') }

    it 'blocks user' do
      user.block

      expect(user.blocked?).to be_truthy
    end

    context 'when user has running CI pipelines' do
      let(:service) { double }

      before do
        pipeline = create(:ci_pipeline, :running, user: user)
        create(:ci_build, :running, pipeline: pipeline)
      end

      it 'cancels all running pipelines and related jobs' do
        expect(Ci::CancelUserPipelinesService).to receive(:new).and_return(service)
        expect(service).to receive(:execute).with(user)

        user.block
      end
    end
  end

  describe 'deactivating a user' do
    let(:user) { create(:user, name: 'John Smith') }

    context "an active user" do
      it "can be deactivated" do
        user.deactivate

        expect(user.deactivated?).to be_truthy
      end
    end

    context "a user who is blocked" do
      before do
        user.block
      end

      it "cannot be deactivated" do
        user.deactivate

        expect(user.reload.deactivated?).to be_falsy
      end
    end
  end

  describe '.filter_items' do
    let(:user) { double }

    it 'filters by active users by default' do
      expect(described_class).to receive(:active).and_return([user])

      expect(described_class.filter_items(nil)).to include user
    end

    it 'filters by admins' do
      expect(described_class).to receive(:admins).and_return([user])

      expect(described_class.filter_items('admins')).to include user
    end

    it 'filters by blocked' do
      expect(described_class).to receive(:blocked).and_return([user])

      expect(described_class.filter_items('blocked')).to include user
    end

    it 'filters by deactivated' do
      expect(described_class).to receive(:deactivated).and_return([user])

      expect(described_class.filter_items('deactivated')).to include user
    end

    it 'filters by two_factor_disabled' do
      expect(described_class).to receive(:without_two_factor).and_return([user])

      expect(described_class.filter_items('two_factor_disabled')).to include user
    end

    it 'filters by two_factor_enabled' do
      expect(described_class).to receive(:with_two_factor).and_return([user])

      expect(described_class.filter_items('two_factor_enabled')).to include user
    end

    it 'filters by wop' do
      expect(described_class).to receive(:without_projects).and_return([user])

      expect(described_class.filter_items('wop')).to include user
    end
  end

  describe '.without_projects' do
    let!(:project) { create(:project, :public) }
    let!(:user) { create(:user) }
    let!(:user_without_project) { create(:user) }
    let!(:user_without_project2) { create(:user) }

    before do
      # add user to project
      project.add_maintainer(user)

      # create invite to projet
      create(:project_member, :developer, project: project, invite_token: '1234', invite_email: 'inviteduser1@example.com')

      # create request to join project
      project.request_access(user_without_project2)
    end

    it { expect(described_class.without_projects).not_to include user }
    it { expect(described_class.without_projects).to include user_without_project }
    it { expect(described_class.without_projects).to include user_without_project2 }
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
      let(:user) { described_class.new }

      it "applies defaults to user" do
        expect(user.projects_limit).to eq(Gitlab.config.gitlab.default_projects_limit)
        expect(user.can_create_group).to eq(Gitlab.config.gitlab.default_can_create_group)
        expect(user.theme_id).to eq(Gitlab.config.gitlab.default_theme)
        expect(user.external).to be_falsey
        expect(user.private_profile).to eq(false)
      end
    end

    describe 'with default overrides' do
      let(:user) { described_class.new(projects_limit: 123, can_create_group: false, can_create_team: true) }

      it "applies defaults to user" do
        expect(user.projects_limit).to eq(123)
        expect(user.can_create_group).to be_falsey
        expect(user.theme_id).to eq(1)
      end

      it 'does not undo projects_limit setting if it matches old DB default of 10' do
        # If the real default project limit is 10 then this test is worthless
        expect(Gitlab.config.gitlab.default_projects_limit).not_to eq(10)
        user = described_class.new(projects_limit: 10)
        expect(user.projects_limit).to eq(10)
      end
    end

    context 'when Gitlab::CurrentSettings.user_default_external is true' do
      before do
        stub_application_setting(user_default_external: true)
      end

      it "creates external user by default" do
        user = create(:user)

        expect(user.external).to be_truthy
        expect(user.can_create_group).to be_falsey
        expect(user.projects_limit).to be 0
      end

      describe 'with default overrides' do
        it "creates a non-external user" do
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
        it "has correct require_ssh_key?" do
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

    it 'finds by primary email' do
      user = create(:user, email: 'foo@example.com')

      expect(described_class.find_by_any_email(user.email)).to eq user
      expect(described_class.find_by_any_email(user.email, confirmed: true)).to eq user
    end

    it 'finds by uppercased email' do
      user = create(:user, email: 'foo@example.com')

      expect(described_class.find_by_any_email(user.email.upcase)).to eq user
      expect(described_class.find_by_any_email(user.email.upcase, confirmed: true)).to eq user
    end

    context 'finds by secondary email' do
      let(:user) { email.user }

      context 'primary email confirmed' do
        context 'secondary email confirmed' do
          let!(:email) { create(:email, :confirmed, email: 'foo@example.com') }

          it 'finds user respecting the confirmed flag' do
            expect(described_class.find_by_any_email(email.email)).to eq user
            expect(described_class.find_by_any_email(email.email, confirmed: true)).to eq user
          end
        end

        context 'secondary email not confirmed' do
          let!(:email) { create(:email, email: 'foo@example.com') }

          it 'finds user respecting the confirmed flag' do
            expect(described_class.find_by_any_email(email.email)).to eq user
            expect(described_class.find_by_any_email(email.email, confirmed: true)).to be_nil
          end
        end
      end

      context 'primary email not confirmed' do
        let(:user) { create(:user, confirmed_at: nil) }
        let!(:email) { create(:email, :confirmed, user: user, email: 'foo@example.com') }

        it 'finds user respecting the confirmed flag' do
          expect(described_class.find_by_any_email(email.email)).to eq user
          expect(described_class.find_by_any_email(email.email, confirmed: true)).to be_nil
        end
      end
    end

    it 'returns nil when nothing found' do
      expect(described_class.find_by_any_email('')).to be_nil
    end

    it 'returns nil when user is not confirmed' do
      user = create(:user, email: 'foo@example.com', confirmed_at: nil)

      expect(described_class.find_by_any_email(user.email, confirmed: false)).to eq(user)
      expect(described_class.find_by_any_email(user.email, confirmed: true)).to be_nil
    end
  end

  describe '.by_any_email' do
    it 'returns an ActiveRecord::Relation' do
      expect(described_class.by_any_email('foo@example.com'))
        .to be_a_kind_of(ActiveRecord::Relation)
    end

    it 'returns a relation of users' do
      user = create(:user)

      expect(described_class.by_any_email(user.email)).to eq([user])
    end

    it 'returns a relation of users for confirmed users' do
      user = create(:user)

      expect(described_class.by_any_email(user.email, confirmed: true)).to eq([user])
    end

    it 'finds user through a private commit email' do
      user = create(:user)
      private_email = user.private_commit_email

      expect(described_class.by_any_email(private_email)).to eq([user])
      expect(described_class.by_any_email(private_email, confirmed: true)).to eq([user])
    end

    it 'finds user through a private commit email in an array' do
      user = create(:user)
      private_email = user.private_commit_email

      expect(described_class.by_any_email([private_email])).to eq([user])
      expect(described_class.by_any_email([private_email], confirmed: true)).to eq([user])
    end
  end

  describe '.search' do
    let!(:user) { create(:user, name: 'user', username: 'usern', email: 'email@gmail.com') }
    let!(:user2) { create(:user, name: 'user name', username: 'username', email: 'someemail@gmail.com') }
    let!(:user3) { create(:user, name: 'us', username: 'se', email: 'foo@gmail.com') }

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

      it 'returns users with a exact matching name shorter than 3 chars' do
        expect(described_class.search(user3.name)).to eq([user3])
      end

      it 'returns users with a exact matching name shorter than 3 chars regardless of the casing' do
        expect(described_class.search(user3.name.upcase)).to eq([user3])
      end
    end

    describe 'email matching' do
      it 'returns users with a matching Email' do
        expect(described_class.search(user.email)).to eq([user])
      end

      it 'does not return users with a partially matching Email' do
        expect(described_class.search(user.email[0..2])).not_to include(user, user2)
      end

      it 'returns users with a matching Email regardless of the casing' do
        expect(described_class.search(user2.email.upcase)).to eq([user2])
      end
    end

    describe 'username matching' do
      it 'returns users with a matching username' do
        expect(described_class.search(user.username)).to eq([user, user2])
      end

      it 'returns users with a matching username starting with a @' do
        expect(described_class.search("@#{user.username}")).to eq([user, user2])
      end

      it 'returns users with a partially matching username' do
        expect(described_class.search(user.username[0..2])).to eq([user, user2])
      end

      it 'returns users with a partially matching username starting with @' do
        expect(described_class.search("@#{user.username[0..2]}")).to eq([user, user2])
      end

      it 'returns users with a matching username regardless of the casing' do
        expect(described_class.search(user2.username.upcase)).to eq([user2])
      end

      it 'returns users with a exact matching username shorter than 3 chars' do
        expect(described_class.search(user3.username)).to eq([user3])
      end

      it 'returns users with a exact matching username shorter than 3 chars regardless of the casing' do
        expect(described_class.search(user3.username.upcase)).to eq([user3])
      end
    end

    it 'returns no matches for an empty string' do
      expect(described_class.search('')).to be_empty
    end

    it 'returns no matches for nil' do
      expect(described_class.search(nil)).to be_empty
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

    it 'does not return users with a partially matching email' do
      expect(search_with_secondary_emails(user.email[0..2])).not_to include([user])
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

    it 'does not return users with a matching part of secondary email' do
      expect(search_with_secondary_emails(email.email[1..4])).not_to include([email.user])
    end

    it 'returns no matches for an empty string' do
      expect(search_with_secondary_emails('')).to be_empty
    end

    it 'returns no matches for nil' do
      expect(search_with_secondary_emails(nil)).to be_empty
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
  end

  describe '.by_login' do
    let(:username) { 'John' }
    let!(:user) { create(:user, username: username) }

    it 'gets the correct user' do
      expect(described_class.by_login(user.email.upcase)).to eq user
      expect(described_class.by_login(user.email)).to eq user
      expect(described_class.by_login(username.downcase)).to eq user
      expect(described_class.by_login(username)).to eq user
      expect(described_class.by_login(nil)).to be_nil
      expect(described_class.by_login('')).to be_nil
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
        expect(described_class.find_by_full_path(route.path)).to eq(user)
      end

      it 'is case-insensitive' do
        expect(described_class.find_by_full_path(route.path.upcase)).to eq(user)
        expect(described_class.find_by_full_path(route.path.downcase)).to eq(user)
      end
    end

    context 'with a redirect route matching the given path' do
      let!(:redirect_route) { user.namespace.redirect_routes.create(path: 'foo') }

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

      expect(user.avatar_type).to eq(['file format is not supported. Please try one of the following supported formats: png, jpg, jpeg, gif, bmp, tiff, ico'])
    end
  end

  describe '#avatar_url' do
    let(:user) { create(:user, :with_avatar) }

    context 'when avatar file is uploaded' do
      it 'shows correct avatar url' do
        expect(user.avatar_url).to eq(user.avatar.url)
        expect(user.avatar_url(only_path: false)).to eq([Gitlab.config.gitlab.url, user.avatar.url].join)
      end
    end
  end

  describe '#accept_pending_invitations!' do
    let(:user) { create(:user, email: 'user@email.com') }
    let!(:project_member_invite) { create(:project_member, :invited, invite_email: user.email) }
    let!(:group_member_invite) { create(:group_member, :invited, invite_email: user.email) }
    let!(:external_project_member_invite) { create(:project_member, :invited, invite_email: 'external@email.com') }
    let!(:external_group_member_invite) { create(:group_member, :invited, invite_email: 'external@email.com') }

    it 'accepts all the user members pending invitations and returns the accepted_members' do
      accepted_members = user.accept_pending_invitations!

      expect(accepted_members).to match_array([project_member_invite, group_member_invite])
      expect(group_member_invite.reload).not_to be_invite
      expect(project_member_invite.reload).not_to be_invite
      expect(external_project_member_invite.reload).to be_invite
      expect(external_group_member_invite.reload).to be_invite
    end
  end

  describe '#all_emails' do
    let(:user) { create(:user) }

    it 'returns all emails' do
      email_confirmed   = create :email, user: user, confirmed_at: Time.now
      email_unconfirmed = create :email, user: user
      user.reload

      expect(user.all_emails).to contain_exactly(
        user.email,
        user.private_commit_email,
        email_unconfirmed.email,
        email_confirmed.email
      )
    end
  end

  describe '#verified_emails' do
    let(:user) { create(:user) }

    it 'returns only confirmed emails' do
      email_confirmed = create :email, user: user, confirmed_at: Time.now
      create :email, user: user

      expect(user.verified_emails).to contain_exactly(
        user.email,
        user.private_commit_email,
        email_confirmed.email
      )
    end
  end

  describe '#verified_email?' do
    let(:user) { create(:user) }

    it 'returns true when the email is verified/confirmed' do
      email_confirmed = create :email, user: user, confirmed_at: Time.now
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

  describe '#ultraauth_user?' do
    it 'is true if provider is ultraauth' do
      user = create(:omniauth_user, provider: 'ultraauth')

      expect(user.ultraauth_user?).to be_truthy
    end

    it 'is false with othe provider' do
      user = create(:omniauth_user, provider: 'not-ultraauth')

      expect(user.ultraauth_user?).to be_falsey
    end

    it 'is false if no extern_uid is provided' do
      user = create(:omniauth_user, extern_uid: nil)

      expect(user.ldap_user?).to be_falsey
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
      project = create(:project, :public)

      expect(user.starred?(project)).to be_falsey

      user.toggle_star(project)

      expect(user.starred?(project)).to be_truthy

      user.toggle_star(project)

      expect(user.starred?(project)).to be_falsey
    end
  end

  describe '.find_by_private_commit_email' do
    context 'with email' do
      set(:user) { create(:user) }

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
    before do
      described_class.delete_all
      @user = create :user, created_at: Date.today, current_sign_in_at: Date.today, name: 'Alpha'
      @user1 = create :user, created_at: Date.today - 1, current_sign_in_at: Date.today - 1, name: 'Omega'
      @user2 = create :user, created_at: Date.today - 2, name: 'Beta'
    end

    context 'when sort by recent_sign_in' do
      let(:users) { described_class.sort_by_attribute('recent_sign_in') }

      it 'sorts users by recent sign-in time' do
        expect(users.first).to eq(@user)
        expect(users.second).to eq(@user1)
      end

      it 'pushes users who never signed in to the end' do
        expect(users.third).to eq(@user2)
      end
    end

    context 'when sort by oldest_sign_in' do
      let(:users) { described_class.sort_by_attribute('oldest_sign_in') }

      it 'sorts users by the oldest sign-in time' do
        expect(users.first).to eq(@user1)
        expect(users.second).to eq(@user)
      end

      it 'pushes users who never signed in to the end' do
        expect(users.third).to eq(@user2)
      end
    end

    it 'sorts users in descending order by their creation time' do
      expect(described_class.sort_by_attribute('created_desc').first).to eq(@user)
    end

    it 'sorts users in ascending order by their creation time' do
      expect(described_class.sort_by_attribute('created_asc').first).to eq(@user2)
    end

    it 'sorts users by id in descending order when nil is passed' do
      expect(described_class.sort_by_attribute(nil).first).to eq(@user2)
    end
  end

  describe "#last_active_at" do
    let(:last_activity_on) { 5.days.ago.to_date }
    let(:current_sign_in_at) { 8.days.ago }

    context 'for a user that has `last_activity_on` set' do
      let(:user) { create(:user, last_activity_on: last_activity_on) }

      it 'returns `last_activity_on` with current time zone' do
        expect(user.last_active_at).to eq(last_activity_on.to_time.in_time_zone)
      end
    end

    context 'for a user that has `current_sign_in_at` set' do
      let(:user) { create(:user, current_sign_in_at: current_sign_in_at) }

      it 'returns `current_sign_in_at`' do
        expect(user.last_active_at).to eq(current_sign_in_at)
      end
    end

    context 'for a user that has both `current_sign_in_at` & ``last_activity_on`` set' do
      let(:user) { create(:user, current_sign_in_at: current_sign_in_at, last_activity_on: last_activity_on) }

      it 'returns the latest among `current_sign_in_at` & `last_activity_on`' do
        latest_event = [current_sign_in_at, last_activity_on.to_time.in_time_zone].max
        expect(user.last_active_at).to eq(latest_event)
      end
    end

    context 'for a user that does not have both `current_sign_in_at` & `last_activity_on` set' do
      let(:user) { create(:user, current_sign_in_at: nil, last_activity_on: nil) }

      it 'returns nil' do
        expect(user.last_active_at).to eq(nil)
      end
    end
  end

  describe "#can_be_deactivated?" do
    let(:activity) { {} }
    let(:user) { create(:user, name: 'John Smith', **activity) }
    let(:day_within_minium_inactive_days_threshold) { User::MINIMUM_INACTIVE_DAYS.pred.days.ago }
    let(:day_outside_minium_inactive_days_threshold) { User::MINIMUM_INACTIVE_DAYS.next.days.ago }

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

    context "a user who is not active" do
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
  end

  describe "#contributed_projects" do
    subject { create(:user) }

    let!(:project1) { create(:project) }
    let!(:project2) { fork_project(project3) }
    let!(:project3) { create(:project) }
    let!(:merge_request) { create(:merge_request, source_project: project2, target_project: project3, author: subject) }
    let!(:push_event) { create(:push_event, project: project1, author: subject) }
    let!(:merge_event) { create(:event, :created, project: project3, target: merge_request, author: subject) }

    before do
      project1.add_maintainer(subject)
      project2.add_maintainer(subject)
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

  describe '#fork_of' do
    let(:user) { create(:user) }

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
    let!(:user) { create(:user) }
    let!(:private_group) { create(:group) }
    let!(:child_group) { create(:group, parent: private_group) }

    let!(:project_group) { create(:group) }
    let!(:project) { create(:project, group: project_group) }

    before do
      private_group.add_user(user, Gitlab::Access::MAINTAINER)
      project.add_maintainer(user)
    end

    subject { user.authorized_groups }

    it { is_expected.to contain_exactly private_group, project_group }
  end

  describe '#membership_groups' do
    let!(:user) { create(:user) }
    let!(:parent_group) { create(:group) }
    let!(:child_group) { create(:group, parent: parent_group) }

    before do
      parent_group.add_user(user, Gitlab::Access::MAINTAINER)
    end

    subject { user.membership_groups }

    it { is_expected.to contain_exactly parent_group, child_group }
  end

  describe '#authorizations_for_projects' do
    let!(:user) { create(:user) }
    subject { Project.where("EXISTS (?)", user.authorizations_for_projects) }

    it 'includes projects that belong to a user, but no other projects' do
      owned = create(:project, :private, namespace: user.namespace)
      member = create(:project, :private).tap { |p| p.add_maintainer(user) }
      other = create(:project)

      expect(subject).to include(owned)
      expect(subject).to include(member)
      expect(subject).not_to include(other)
    end

    it 'includes projects a user has access to, but no other projects' do
      other_user = create(:user)
      accessible = create(:project, :private, namespace: other_user.namespace) do |project|
        project.add_developer(user)
      end
      other = create(:project)

      expect(subject).to include(accessible)
      expect(subject).not_to include(other)
    end

    context 'with min_access_level' do
      let!(:user) { create(:user) }
      let!(:project) { create(:project, :private, namespace: user.namespace) }

      before do
        project.add_developer(user)
      end

      subject { Project.where("EXISTS (?)", user.authorizations_for_projects(min_access_level: min_access_level)) }

      context 'when developer access' do
        let(:min_access_level) { Gitlab::Access::DEVELOPER }

        it 'includes projects a user has access to' do
          expect(subject).to include(project)
        end
      end

      context 'when owner access' do
        let(:min_access_level) { Gitlab::Access::OWNER }

        it 'does not include projects with higher access level' do
          expect(subject).not_to include(project)
        end
      end
    end
  end

  describe '#authorized_projects', :delete do
    context 'with a minimum access level' do
      it 'includes projects for which the user is an owner' do
        user = create(:user)
        project = create(:project, :private, namespace: user.namespace)

        expect(user.authorized_projects(Gitlab::Access::REPORTER))
          .to contain_exactly(project)
      end

      it 'includes projects for which the user is a maintainer' do
        user = create(:user)
        project = create(:project, :private)

        project.add_maintainer(user)

        expect(user.authorized_projects(Gitlab::Access::REPORTER))
          .to contain_exactly(project)
      end
    end

    it "includes user's personal projects" do
      user    = create(:user)
      project = create(:project, :private, namespace: user.namespace)

      expect(user.authorized_projects).to include(project)
    end

    it "includes personal projects user has been given access to" do
      user1   = create(:user)
      user2   = create(:user)
      project = create(:project, :private, namespace: user1.namespace)

      project.add_developer(user2)

      expect(user2.authorized_projects).to include(project)
    end

    it "includes projects of groups user has been added to" do
      group   = create(:group)
      project = create(:project, group: group)
      user    = create(:user)

      group.add_developer(user)

      expect(user.authorized_projects).to include(project)
    end

    it "does not include projects of groups user has been removed from" do
      group   = create(:group)
      project = create(:project, group: group)
      user    = create(:user)

      member = group.add_developer(user)

      expect(user.authorized_projects).to include(project)

      member.destroy

      expect(user.authorized_projects).not_to include(project)
    end

    it "includes projects shared with user's group" do
      user    = create(:user)
      project = create(:project, :private)
      group   = create(:group)

      group.add_reporter(user)
      project.project_group_links.create(group: group)

      expect(user.authorized_projects).to include(project)
    end

    it "does not include destroyed projects user had access to" do
      user1   = create(:user)
      user2   = create(:user)
      project = create(:project, :private, namespace: user1.namespace)

      project.add_developer(user2)

      expect(user2.authorized_projects).to include(project)

      project.destroy

      expect(user2.authorized_projects).not_to include(project)
    end

    it "does not include projects of destroyed groups user had access to" do
      group   = create(:group)
      project = create(:project, namespace: group)
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
      reporter_project  = create(:project) { |p| p.add_reporter(user) }
      developer_project = create(:project) { |p| p.add_developer(user) }
      maintainer_project = create(:project) { |p| p.add_maintainer(user) }

      expect(user.projects_where_can_admin_issues.to_a).to match_array([maintainer_project, developer_project, reporter_project])
      expect(user.can?(:admin_issue, maintainer_project)).to eq(true)
      expect(user.can?(:admin_issue, developer_project)).to eq(true)
      expect(user.can?(:admin_issue, reporter_project)).to eq(true)
    end

    it 'does not include for which the user access level is below reporter' do
      project = create(:project)
      guest_project = create(:project) { |p| p.add_guest(user) }

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

  describe '#ci_owned_runners' do
    let(:user) { create(:user) }
    let!(:project) { create(:project) }
    let(:runner) { create(:ci_runner, :project, projects: [project]) }

    context 'without any projects nor groups' do
      it 'does not load' do
        expect(user.ci_owned_runners).to be_empty
      end
    end

    context 'with personal projects runners' do
      let(:namespace) { create(:namespace, owner: user) }
      let!(:project) { create(:project, namespace: namespace) }

      it 'loads' do
        expect(user.ci_owned_runners).to contain_exactly(runner)
      end
    end

    context 'with personal group runner' do
      let!(:project) { create(:project) }
      let(:group_runner) { create(:ci_runner, :group, groups: [group]) }
      let!(:group) do
        create(:group).tap do |group|
          group.add_owner(user)
        end
      end

      it 'loads' do
        expect(user.ci_owned_runners).to contain_exactly(group_runner)
      end
    end

    context 'with personal project and group runner' do
      let(:namespace) { create(:namespace, owner: user) }
      let!(:project) { create(:project, namespace: namespace) }
      let!(:group_runner) { create(:ci_runner, :group, groups: [group]) }

      let!(:group) do
        create(:group).tap do |group|
          group.add_owner(user)
        end
      end

      it 'loads' do
        expect(user.ci_owned_runners).to contain_exactly(runner, group_runner)
      end
    end

    shared_examples :member do
      context 'when the user is a maintainer' do
        before do
          add_user(:maintainer)
        end

        it 'does not load' do
          expect(user.ci_owned_runners).to be_empty
        end
      end

      context 'when the user is a developer' do
        before do
          add_user(:developer)
        end

        it 'does not load' do
          expect(user.ci_owned_runners).to be_empty
        end
      end
    end

    shared_examples :group_member do
      context 'when the user is owner' do
        before do
          add_user(:owner)
        end

        it 'loads' do
          expect(user.ci_owned_runners).to contain_exactly(runner)
        end
      end

      it_behaves_like :member
    end

    context 'with groups projects runners' do
      let(:group) { create(:group) }
      let!(:project) { create(:project, group: group) }

      def add_user(access)
        group.add_user(user, access)
      end

      it_behaves_like :group_member
    end

    context 'with groups runners' do
      let!(:runner) { create(:ci_runner, :group, groups: [group]) }
      let!(:group) { create(:group) }

      def add_user(access)
        group.add_user(user, access)
      end

      it_behaves_like :group_member
    end

    context 'with other projects runners' do
      let!(:project) { create(:project) }

      def add_user(access)
        project.add_user(user, access)
      end

      it_behaves_like :member
    end

    context 'with subgroup with different owner for project runner' do
      let(:group) { create(:group) }
      let(:another_user) { create(:user) }
      let(:subgroup) { create(:group, parent: group) }
      let!(:project) { create(:project, group: subgroup) }

      def add_user(access)
        group.add_user(user, access)
        group.add_user(another_user, :owner)
        subgroup.add_user(another_user, :owner)
      end

      it_behaves_like :group_member
    end
  end

  describe '#projects_with_reporter_access_limited_to' do
    let(:project1) { create(:project) }
    let(:project2) { create(:project) }
    let(:user) { create(:user) }

    before do
      project1.add_reporter(user)
      project2.add_guest(user)
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
      before do
        group.add_owner(user)
      end

      it 'returns all groups' do
        is_expected.to match_array [
          group,
          nested_group_1, nested_group_1_1,
          nested_group_2, nested_group_2_1
        ]
      end
    end

    context 'user is member of the first child (internal node), branch 1' do
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

    context 'user is member of the first child (internal node), branch 2' do
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

    context 'user is member of the last child (leaf node)' do
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

  describe '#refresh_authorized_projects', :clean_gitlab_redis_shared_state do
    let(:project1) { create(:project) }
    let(:project2) { create(:project) }
    let(:user) { create(:user) }

    before do
      project1.add_reporter(user)
      project2.add_guest(user)

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

    context 'for admin user' do
      include_context 'custom session'

      let(:user) { build(:user, :admin) }

      context 'when admin mode is disabled' do
        it 'returns false' do
          expect(user.full_private_access?).to be_falsy
        end
      end

      context 'when admin mode is enabled' do
        before do
          Gitlab::Auth::CurrentUserMode.new(user).enable_admin_mode!(password: user.password)
        end

        it 'returns true' do
          expect(user.full_private_access?).to be_truthy
        end
      end
    end
  end

  describe '.ghost' do
    it "creates a ghost user if one isn't already present" do
      ghost = described_class.ghost

      expect(ghost).to be_ghost
      expect(ghost).to be_persisted
      expect(ghost.namespace).not_to be_nil
      expect(ghost.namespace).to be_persisted
    end

    it "does not create a second ghost user if one is already present" do
      expect do
        described_class.ghost
        described_class.ghost
      end.to change { described_class.count }.by(1)
      expect(described_class.ghost).to eq(described_class.ghost)
    end

    context "when a regular user exists with the username 'ghost'" do
      it "creates a ghost user with a non-conflicting username" do
        create(:user, username: 'ghost')
        ghost = described_class.ghost

        expect(ghost).to be_persisted
        expect(ghost.username).to eq('ghost1')
      end
    end

    context "when a regular user exists with the email 'ghost@example.com'" do
      it "creates a ghost user with a non-conflicting email" do
        create(:user, email: 'ghost@example.com')
        ghost = described_class.ghost

        expect(ghost).to be_persisted
        expect(ghost.email).to eq('ghost1@example.com')
      end
    end

    context 'when a domain whitelist is in place' do
      before do
        stub_application_setting(domain_whitelist: ['gitlab.com'])
      end

      it 'creates a ghost user' do
        expect(described_class.ghost).to be_persisted
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

    context 'with 2FA requirement from expanded groups' do
      let!(:group1) { create :group, require_two_factor_authentication: true }
      let!(:group1a) { create :group, parent: group1 }

      before do
        group1a.add_user(user, GroupMember::OWNER)

        user.update_two_factor_requirement
      end

      it 'requires 2FA' do
        expect(user.require_two_factor_authentication_from_group).to be true
      end
    end

    context 'with 2FA requirement on nested child group' do
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

    context "with 2FA requirement from shared project's group" do
      let!(:group1) { create :group, require_two_factor_authentication: true }
      let!(:group2) { create :group }
      let(:shared_project) { create(:project, namespace: group1) }

      before do
        shared_project.project_group_links.create!(
          group: group2,
          group_access: ProjectGroupLink.default_access
        )

        group2.add_user(user, GroupMember::OWNER)
      end

      it 'does not require 2FA' do
        user.update_two_factor_requirement

        expect(user.require_two_factor_authentication_from_group).to be false
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
      described_class.ghost
      create(:user, name: 'user', state: 'active')
      create(:user, name: 'user', state: 'blocked')
    end

    it 'only counts active and non internal users' do
      expect(described_class.active.count).to eq(1)
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

  context '#invalidate_personal_projects_count' do
    let(:user) { build_stubbed(:user) }

    it 'invalidates cache for personal projects counter' do
      cache_mock = double

      expect(cache_mock).to receive(:delete).with(['users', user.id, 'personal_projects_count'])

      allow(Rails).to receive(:cache).and_return(cache_mock)

      user.invalidate_personal_projects_count
    end
  end

  describe '#allow_password_authentication_for_web?' do
    context 'regular user' do
      let(:user) { build(:user) }

      it 'returns true when password authentication is enabled for the web interface' do
        expect(user.allow_password_authentication_for_web?).to be_truthy
      end

      it 'returns false when password authentication is disabled for the web interface' do
        stub_application_setting(password_authentication_enabled_for_web: false)

        expect(user.allow_password_authentication_for_web?).to be_falsey
      end
    end

    it 'returns false for ldap user' do
      user = create(:omniauth_user, provider: 'ldapmain')

      expect(user.allow_password_authentication_for_web?).to be_falsey
    end

    it 'returns false for ultraauth user' do
      user = create(:omniauth_user, provider: 'ultraauth')

      expect(user.allow_password_authentication_for_web?).to be_falsey
    end
  end

  describe '#allow_password_authentication_for_git?' do
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

    it 'returns false for ultraauth user' do
      user = create(:omniauth_user, provider: 'ultraauth')

      expect(user.allow_password_authentication_for_git?).to be_falsey
    end
  end

  describe '#assigned_open_merge_requests_count' do
    it 'returns number of open merge requests from non-archived projects' do
      user    = create(:user)
      project = create(:project, :public)
      archived_project = create(:project, :public, :archived)

      create(:merge_request, source_project: project, author: user, assignees: [user])
      create(:merge_request, :closed, source_project: project, author: user, assignees: [user])
      create(:merge_request, source_project: archived_project, author: user, assignees: [user])

      expect(user.assigned_open_merge_requests_count(force: true)).to eq 1
    end
  end

  describe '#assigned_open_issues_count' do
    it 'returns number of open issues from non-archived projects' do
      user    = create(:user)
      project = create(:project, :public)
      archived_project = create(:project, :public, :archived)

      create(:issue, project: project, author: user, assignees: [user])
      create(:issue, :closed, project: project, author: user, assignees: [user])
      create(:issue, project: archived_project, author: user, assignees: [user])

      expect(user.assigned_open_issues_count(force: true)).to eq 1
    end
  end

  describe '#personal_projects_count' do
    it 'returns the number of personal projects using a single query' do
      user = build(:user)
      projects = double(:projects, count: 1)

      expect(user).to receive(:personal_projects).and_return(projects)

      expect(user.personal_projects_count).to eq(1)
    end
  end

  describe '#projects_limit_left' do
    it 'returns the number of projects that can be created by the user' do
      user = build(:user)

      allow(user).to receive(:projects_limit).and_return(10)
      allow(user).to receive(:personal_projects_count).and_return(5)

      expect(user.projects_limit_left).to eq(5)
    end
  end

  describe '#ensure_namespace_correct' do
    context 'for a new user' do
      let(:user) { build(:user) }

      it 'creates the namespace' do
        expect(user.namespace).to be_nil

        user.save!

        expect(user.namespace).not_to be_nil
      end
    end

    context 'for an existing user' do
      let(:username) { 'foo' }
      let(:user) { create(:user, username: username) }

      context 'when the user is updated' do
        context 'when the username or name is changed' do
          let(:new_username) { 'bar' }

          it 'changes the namespace (just to compare to when username is not changed)' do
            expect do
              Timecop.freeze(1.second.from_now) do
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
              expect(user.namespace.errors.messages[:path].first).to eq('has already been taken')
            end

            it 'adds the namespace errors to the user' do
              user.update(username: new_username)

              expect(user.errors.full_messages.first).to eq('Username has already been taken')
            end
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

  describe '#username_changed_hook' do
    context 'for a new user' do
      let(:user) { build(:user) }

      it 'does not trigger system hook' do
        expect(user).not_to receive(:system_hook_service)

        user.save!
      end
    end

    context 'for an existing user' do
      let(:user) { create(:user, username: 'old-username') }

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
    let(:user) { create(:user, username: 'old-username', email: 'old-email@example.org') }
    let(:new_username) { 'new-name' }
    let(:new_email) { 'new-email@example.org' }

    subject { user.will_save_change_to_login? }

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

    context 'when email and username aren\'t changed' do
      before do
        user.name = 'new_name'
      end

      it { is_expected.to be_falsy }
    end
  end

  describe '#sync_attribute?' do
    let(:user) { described_class.new }

    context 'oauth user' do
      it 'returns true if name can be synced' do
        stub_omniauth_setting(sync_profile_attributes: %w(name location))

        expect(user.sync_attribute?(:name)).to be_truthy
      end

      it 'returns true if email can be synced' do
        stub_omniauth_setting(sync_profile_attributes: %w(name email))

        expect(user.sync_attribute?(:email)).to be_truthy
      end

      it 'returns true if location can be synced' do
        stub_omniauth_setting(sync_profile_attributes: %w(location email))

        expect(user.sync_attribute?(:email)).to be_truthy
      end

      it 'returns false if name can not be synced' do
        stub_omniauth_setting(sync_profile_attributes: %w(location email))

        expect(user.sync_attribute?(:name)).to be_falsey
      end

      it 'returns false if email can not be synced' do
        stub_omniauth_setting(sync_profile_attributes: %w(location email))

        expect(user.sync_attribute?(:name)).to be_falsey
      end

      it 'returns false if location can not be synced' do
        stub_omniauth_setting(sync_profile_attributes: %w(location email))

        expect(user.sync_attribute?(:name)).to be_falsey
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
        stub_omniauth_setting(sync_profile_attributes: %w(location))

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
    let(:user) { create(:user) }
    let(:deleted_by) { create(:user) }

    it 'blocks the user then schedules them for deletion if a hard delete is specified' do
      expect(DeleteUserWorker).to receive(:perform_async).with(deleted_by.id, user.id, hard_delete: true)

      user.delete_async(deleted_by: deleted_by, params: { hard_delete: true })

      expect(user).to be_blocked
    end

    it 'schedules user for deletion without blocking them' do
      expect(DeleteUserWorker).to receive(:perform_async).with(deleted_by.id, user.id, {})

      user.delete_async(deleted_by: deleted_by)

      expect(user).not_to be_blocked
    end
  end

  describe '#max_member_access_for_project_ids' do
    shared_examples 'max member access for projects' do
      let(:user) { create(:user) }
      let(:group) { create(:group) }
      let(:owner_project) { create(:project, group: group) }
      let(:maintainer_project) { create(:project) }
      let(:reporter_project) { create(:project) }
      let(:developer_project) { create(:project) }
      let(:guest_project) { create(:project) }
      let(:no_access_project) { create(:project) }

      let(:projects) do
        [owner_project, maintainer_project, reporter_project, developer_project, guest_project, no_access_project].map(&:id)
      end

      let(:expected) do
        {
          owner_project.id => Gitlab::Access::OWNER,
          maintainer_project.id => Gitlab::Access::MAINTAINER,
          reporter_project.id => Gitlab::Access::REPORTER,
          developer_project.id => Gitlab::Access::DEVELOPER,
          guest_project.id => Gitlab::Access::GUEST,
          no_access_project.id => Gitlab::Access::NO_ACCESS
        }
      end

      before do
        create(:group_member, user: user, group: group)
        maintainer_project.add_maintainer(user)
        reporter_project.add_reporter(user)
        developer_project.add_developer(user)
        guest_project.add_guest(user)
      end

      it 'returns correct roles for different projects' do
        expect(user.max_member_access_for_project_ids(projects)).to eq(expected)
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
        second_maintainer_project = create(:project)
        second_developer_project = create(:project)
        second_maintainer_project.add_maintainer(user)
        second_developer_project.add_developer(user)

        all_projects = projects + [second_maintainer_project.id, second_developer_project.id]

        expected_all = expected.merge(second_maintainer_project.id => Gitlab::Access::MAINTAINER,
                                      second_developer_project.id => Gitlab::Access::DEVELOPER)

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
    shared_examples 'max member access for groups' do
      let(:user) { create(:user) }
      let(:owner_group) { create(:group) }
      let(:maintainer_group) { create(:group) }
      let(:reporter_group) { create(:group) }
      let(:developer_group) { create(:group) }
      let(:guest_group) { create(:group) }
      let(:no_access_group) { create(:group) }

      let(:groups) do
        [owner_group, maintainer_group, reporter_group, developer_group, guest_group, no_access_group].map(&:id)
      end

      let(:expected) do
        {
          owner_group.id => Gitlab::Access::OWNER,
          maintainer_group.id => Gitlab::Access::MAINTAINER,
          reporter_group.id => Gitlab::Access::REPORTER,
          developer_group.id => Gitlab::Access::DEVELOPER,
          guest_group.id => Gitlab::Access::GUEST,
          no_access_group.id => Gitlab::Access::NO_ACCESS
        }
      end

      before do
        owner_group.add_owner(user)
        maintainer_group.add_maintainer(user)
        reporter_group.add_reporter(user)
        developer_group.add_developer(user)
        guest_group.add_guest(user)
      end

      it 'returns correct roles for different groups' do
        expect(user.max_member_access_for_group_ids(groups)).to eq(expected)
      end
    end

    context 'with RequestStore enabled', :request_store do
      include_examples 'max member access for groups'

      def access_levels(groups)
        user.max_member_access_for_group_ids(groups)
      end

      it 'does not perform extra queries when asked for groups who have already been found' do
        access_levels(groups)

        expect { access_levels(groups) }.not_to exceed_query_limit(0)

        expect(access_levels(groups)).to eq(expected)
      end

      it 'only requests the extra groups when uncached groups are passed' do
        second_maintainer_group = create(:group)
        second_developer_group = create(:group)
        second_maintainer_group.add_maintainer(user)
        second_developer_group.add_developer(user)

        all_groups = groups + [second_maintainer_group.id, second_developer_group.id]

        expected_all = expected.merge(second_maintainer_group.id => Gitlab::Access::MAINTAINER,
                                      second_developer_group.id => Gitlab::Access::DEVELOPER)

        access_levels(groups)

        queries = ActiveRecord::QueryRecorder.new { access_levels(all_groups) }

        expect(queries.count).to eq(1)
        expect(queries.log_message).to match(/\W(#{second_maintainer_group.id}, #{second_developer_group.id})\W/)
        expect(access_levels(all_groups)).to eq(expected_all)
      end
    end

    context 'with RequestStore disabled' do
      include_examples 'max member access for groups'
    end
  end

  context 'changing a username' do
    let(:user) { create(:user, username: 'foo') }

    it 'creates a redirect route' do
      expect { user.update!(username: 'bar') }
        .to change { RedirectRoute.where(path: 'foo').count }.by(1)
    end

    it 'deletes the redirect when a user with the old username was created' do
      user.update!(username: 'bar')

      expect { create(:user, username: 'foo') }
        .to change { RedirectRoute.where(path: 'foo').count }.by(-1)
    end
  end

  describe '#required_terms_not_accepted?' do
    let(:user) { build(:user) }
    subject { user.required_terms_not_accepted? }

    context "when terms are not enforced" do
      it { is_expected.to be_falsy }
    end

    context "when terms are enforced and accepted by the user" do
      before do
        enforce_terms
        accept_terms(user)
      end

      it { is_expected.to be_falsy }
    end

    context "when terms are enforced but the user has not accepted" do
      before do
        enforce_terms
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '#increment_failed_attempts!' do
    subject(:user) { create(:user, failed_attempts: 0) }

    it 'logs failed sign-in attempts' do
      expect { user.increment_failed_attempts! }.to change(user, :failed_attempts).from(0).to(1)
    end

    it 'does not log failed sign-in attempts when in a GitLab read-only instance' do
      allow(Gitlab::Database).to receive(:read_only?) { true }

      expect { user.increment_failed_attempts! }.not_to change(user, :failed_attempts)
    end
  end

  describe '#requires_usage_stats_consent?' do
    let(:user) { create(:user, :admin, created_at: 8.days.ago) }

    before do
      allow(user).to receive(:has_current_license?).and_return false
    end

    context 'in single-user environment' do
      it 'requires user consent after one week' do
        create(:user, ghost: true)

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
    context 'when no user ID is provided' do
      it 'returns the input relation' do
        user = create(:user)

        expect(described_class.union_with_user).to eq([user])
      end
    end

    context 'when a user ID is provided' do
      it 'includes the user object in the returned relation' do
        user1 = create(:user)
        user2 = create(:user)
        users = described_class.where(id: user1.id).union_with_user(user2.id)

        expect(users).to include(user1)
        expect(users).to include(user2)
      end

      it 'does not re-apply any WHERE conditions on the outer query' do
        relation = described_class.where(id: 1).union_with_user(2)

        expect(relation.arel.where_sql).to be_nil
      end
    end
  end

  describe '.optionally_search' do
    context 'using nil as the argument' do
      it 'returns the current relation' do
        user = create(:user)

        expect(described_class.optionally_search).to eq([user])
      end
    end

    context 'using an empty String as the argument' do
      it 'returns the current relation' do
        user = create(:user)

        expect(described_class.optionally_search('')).to eq([user])
      end
    end

    context 'using a non-empty String' do
      it 'returns users matching the search query' do
        user1 = create(:user)
        create(:user)

        expect(described_class.optionally_search(user1.name)).to eq([user1])
      end
    end
  end

  describe '.where_not_in' do
    context 'without an argument' do
      it 'returns the current relation' do
        user = create(:user)

        expect(described_class.where_not_in).to eq([user])
      end
    end

    context 'using a list of user IDs' do
      it 'excludes the users from the returned relation' do
        user1 = create(:user)
        user2 = create(:user)

        expect(described_class.where_not_in([user2.id])).to eq([user1])
      end
    end
  end

  describe '.reorder_by_name' do
    it 'reorders the input relation' do
      user1 = create(:user, name: 'A')
      user2 = create(:user, name: 'B')

      expect(described_class.reorder_by_name).to eq([user1, user2])
    end
  end

  describe '#notification_settings_for' do
    let(:user) { create(:user) }
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
      let(:group) { create(:group) }

      subject { user.notification_settings_for(group, inherit: true) }

      context 'when group has no existing notification settings' do
        context 'when group has no ancestors' do
          it 'will be a default Global notification setting' do
            expect(subject.notification_email).to eq(nil)
            expect(subject.level).to eq('global')
          end
        end

        context 'when group has ancestors' do
          context 'when an ancestor has a level other than Global' do
            let(:ancestor) { create(:group) }
            let(:group) { create(:group, parent: ancestor) }

            before do
              create(:notification_setting, user: user, source: ancestor, level: 'participating', notification_email: 'ancestor@example.com')
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

            before do
              create(:notification_setting, user: user, source: grand_ancestor, level: 'participating', notification_email: 'grand@example.com')
              create(:notification_setting, user: user, source: ancestor, level: 'global', notification_email: 'ancestor@example.com')
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

  describe '#notification_email_for' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }

    subject { user.notification_email_for(group) }

    context 'when group is nil' do
      let(:group) { nil }

      it 'returns global notification email' do
        is_expected.to eq(user.notification_email)
      end
    end

    context 'when group has no notification email set' do
      it 'returns global notification email' do
        create(:notification_setting, user: user, source: group, notification_email: '')

        is_expected.to eq(user.notification_email)
      end
    end

    context 'when group has notification email set' do
      it 'returns group notification email' do
        group_notification_email = 'user+group@example.com'

        create(:notification_setting, user: user, source: group, notification_email: group_notification_email)

        is_expected.to eq(group_notification_email)
      end
    end
  end

  describe '#password_expired?' do
    let(:user) { build(:user, password_expires_at: password_expires_at) }

    subject { user.password_expired? }

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
end
