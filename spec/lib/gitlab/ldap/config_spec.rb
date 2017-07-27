require 'spec_helper'

describe Gitlab::LDAP::Config do
  include LdapHelpers

  let(:config) { described_class.new('ldapmain') }

  describe '#initalize' do
    it 'requires a provider' do
      expect{ described_class.new }.to raise_error ArgumentError
    end

    it 'works' do
      expect(config).to be_a described_class
    end

    it "raises an error if a unknow provider is used" do
      expect{ described_class.new 'unknown' }.to raise_error(Gitlab::LDAP::Config::InvalidProvider)
    end
  end

  describe '#adapter_options' do
    it 'constructs basic options' do
      stub_ldap_config(
        options: {
          'host'    => 'ldap.example.com',
          'port'    => 386,
          'method'  => 'plain'
        }
      )

      expect(config.adapter_options).to eq(
        host: 'ldap.example.com',
        port: 386,
        encryption: nil
      )
    end

    it 'includes authentication options when auth is configured' do
      stub_ldap_config(
        options: {
          'host'      => 'ldap.example.com',
          'port'      => 686,
          'method'    => 'ssl',
          'bind_dn'   => 'uid=admin,dc=example,dc=com',
          'password'  => 'super_secret'
        }
      )

      expect(config.adapter_options).to eq(
        host: 'ldap.example.com',
        port: 686,
        encryption: :simple_tls,
        auth: {
          method: :simple,
          username: 'uid=admin,dc=example,dc=com',
          password: 'super_secret'
        }
      )
    end
  end

  describe '#omniauth_options' do
    it 'constructs basic options' do
      stub_ldap_config(
        options: {
          'host'    => 'ldap.example.com',
          'port'    => 386,
          'base'    => 'ou=users,dc=example,dc=com',
          'method'  => 'plain',
          'uid'     => 'uid'
        }
      )

      expect(config.omniauth_options).to include(
        host: 'ldap.example.com',
        port: 386,
        base: 'ou=users,dc=example,dc=com',
        method: 'plain',
        filter: '(uid=%{username})'
      )
      expect(config.omniauth_options.keys).not_to include(:bind_dn, :password)
    end

    it 'includes authentication options when auth is configured' do
      stub_ldap_config(
        options: {
          'uid'         => 'sAMAccountName',
          'user_filter' => '(memberOf=cn=group1,ou=groups,dc=example,dc=com)',
          'bind_dn'     => 'uid=admin,dc=example,dc=com',
          'password'    => 'super_secret'
        }
      )

      expect(config.omniauth_options).to include(
        filter: '(&(sAMAccountName=%{username})(memberOf=cn=group1,ou=groups,dc=example,dc=com))',
        bind_dn: 'uid=admin,dc=example,dc=com',
        password: 'super_secret'
      )
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

  describe '#attributes' do
    it 'uses default attributes when no custom attributes are configured' do
      expect(config.attributes).to eq(config.default_attributes)
    end

    it 'merges the configuration attributes with default attributes' do
      stub_ldap_config(
        options: {
          'attributes' => {
            'username' => %w(sAMAccountName),
            'email'    => %w(userPrincipalName)
          }
        }
      )

      expect(config.attributes).to include({
        'username' => %w(sAMAccountName),
        'email'    => %w(userPrincipalName),
        'name'     => 'cn'
      })
    end
  end
end
