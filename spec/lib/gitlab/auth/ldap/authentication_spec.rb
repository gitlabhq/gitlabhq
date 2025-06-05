# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Ldap::Authentication do
  include LdapHelpers

  let(:provider) { 'ldapmain' }
  let(:uid) { 'john' }
  let(:dn) { user_dn(uid) }
  let(:user) { create(:omniauth_user, :ldap, extern_uid: dn) }
  let(:login) { uid }
  let(:password) { 'password' }

  before do
    stub_ldap_setting(enabled: true)
  end

  describe '.login' do
    it "finds the user if authentication is successful" do
      expect(user).not_to be_nil

      # try only to fake the LDAP call
      adapter = double('adapter', dn: dn).as_null_object
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:adapter).and_return(adapter)
      end

      expect(described_class.login(login, password)).to be_truthy
    end

    it "is false if the user does not exist" do
      # try only to fake the LDAP call
      adapter = double('adapter', dn: dn).as_null_object
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:adapter).and_return(adapter)
      end

      expect(described_class.login(login, password)).to be_falsey
    end

    it "is false if authentication fails" do
      expect(user).not_to be_nil

      # try only to fake the LDAP call
      adapter = double('adapter', bind_as: nil).as_null_object
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:adapter).and_return(adapter)
      end

      expect(described_class.login(login, password)).to be_falsey
    end

    it "fails if ldap is disabled" do
      allow(Gitlab::Auth::Ldap::Config).to receive(:enabled?).and_return(false)
      expect(described_class.login(login, password)).to be_falsey
    end

    it "fails if no login is supplied" do
      expect(described_class.login('', password)).to be_falsey
    end

    it "fails if no password is supplied" do
      expect(described_class.login(login, '')).to be_falsey
    end
  end

  describe '#login' do
    let(:adapter) { instance_double(OmniAuth::LDAP::Adaptor) }

    before do
      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:adapter).and_return(adapter)
      end
    end

    context 'with GitLab username' do
      subject(:authentication) { described_class.new(provider, user).login(login, password) }

      let(:login) { user.username }

      it "identifies the user's LDAP UID and uses it for authentication" do
        stub_ldap_person_find_by_dn(ldap_user_entry(uid), provider)

        expect(adapter).to receive(:bind_as).with(
          filter: Net::LDAP::Filter.equals(Gitlab::Auth::Ldap::Config.new(provider).uid, uid),
          size: 1,
          password: password
        ).and_return(ldap_user_entry(uid))

        expect(authentication).to eq(user)
      end

      context "when the user's LDAP UID cannot be identified" do
        it 'uses specified login for authentication' do
          stub_ldap_person_find_by_dn(nil, provider)

          expect(adapter).to receive(:bind_as).with(
            filter: Net::LDAP::Filter.equals(Gitlab::Auth::Ldap::Config.new(provider).uid, login),
            size: 1,
            password: password
          )

          expect(authentication).to be_nil
        end
      end

      context 'when the user is not a LDAP user' do
        let(:user) { create(:user) }

        it "does not try to identify the user's LDAP UID and and uses specified login for authentication" do
          expect(::Gitlab::Auth::Ldap::Person).not_to receive(:find_by_dn)

          expect(adapter).to receive(:bind_as).with(
            filter: Net::LDAP::Filter.equals(Gitlab::Auth::Ldap::Config.new(provider).uid, login),
            size: 1,
            password: password
          )

          expect(authentication).to be_nil
        end
      end
    end

    context 'with LDAP UID that does not match GitLab username' do
      subject(:authentication) { described_class.new(provider).login(login, password) }

      let(:login) { uid }

      it "does not try to identify the user's LDAP UID and and uses specified login for authentication" do
        expect(user).not_to be_nil

        expect(::Gitlab::Auth::Ldap::Person).not_to receive(:find_by_dn)

        expect(adapter).to receive(:bind_as).with(
          filter: Net::LDAP::Filter.equals(Gitlab::Auth::Ldap::Config.new(provider).uid, login),
          size: 1,
          password: password
        ).and_return(ldap_user_entry(login))

        expect(authentication).to eq(user)
      end
    end
  end
end
