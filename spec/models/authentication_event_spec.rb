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
      allow(Devise).to receive(:omniauth_providers).and_return(%w[ldapmain google_oauth2])
    end

    it 'returns an array of distinct providers' do
      expect(described_class.providers).to match_array %w[ldapmain google_oauth2 standard two-factor two-factor-via-u2f-device two-factor-via-webauthn-device]
    end
  end

  describe '.initial_login_or_known_ip_address?' do
    let_it_be(:user) { create(:user) }
    let_it_be(:ip_address) { '127.0.0.1' }

    subject { described_class.initial_login_or_known_ip_address?(user, ip_address) }

    context 'on first login, when no record exists yet' do
      it { is_expected.to eq(true) }
    end

    context 'on second login from the same ip address' do
      before do
        create(:authentication_event, :successful, user: user, ip_address: ip_address)
      end

      it { is_expected.to eq(true) }
    end

    context 'on second login from another ip address' do
      before do
        create(:authentication_event, :successful, user: user, ip_address: '1.2.3.4')
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '.most_used_ip_address_for_user' do
    let_it_be(:user) { create(:user) }
    let_it_be(:most_used_ip_address) { '::1' }
    let_it_be(:another_ip_address) { '127.0.0.1' }

    subject { described_class.most_used_ip_address_for_user(user) }

    before do
      create_list(:authentication_event, 2, user: user, ip_address: most_used_ip_address)
      create(:authentication_event, user: user, ip_address: another_ip_address)
    end

    it { is_expected.to eq(most_used_ip_address) }
  end
end
