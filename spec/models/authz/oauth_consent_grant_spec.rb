# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Authz::OauthConsentGrant, feature_category: :permissions do
  describe 'associations' do
    it { is_expected.to belong_to(:organization).required }
    it { is_expected.to belong_to(:user).required }
    it { is_expected.to belong_to(:application).class_name('Authn::OauthApplication').required }
    it { is_expected.to have_many(:oauth_consent_grant_granular_scopes).autosave(true) }
    it { is_expected.to have_many(:granular_scopes).through(:oauth_consent_grant_granular_scopes) }
  end

  describe 'sharding key' do
    let_it_be(:user) { create(:user) }

    subject { build(:oauth_consent_grant, user: user, organization_id: nil) }

    it { is_expected.to populate_sharding_key(:organization_id).with(user.organization_id) }
  end

  describe 'enums' do
    it { is_expected.to define_enum_for(:status).with_values(authorized: 0, revoked: 1) }

    it 'defines the source enum' do
      is_expected.to define_enum_for(:source)
        .with_values(doorkeeper: 0, iam_consent: 1, trusted_auto_grant: 2, duo_session: 3)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:source) }
  end

  describe 'active grant uniqueness' do
    let_it_be(:user) { create(:user) }
    let_it_be(:application) { create(:oauth_application) }

    let!(:grant) { create(:oauth_consent_grant, user: user, application: application) }

    it 'rejects a second authorized grant for the same user and application' do
      expect { create(:oauth_consent_grant, user: user, application: application) }
        .to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allows a new authorized grant once the existing one is revoked' do
      grant.revoked!

      expect { create(:oauth_consent_grant, user: user, application: application) }.not_to raise_error
    end

    it 'allows another authorized grant for the same user and another application' do
      expect { create(:oauth_consent_grant, user: user) }.not_to raise_error
    end

    it 'allows multiple authorized duo_session grants for the same user and application' do
      create(:oauth_consent_grant, user: user, application: application, source: :duo_session)

      expect { create(:oauth_consent_grant, user: user, application: application, source: :duo_session) }
        .not_to raise_error
    end
  end
end
