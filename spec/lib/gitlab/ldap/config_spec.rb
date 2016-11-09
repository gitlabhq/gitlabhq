require 'spec_helper'

describe Gitlab::LDAP::Config, lib: true do
  include LdapHelpers

  let(:config) { Gitlab::LDAP::Config.new('ldapmain') }

  describe '#initalize' do
    it 'requires a provider' do
      expect{ Gitlab::LDAP::Config.new }.to raise_error ArgumentError
    end

    it 'works' do
      expect(config).to be_a described_class
    end

    it "raises an error if a unknow provider is used" do
      expect{ Gitlab::LDAP::Config.new 'unknown' }.to raise_error(Gitlab::LDAP::Config::InvalidProvider)
    end
  end

  describe '#has_auth?' do
    it 'is true when password is set' do
      stub_ldap_config(
        options: {
          'bind_dn'  => 'uid=admin,dc=example,dc=com',
          'password' => 'super_secret'
        }
      )

      expect(config.has_auth?).to be_truthy
    end

    it 'is true when bind_dn is set and password is empty' do
      stub_ldap_config(
        options: {
          'bind_dn'  => 'uid=admin,dc=example,dc=com',
          'password' => ''
        }
      )

      expect(config.has_auth?).to be_truthy
    end

    it 'is false when password and bind_dn are not set' do
      stub_ldap_config(options: { 'bind_dn' => nil, 'password' => nil })

      expect(config.has_auth?).to be_falsey
    end
  end
end
