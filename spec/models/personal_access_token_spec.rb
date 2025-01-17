# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessToken, feature_category: :system_access do
  include ::TokenAuthenticatableMatchers

  describe 'default values' do
    subject(:personal_access_token) { described_class.new }

    it { expect(personal_access_token.organization_id).to eq(Organizations::Organization::DEFAULT_ORGANIZATION_ID) }
    it { expect(personal_access_token.organization).to eq(Organizations::Organization.default_organization) }
    it { expect(personal_access_token.description).to be_nil }
  end

  describe '.build' do
    let(:personal_access_token) { build(:personal_access_token) }
    let(:invalid_personal_access_token) { build(:personal_access_token, :invalid) }

    it 'is a valid personal access token' do
      expect(personal_access_token).to be_valid
    end

    it 'ensures that the token is generated' do
      invalid_personal_access_token.save!

      expect(invalid_personal_access_token).to be_valid
      expect(invalid_personal_access_token.token).not_to be_nil
    end
  end

  describe 'associations' do
    subject(:project_access_token) { create(:personal_access_token) }

    it { is_expected.to belong_to(:previous_personal_access_token).class_name('PersonalAccessToken') }
    it { is_expected.to belong_to(:organization).class_name('Organizations::Organization') }
    it { is_expected.to have_many(:last_used_ips) }
  end

  describe 'scopes' do
    describe '.project_access_tokens' do
      let_it_be(:user) { create(:user, :project_bot) }
      let_it_be(:project_member) { create(:project_member, user: user) }
      let_it_be(:project_access_token) { create(:personal_access_token, user: user) }

      subject { described_class.project_access_token }

      it { is_expected.to contain_exactly(project_access_token) }
    end

    describe '.owner_is_human' do
      let_it_be(:user) { create(:user, :project_bot) }
      let_it_be(:project_member) { create(:project_member, user: user) }
      let_it_be(:personal_access_token) { create(:personal_access_token) }
      let_it_be(:project_access_token) { create(:personal_access_token, user: user) }

      subject { described_class.owner_is_human }

      it { is_expected.to contain_exactly(personal_access_token) }
    end

    describe '.for_user' do
      it 'returns personal access tokens of specified user only' do
        user_1 = create(:user)
        token_of_user_1 = create(:personal_access_token, user: user_1)
        create_list(:personal_access_token, 2)

        expect(described_class.for_user(user_1)).to contain_exactly(token_of_user_1)
      end
    end

    describe '.for_users' do
      it 'returns personal access tokens for the specified users only' do
        user_1 = create(:user)
        user_2 = create(:user)
        token_of_user_1 = create(:personal_access_token, user: user_1)
        token_of_user_2 = create(:personal_access_token, user: user_2)
        create_list(:personal_access_token, 3)

        expect(described_class.for_users([user_1, user_2])).to contain_exactly(token_of_user_1, token_of_user_2)
      end
    end

    describe '.created_before' do
      let(:last_used_at) { 1.month.ago.beginning_of_hour }
      let!(:new_used_token) do
        create(:personal_access_token,
          created_at: last_used_at + 1.minute,
          last_used_at: last_used_at + 1.minute
        )
      end

      let!(:old_unused_token) do
        create(:personal_access_token,
          created_at: last_used_at - 1.minute
        )
      end

      let!(:old_formerly_used_token) do
        create(:personal_access_token,
          created_at: last_used_at - 1.minute,
          last_used_at: last_used_at - 1.minute
        )
      end

      let!(:old_still_used_token) do
        create(:personal_access_token,
          created_at: last_used_at - 1.minute,
          last_used_at: 1.minute.ago
        )
      end

      subject { described_class.created_before(last_used_at) }

      it do
        is_expected.to contain_exactly(
          old_unused_token,
          old_formerly_used_token,
          old_still_used_token
        )
      end
    end

    describe 'expires scopes', :time_freeze do
      let!(:expires_last_month_token) { create(:personal_access_token, expires_at: 1.month.ago) }
      let!(:expires_next_month_token) { create(:personal_access_token, expires_at: 1.month.from_now) }
      let!(:expires_two_months_token) { create(:personal_access_token, expires_at: 2.months.from_now) }

      describe '.expires_before' do
        it 'finds tokens that expire before or on date' do
          expect(described_class.expires_before((1.month - 1.day).ago)).to contain_exactly(expires_last_month_token)
        end
      end

      describe '.expires_after' do
        it 'finds tokens that expires after or on date' do
          expect(described_class.expires_after(1.month.from_now.beginning_of_hour))
            .to contain_exactly(expires_next_month_token, expires_two_months_token)
        end
      end
    end

    describe '.last_used_before' do
      context 'last_used_*' do
        let_it_be(:date) { DateTime.new(2022, 01, 01) }
        let_it_be(:token) { create(:personal_access_token, last_used_at: date) }
        # This token should never occur in the following tests and indicates that filtering was done correctly with it
        let_it_be(:never_used_token) { create(:personal_access_token) }

        describe '.last_used_before' do
          it 'returns personal access tokens used before the specified date only' do
            expect(described_class.last_used_before(date + 1)).to contain_exactly(token)
          end
        end

        it 'does not return token that is last_used_at after given date' do
          expect(described_class.last_used_before(date + 1)).not_to contain_exactly(never_used_token)
        end

        describe '.last_used_after' do
          it 'returns personal access tokens used after the specified date only' do
            expect(described_class.last_used_after(date - 1)).to contain_exactly(token)
          end
        end
      end
    end

    describe '.last_used_before_or_unused' do
      let(:last_used_at) { 1.month.ago.beginning_of_hour }
      let!(:unused_token)  { create(:personal_access_token) }
      let!(:used_token) do
        create(:personal_access_token,
          created_at: last_used_at + 1.minute,
          last_used_at: last_used_at + 1.minute
        )
      end

      let!(:old_unused_token) do
        create(:personal_access_token,
          created_at: last_used_at - 1.minute
        )
      end

      let!(:old_formerly_used_token) do
        create(:personal_access_token,
          created_at: last_used_at - 1.minute,
          last_used_at: last_used_at - 1.minute
        )
      end

      let!(:old_still_used_token) do
        create(:personal_access_token,
          created_at: last_used_at - 1.minute,
          last_used_at: 1.minute.ago
        )
      end

      subject { described_class.last_used_before_or_unused(last_used_at) }

      it { is_expected.to contain_exactly(old_unused_token, old_formerly_used_token) }
    end

    describe ".for_organization" do
      let_it_be(:organization) { create(:organization) }
      let_it_be(:personal_access_token) { create(:personal_access_token, organization: organization) }
      let_it_be(:personal_access_token_2) { create(:personal_access_token) }

      it "returns personal access tokens for the specified organization only" do
        expect(described_class.for_organization(organization)).to contain_exactly(personal_access_token)
      end
    end
  end

  describe '#active?' do
    let(:active_personal_access_token) { build(:personal_access_token) }
    let(:revoked_personal_access_token) { build(:personal_access_token, :revoked) }
    let(:expired_personal_access_token) { build(:personal_access_token, :expired) }

    it "returns false if the personal_access_token is revoked" do
      expect(revoked_personal_access_token).not_to be_active
    end

    it "returns false if the personal_access_token is expired" do
      expect(expired_personal_access_token).not_to be_active
    end

    it "returns true if the personal_access_token is not revoked and not expired" do
      expect(active_personal_access_token).to be_active
    end
  end

  describe '#revoke!' do
    let(:active_personal_access_token) { create(:personal_access_token) }

    context 'when the token is persisted' do
      it 'revokes the token' do
        active_personal_access_token.revoke!
        expect(active_personal_access_token.revoked).to be_truthy
        expect(active_personal_access_token).to be_persisted
      end

      it 'updates updated_at timestamp', :aggregate_failures do
        previous_updated_at = active_personal_access_token.updated_at

        timestamp_of_token_revocation = 3.days.from_now.change(usec: 0)

        travel_to(timestamp_of_token_revocation) do
          active_personal_access_token.revoke!
        end

        expect(active_personal_access_token.updated_at).not_to eq(previous_updated_at)

        expect(active_personal_access_token.updated_at).to eq(timestamp_of_token_revocation)
      end
    end

    context 'when the token is not persisted (before scheduled revocation after DEFAULT_LEASE_TIMEOUT)' do
      let(:unpersisted_personal_access_token) { build(:personal_access_token) }

      it 'revokes the token in memory' do
        unpersisted_personal_access_token.revoke!
        expect(unpersisted_personal_access_token.revoked).to be_truthy
        expect(unpersisted_personal_access_token).not_to be_persisted
      end

      it 'does not update updated_at timestamp', :aggregate_failures do
        current_updated_at = unpersisted_personal_access_token.updated_at
        timestamp_of_token_revocation = 3.days.from_now.change(usec: 0)

        travel_to(timestamp_of_token_revocation) do
          unpersisted_personal_access_token.revoke!
        end

        expect(current_updated_at).to eql(unpersisted_personal_access_token.updated_at)
      end
    end
  end

  describe 'validations' do
    let(:personal_access_token) { build(:personal_access_token) }

    describe 'name' do
      it "requires a name" do
        personal_access_token.name = nil

        expect(personal_access_token).not_to be_valid
        expect(personal_access_token.errors[:name].first).to eq "can't be blank"
      end
    end

    describe 'scopes' do
      it "requires at least one scope" do
        personal_access_token.scopes = []

        expect(personal_access_token).not_to be_valid
        expect(personal_access_token.errors[:scopes].first).to eq "can't be blank"
      end

      it "allows creating a token with API scopes" do
        personal_access_token.scopes = [:api, :read_user]

        expect(personal_access_token).to be_valid
      end

      it "allows creating a token with `admin_mode` scope" do
        personal_access_token.scopes = [:api, :admin_mode]

        expect(personal_access_token).to be_valid
      end

      context 'when registry is disabled' do
        before do
          stub_container_registry_config(enabled: false)
        end

        it "rejects creating a token with read_registry scope" do
          personal_access_token.scopes = [:read_registry]

          expect(personal_access_token).not_to be_valid
          expect(personal_access_token.errors[:scopes].first).to eq "can only contain available scopes"
        end

        it "allows revoking a token with read_registry scope" do
          personal_access_token.scopes = [:read_registry]

          personal_access_token.revoke!

          expect(personal_access_token).to be_revoked
        end
      end

      context 'when registry is enabled' do
        before do
          stub_container_registry_config(enabled: true)
        end

        it "allows creating a token with read_registry scope" do
          personal_access_token.scopes = [:read_registry]

          expect(personal_access_token).to be_valid
        end
      end

      it "rejects creating a token with unavailable scopes" do
        personal_access_token.scopes = [:openid, :api]

        expect(personal_access_token).not_to be_valid
        expect(personal_access_token.errors[:scopes].first).to eq "can only contain available scopes"
      end

      it "rejects creating a token with dynamic scopes" do
        personal_access_token.scopes = [:"user:123"]

        expect(personal_access_token).not_to be_valid
        expect(personal_access_token.errors[:scopes].first).to eq "can only contain available scopes"
      end
    end

    describe 'expires_at' do
      before do
        stub_feature_flags(buffered_token_expiration_limit: false)
      end

      let(:max_expiration_date) { Date.current + described_class::MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS }

      it "can't be blank" do
        personal_access_token.expires_at = nil

        expect(personal_access_token).not_to be_valid
        expect(personal_access_token.errors[:expires_at].first).to eq("can't be blank")
      end

      context 'when expires_in is less than MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS days' do
        it 'is valid' do
          personal_access_token.expires_at = max_expiration_date - 1.day

          expect(personal_access_token).to be_valid
        end
      end

      context 'when expires_in is more than MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS days', :freeze_time do
        it 'is invalid' do
          personal_access_token.expires_at = max_expiration_date + 1.day

          expect(personal_access_token).not_to be_valid
          expect(personal_access_token.errors.full_messages.to_sentence).to eq(
            "Expiration date must be before #{max_expiration_date}"
          )
        end
      end

      context 'when application settings does not enforce expiry' do
        before do
          stub_application_setting(require_personal_access_token_expiry: false)
        end

        it 'is valid' do
          personal_access_token.expires_at = nil

          expect(personal_access_token).to be_valid
        end
      end
    end

    describe 'buffered expires_at' do
      let(:max_expiration_date) { Date.current + described_class::MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS_BUFFERED }
      let(:max_unbuffered_expiration_date) { Date.current + described_class::MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS }

      it "can't be blank" do
        personal_access_token.expires_at = nil

        expect(personal_access_token).not_to be_valid
        expect(personal_access_token.errors[:expires_at].first).to eq("can't be blank")
      end

      context 'when expires_in is less than MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS_BUFFERED days' do
        it 'is valid' do
          personal_access_token.expires_at = max_expiration_date - 1.day

          expect(personal_access_token).to be_valid
        end
      end

      context 'when expires_in is less than MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS days' do
        it 'is valid' do
          personal_access_token.expires_at = max_unbuffered_expiration_date - 1.day

          expect(personal_access_token).to be_valid
        end
      end

      context 'when expires_in is more than MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS_BUFFERED days', :freeze_time do
        it 'is invalid' do
          personal_access_token.expires_at = max_expiration_date + 1.day

          expect(personal_access_token).not_to be_valid
          expect(personal_access_token.errors.full_messages.to_sentence).to eq(
            "Expiration date must be before #{max_expiration_date}"
          )
        end
      end
    end
  end

  describe 'scopes' do
    describe '.active' do
      let_it_be(:revoked_token) { create(:personal_access_token, :revoked) }
      let_it_be(:not_revoked_false_token) { create(:personal_access_token, revoked: false) }
      let_it_be(:not_revoked_nil_token) { create(:personal_access_token, revoked: nil) }
      let_it_be(:expired_token) { create(:personal_access_token, :expired) }
      let_it_be(:not_expired_token) { create(:personal_access_token) }

      it 'includes non-revoked tokens' do
        expect(described_class.active)
          .to match_array([not_revoked_false_token, not_revoked_nil_token, not_expired_token])
      end
    end

    describe '.expiring_and_not_notified' do
      let_it_be(:expired_token) { create(:personal_access_token, expires_at: 2.days.ago) }
      let_it_be(:revoked_token) { create(:personal_access_token, revoked: true) }
      let_it_be(:valid_token_and_notified) { create(:personal_access_token, expires_at: 2.days.from_now, expire_notification_delivered: true) }
      let_it_be(:valid_token_and_7d_notified) { create(:personal_access_token, expires_at: 2.days.from_now, seven_days_notification_sent_at: Time.current) }
      let_it_be(:valid_token) { create(:personal_access_token, expires_at: 2.days.from_now) }
      let_it_be(:long_expiry_token) { create(:personal_access_token, expires_at: described_class::MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS.days.from_now) }

      context 'in one day' do
        it "doesn't have any tokens" do
          expect(described_class.expiring_and_not_notified(1.day.from_now)).to be_empty
        end
      end

      context 'in three days' do
        it 'only includes a valid token' do
          expect(described_class.expiring_and_not_notified(3.days.from_now)).to contain_exactly(valid_token)
        end
      end
    end

    context 'with existing tokens' do
      let_it_be(:expired_token) { create(:personal_access_token, expires_at: 2.days.ago) }
      let_it_be(:revoked_token) { create(:personal_access_token, revoked: true) }
      let_it_be(:impersonation_token) { create(:personal_access_token, :impersonation) }
      let_it_be(:valid_token_and_notified) { create(:personal_access_token, expires_at: 2.days.from_now, expire_notification_delivered: true) }
      let_it_be(:valid_token_and_7d_notified) { create(:personal_access_token, expires_at: 2.days.from_now, seven_days_notification_sent_at: Time.current) }
      let_it_be(:valid_token) { create(:personal_access_token, expires_at: 2.days.from_now, impersonation: false) }
      let_it_be(:thirty_days_token) { create(:personal_access_token, expires_at: 28.days.from_now) }
      let_it_be(:sixty_days_token) { create(:personal_access_token, expires_at: 55.days.from_now) }
      let_it_be(:long_expiry_token) { create(:personal_access_token, expires_at: described_class::MAX_PERSONAL_ACCESS_TOKEN_LIFETIME_IN_DAYS.days.from_now) }

      describe '.scope_for_notification_interval' do
        let(:interval) { :seven_days }

        subject(:scope) { described_class.scope_for_notification_interval(interval) }

        it 'returns a scope including expected tokens' do
          expect(scope).to contain_exactly(valid_token)
        end

        context 'with invalid interval' do
          let(:interval) { :one_million_days }

          it 'throws an error' do
            expect(described_class::NOTIFICATION_INTERVALS.keys).not_to include(interval)

            expect { scope }.to raise_error(KeyError)
          end
        end

        context 'with min_expires_at' do
          let_it_be(:five_days_token) { create(:personal_access_token, expires_at: 5.days.from_now, impersonation: false) }
          let(:min_expires_at) { 4.days.from_now }
          let(:max_expires_at) { 8.days.from_now }

          subject(:scope) { described_class.scope_for_notification_interval(:seven_days, min_expires_at: min_expires_at, max_expires_at: max_expires_at) }

          it 'excludes tokens expiring before min_expires_at' do
            expect(scope).to include(five_days_token)
            expect(scope).not_to include(valid_token)
            expect(scope).not_to include(thirty_days_token)
            expect(scope).not_to include(sixty_days_token)
          end

          context 'with past min_expires_at' do
            let(:min_expires_at) { 3.days.ago }

            it 'overrides default expiration interval' do
              expect(scope).to include(expired_token)
              expect(scope).to include(valid_token)
              expect(scope).to include(five_days_token)
            end
          end

          context 'with truncated max_expires_at' do
            let(:min_expires_at) { 1.minute.ago }
            let(:max_expires_at) { 4.days.from_now }

            it 'overrides default expiration interval' do
              expect(scope).to include(valid_token)
              expect(scope).not_to include(five_days_token)
            end
          end
        end

        context 'with 30d interval' do
          let(:interval) { :thirty_days }

          it 'returns a scope including expected tokens' do
            expect(scope).to include(thirty_days_token)
            expect(scope).not_to include(valid_token)
            expect(scope).not_to include(sixty_days_token)
          end
        end

        context 'with 60d interval' do
          let(:interval) { :sixty_days }

          it 'returns a scope including expected tokens' do
            expect(scope).to include(sixty_days_token)
            expect(scope).not_to include(valid_token)
            expect(scope).not_to include(thirty_days_token)
          end
        end
      end

      describe '.expiring_and_not_notified_without_impersonation' do
        context 'when token is there to be notified' do
          it "has only unnotified tokens" do
            expect(described_class.expiring_and_not_notified_without_impersonation).to contain_exactly(valid_token)
          end
        end

        context 'when no token is there to be notified' do
          it "return empty array" do
            valid_token.update!(impersonation: true)

            expect(described_class.expiring_and_not_notified_without_impersonation).to be_empty
          end
        end
      end
    end

    describe '.expired_today_and_not_notified' do
      let_it_be(:active) { create(:personal_access_token) }
      let_it_be(:expired_yesterday) { create(:personal_access_token, expires_at: Date.yesterday) }
      let_it_be(:revoked_token) { create(:personal_access_token, expires_at: Date.current, revoked: true) }
      let_it_be(:expired_today) { create(:personal_access_token, expires_at: Date.current) }
      let_it_be(:expired_today_and_notified) { create(:personal_access_token, expires_at: Date.current, after_expiry_notification_delivered: true) }

      it 'returns tokens that have expired today' do
        expect(described_class.expired_today_and_not_notified).to contain_exactly(expired_today)
      end
    end

    describe '.expired_before' do
      let_it_be(:cut_off) { 3.days.ago }

      let_it_be(:active_token) { create(:personal_access_token) }

      let_it_be(:token_expired_before_cut_off) { create(:personal_access_token, expires_at: cut_off - 1.day) }
      let_it_be(:token_expired_at_cut_off) { create(:personal_access_token, expires_at: cut_off) }
      let_it_be(:token_expired_after_cut_off) { create(:personal_access_token, expires_at: cut_off + 1.day) }

      it 'returns tokens that are expired before date passed in' do
        expect(described_class.expired_before(cut_off)).to contain_exactly(token_expired_before_cut_off)
      end
    end

    describe '.without_impersonation' do
      let_it_be(:impersonation_token) { create(:personal_access_token, :impersonation) }
      let_it_be(:personal_access_token) { create(:personal_access_token) }

      it 'returns only non-impersonation tokens' do
        expect(described_class.without_impersonation).to contain_exactly(personal_access_token)
      end
    end

    describe 'revoke scopes' do
      let_it_be(:revoked_token) { create(:personal_access_token, :revoked) }
      let_it_be(:non_revoked_token) { create(:personal_access_token, revoked: false) }
      let_it_be(:non_revoked_token2) { create(:personal_access_token, revoked: nil) }

      describe '.revoked' do
        it { expect(described_class.revoked).to contain_exactly(revoked_token) }
      end

      describe '.not_revoked' do
        it { expect(described_class.not_revoked).to contain_exactly(non_revoked_token, non_revoked_token2) }
      end

      describe '.revoked_before' do
        let_it_be(:cut_off) { 3.days.ago }

        let_it_be(:token_revoked_before_cut_off) { create(:personal_access_token, :revoked, updated_at: cut_off - 1.second) }
        let_it_be(:token_revoked_at_cut_off) { create(:personal_access_token, :revoked, updated_at: cut_off) }
        let_it_be(:token_revoked_after_cut_off) { create(:personal_access_token, :revoked, updated_at: cut_off + 1.second) }

        let_it_be(:non_revoked_token_updated_before_cut_off) { create(:personal_access_token, updated_at: cut_off - 1.second) }
        let_it_be(:non_revoked_token_updated_at_cut_off) { create(:personal_access_token, updated_at: cut_off) }
        let_it_be(:non_revoked_token_updated_after_cut_off) { create(:personal_access_token, updated_at: cut_off + 1.second) }

        it 'returns tokens that are revoked before date passed in' do
          expect(described_class.revoked_before(cut_off)).to contain_exactly(token_revoked_before_cut_off)
        end
      end
    end
  end

  describe '.simple_sorts' do
    it 'includes overridden keys' do
      expect(described_class.simple_sorts.keys).to include(*%w[expires_at_asc_id_desc])
    end
  end

  describe '.notification_interval' do
    let(:interval) { :seven_days }

    subject(:notification_interval) { described_class.notification_interval(interval) }

    it { is_expected.to eq(7) }

    context 'with invalid interval' do
      let(:interval) { :not_real_interval }

      it 'raises error' do
        expect { notification_interval }.to raise_error(KeyError)
      end
    end
  end

  describe 'ordering by expires_at' do
    let_it_be(:earlier_token) { create(:personal_access_token, expires_at: 2.days.ago) }
    let_it_be(:later_token) { create(:personal_access_token, expires_at: 1.day.ago) }

    describe '.order_expires_at_asc_id_desc' do
      let_it_be(:earlier_token_2) { create(:personal_access_token, expires_at: 2.days.ago) }

      it 'returns ordered list in combination of expires_at ascending and id descending' do
        expect(described_class.order_expires_at_asc_id_desc).to eq [earlier_token_2, earlier_token, later_token]
      end
    end
  end

  it_behaves_like 'TokenAuthenticatable' do
    let(:token_field) { :token }
  end

  describe '#token' do
    let(:random_bytes) { 'a' * Authn::TokenField::Generator::RoutableToken::RANDOM_BYTES_LENGTH }
    let(:devise_token) { 'devise-token' }
    let_it_be(:user) { create(:user) }
    let_it_be(:organization) { create(:organization) }
    let(:token_digest) { nil }
    let(:token_owner_record) do
      create(:personal_access_token,
        organization: organization,
        user: user,
        scopes: [:api],
        token_digest: token_digest)
    end

    subject(:token) { token_owner_record.token }

    before do
      allow(Authn::TokenField::Generator::RoutableToken)
        .to receive(:random_bytes).with(Authn::TokenField::Generator::RoutableToken::RANDOM_BYTES_LENGTH)
        .and_return(random_bytes)
      allow(Devise).to receive(:friendly_token).and_return(devise_token)
      allow(Settings).to receive(:cell).and_return({ id: 1 })
    end

    context 'when :routable_pat feature flag is disabled' do
      before do
        stub_feature_flags(routable_pat: false)
      end

      it_behaves_like 'a digested token' do
        let(:expected_token) { token }
        let(:expected_token_payload) { devise_token }
        let(:expected_token_prefix) { described_class.token_prefix }
        let(:expected_token_digest) { token_owner_record.token_digest }
      end
    end

    shared_examples 'a routable token' do
      context 'when token_digest is not set yet' do
        it_behaves_like 'a digested routable token' do
          let(:expected_token) { token }
          let(:expected_routing_payload) { "c:1\no:#{organization.id.to_s(36)}\nu:#{user.id.to_s(36)}" }
          let(:expected_random_bytes) { random_bytes }
          let(:expected_token_prefix) { described_class.token_prefix }
          let(:expected_token_digest) { token_owner_record.token_digest }
        end
      end

      context 'with token_digest already generated' do
        let(:token_digest) { 's3cr3t' }

        it 'does not change the token' do
          expect(token).to be_nil
          expect(token_owner_record.token_digest).to eq(token_digest)
        end
      end
    end

    context 'when :routable_pat feature flag is enabled for the user' do
      before do
        stub_feature_flags(routable_pat: token_owner_record.user)
      end

      it_behaves_like 'a routable token'
    end

    context 'when :routable_pat feature flag is enabled globally' do
      before do
        stub_feature_flags(routable_pat: true)
      end

      it_behaves_like 'a routable token'
    end
  end
end
