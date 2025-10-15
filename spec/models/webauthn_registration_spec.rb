# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebauthnRegistration, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let_it_be(:webauthn_device) { create(:webauthn_registration, user: user) } # default second_factor
  let_it_be(:passkey) { create(:webauthn_registration, :passkey, user: user) }
  let_it_be(:second_factor_authenticator) { create(:webauthn_registration, :second_factor, user: user) }
  let_it_be(:second_factor_authenticator2) { create(:webauthn_registration, :passkey_eligible, user: user) }

  describe 'relations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations', :aggregate_failures do
    it { is_expected.to validate_presence_of(:credential_xid) }
    it { is_expected.to validate_presence_of(:public_key) }
    it { is_expected.to validate_presence_of(:counter) }
    it { is_expected.to validate_presence_of(:authentication_mode) }
    it { is_expected.to validate_inclusion_of(:passkey_eligible).in_array([true, false]) }
    it { is_expected.to validate_length_of(:name).is_at_least(0) }
    it { is_expected.not_to allow_value(nil).for(:name) }

    it do
      is_expected.to validate_numericality_of(:counter)
          .only_integer
          .is_greater_than_or_equal_to(0)
          .is_less_than_or_equal_to(4294967295)
    end
  end

  describe 'enums' do
    let(:modes) do
      {
        passwordless: 1,
        second_factor: 2
      }
    end

    it { is_expected.to define_enum_for(:authentication_mode).with_values(modes) }
  end

  describe 'scopes' do
    describe '.passkey' do
      it 'returns all passkeys' do
        expect(described_class.passkey).to eq([passkey])
      end
    end

    describe '.second_factor_authenticator' do
      it 'returns all second_factor_authenticators' do
        expect(described_class.second_factor_authenticator).to match_array(
          [webauthn_device, second_factor_authenticator, second_factor_authenticator2]
        )
      end
    end
  end
end
