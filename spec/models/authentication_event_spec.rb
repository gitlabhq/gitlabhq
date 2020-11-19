# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthenticationEvent do
  describe 'associations' do
    it { is_expected.to belong_to(:user).optional }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_presence_of(:user_name) }
    it { is_expected.to validate_presence_of(:result) }

    include_examples 'validates IP address' do
      let(:attribute) { :ip_address }
      let(:object) { create(:authentication_event) }
    end
  end

  describe 'scopes' do
    let_it_be(:ldap_event) { create(:authentication_event, provider: :ldapmain, result: :failed) }
    let_it_be(:google_oauth2) { create(:authentication_event, provider: :google_oauth2, result: :success) }

    describe '.for_provider' do
      it 'returns events only for the specified provider' do
        expect(described_class.for_provider(:ldapmain)).to match_array ldap_event
      end
    end

    describe '.ldap' do
      it 'returns all events for an LDAP provider' do
        expect(described_class.ldap).to match_array ldap_event
      end
    end
  end

  describe '.providers' do
    before do
      allow(Devise).to receive(:omniauth_providers).and_return(%w(ldapmain google_oauth2))
    end

    it 'returns an array of distinct providers' do
      expect(described_class.providers).to match_array %w(ldapmain google_oauth2 standard two-factor two-factor-via-u2f-device two-factor-via-webauthn-device)
    end
  end
end
