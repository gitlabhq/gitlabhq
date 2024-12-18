# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Ldap::Config, feature_category: :system_access do
  include LdapHelpers

  before do
    stub_ldap_setting(enabled: true)
  end

  let(:config) { described_class.new('ldapmain') }

  def raw_cert
    <<-EOS
-----BEGIN CERTIFICATE-----
MIIDZjCCAk4CCQDX+u/9fICksDANBgkqhkiG9w0BAQsFADB1MQswCQYDVQQGEwJV
UzEMMAoGA1UECAwDRm9vMQwwCgYDVQQHDANCYXIxDDAKBgNVBAoMA0JhejEMMAoG
A1UECwwDUXV4MQ0wCwYDVQQDDARsZGFwMR8wHQYJKoZIhvcNAQkBFhBsZGFwQGV4
YW1wbGUuY29tMB4XDTE5MDIyNzE1NTUxNFoXDTE5MDMyOTE1NTUxNFowdTELMAkG
A1UEBhMCVVMxDDAKBgNVBAgMA0ZvbzEMMAoGA1UEBwwDQmFyMQwwCgYDVQQKDANC
YXoxDDAKBgNVBAsMA1F1eDENMAsGA1UEAwwEbGRhcDEfMB0GCSqGSIb3DQEJARYQ
bGRhcEBleGFtcGxlLmNvbTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
APuDB/4/AUmTEmhYzN13no4Kt8hkRbLQuENRHlOeQw05/MVdoB1AWLOPzIXn4kex
GD9tHkoJl8S0QPmAAcPHn5O97e+gd0ze5dRQZl/cSd2/j5zeaMvZ1mCrPN/dOluM
94Oj+wQU4bEcOlrqIMSh0ezJw10R3IHXCQFeGtIZU57WmKcrryQX4kP7KTOgRw/t
CYp+NivQHtLbBEj1MU0l10qMS2+w8Qpqov4MdW4gx4wTgId2j1ZZ56+n6Jsc9qoI
wBWBNL4XU5a3kwhYZDOJoOvI9po33KLdT1dXS81uOFXClp3LGmKDgLTwQ1w+RmQG
+JG4EvTfDIShdcTDXEaOfCECAwEAATANBgkqhkiG9w0BAQsFAAOCAQEAJM9Btu5g
k8qDiz5TilvpyoGuI4viCwusARFAFmOB/my/cHlVvkuq4bbfV1KJoWWGJg8GcklL
cnIdxc35uYM5icr6xXQyrW0GqAO+LEXyUxVQqYETxrQ/LJ03xhBnuF7hvZJIBiky
GwUy0clJxGfaCeEM8zXwePawLgGjuUawDDQOwigysoWqoMu3VFW8zl8UPa84bow9
Kn2QmPAkLw4EcqYSCNSSvnyzu5SM64jwLWRXFsmlqD7773oT29vTkqM1EQANFEfT
7gQomLyPqoPBoFph5oSNn6Rf31QX1Sie92EAKVnZ1XmD68hKzjv6ChCtzTv4jABg
XrDwnLkORIAF/Q==
-----END CERTIFICATE-----
    EOS
  end

  def raw_key
    <<-EOS
-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQD7gwf+PwFJkxJo
WMzdd56OCrfIZEWy0LhDUR5TnkMNOfzFXaAdQFizj8yF5+JHsRg/bR5KCZfEtED5
gAHDx5+Tve3voHdM3uXUUGZf3Endv4+c3mjL2dZgqzzf3TpbjPeDo/sEFOGxHDpa
6iDEodHsycNdEdyB1wkBXhrSGVOe1pinK68kF+JD+ykzoEcP7QmKfjYr0B7S2wRI
9TFNJddKjEtvsPEKaqL+DHVuIMeME4CHdo9WWeevp+ibHPaqCMAVgTS+F1OWt5MI
WGQziaDryPaaN9yi3U9XV0vNbjhVwpadyxpig4C08ENcPkZkBviRuBL03wyEoXXE
w1xGjnwhAgMBAAECggEAbw82GVui6uUpjLAhjm3CssAi1TcJ2+L0aq1IMe5Bd3ay
mkg0apY+VNPboQl6zuNxbJh3doPz42UhB8sxfE0Ktwd4KIb4Bxap7+2stwmkCGoN
NVy0c8d2NWuHzuZ2XXTK2vMu5Wd/HWD0l66o14sJEoEpZlB7yU216UevmjSayxjh
aBTSaYyyrf24haTaCuqwph/V73ZlMpFdSALGny0uiP/5inxciMCkMpHfX6BflSb4
EGKsIYt9BJ0kY4GNG5bCP7971UCxp2eEJhU2fV8HuFGCOD12IqSpUqPxHxjsWpfx
T7FZ3V2kM/58Ca+5LB2y3atcPIdY0/g7/43V4VD+7QKBgQD/PO4/0cmZuuLU1LPT
C/C596kPK0JLlvvRqhbz4byRAkW/n7uQFG7TMtFNle3UmT7rk7pjtbHnByqzEd+9
jMhBysjHOMg0+DWm7fEtSg/tJ3qLVO3nbdA4qmXYobLcLoG+PCYRLskEHHqTG/Bv
QZLbavOU6rrTqckNr1TMpNBmXwKBgQD8Q0C2YTOpwgjRUe8i6Chnc3o4x8a1i98y
9la6c7y7acWHSbEczMkNfEBrbM73rTb+bBA0Zqw+Z1gkv8bGpvGxX8kbSfJJ2YKW
9koxpLNTVNVapqBa9ImiaozV285dz9Ukx8bnMOJlTELpOl7RRV7iF0smYjfHIl3D
Yxyda/MtfwKBgHb9l/Dmw77IkqE4PFFimqqIHCe3OiP1UpavXh36midcUNoCBLYp
4HTTlyI9iG/5tYysBVQgy7xx6eUrqww6Ss3pVOsTvLp9EL4u5aYAhiZApm+4e2TO
HCmevvZcg/8EK3Zdoj2Wex5QjJBykQe9IVLrrH07ZTfySon3uGfjWkivAoGAGvqS
VC8HGHOw/7n0ilYr5Ax8mM/813OzFj80PVKdb6m7P2HJOFxKcE/Gj/aeF+0FgaZL
AV+tsirZSWzdNGesV5z35Bw/dlh11/FVNAP6TcI34y8I3VFj2uPsVf7hDjVpBTr8
ccNPoyfJzCm69ESoBiQZnGxKrNhnELtr1wYxhr8CgYApWwf4hVrTWV1zs+pEJenh
AtlErSqafbECNDSwS5BX8yDpu5yRBJ4xegO/rNlmb8ICRYkuJapD1xXicFOsmfUK
0Ff8afd2Q/OfBeUdq9KA4JO9fNqzEwOWvv8Ryn4ZSYcAuLP7IVJKjjI6R7rYaO/G
3OWJdizbykGOi0BFDu+3dw==
-----END PRIVATE KEY-----
    EOS
  end

  describe '.servers' do
    it 'returns empty array if no server information is available' do
      stub_ldap_setting(servers: {})

      expect(described_class.servers).to eq []
    end
  end

  describe '.available_providers' do
    before do
      stub_licensed_features(multiple_ldap_servers: false)
      stub_ldap_setting(
        'servers' => {
          'main' => { 'provider_name' => 'ldapmain' },
          'secondary' => { 'provider_name' => 'ldapsecondary' }
        }
      )
    end

    it 'returns one provider' do
      expect(described_class.available_providers).to match_array(%w[ldapmain])
    end
  end

  describe '#initialize' do
    it 'requires a provider' do
      expect { described_class.new }.to raise_error ArgumentError
    end

    it 'returns an instance of Gitlab::Auth::Ldap::Config' do
      expect(config).to be_a described_class
    end

    it 'raises an error if a unknown provider is used' do
      expect { described_class.new 'unknown' }.to raise_error(described_class::InvalidProvider)
    end
  end

  describe '#adapter_options' do
    it 'constructs basic options' do
      stub_ldap_config(
        options: {
          'host' => 'ldap.example.com',
          'port' => 386,
          'encryption' => 'plain'
        }
      )

      expect(config.adapter_options).to eq(
        host: 'ldap.example.com',
        port: 386,
        hosts: nil,
        encryption: nil,
        instrumentation_service: ActiveSupport::Notifications
      )
    end

    it 'includes failover hosts when set' do
      stub_ldap_config(
        options: {
          'host' => 'ldap.example.com',
          'port' => 686,
          'hosts' => [
            ['ldap1.example.com', 636],
            ['ldap2.example.com', 636]
          ],
          'encryption' => 'simple_tls',
          'verify_certificates' => true,
          'bind_dn' => 'uid=admin,dc=example,dc=com',
          'password' => 'super_secret'
        }
      )

      expect(config.adapter_options).to include({
        hosts: [
          ['ldap1.example.com', 636],
          ['ldap2.example.com', 636]
        ],
        auth: {
          method: :simple,
          username: 'uid=admin,dc=example,dc=com',
          password: 'super_secret'
        }
      })
    end

    it 'includes authentication options when auth is configured' do
      stub_ldap_config(
        options: {
          'host' => 'ldap.example.com',
          'port' => 686,
          'encryption' => 'simple_tls',
          'verify_certificates' => true,
          'bind_dn' => 'uid=admin,dc=example,dc=com',
          'password' => 'super_secret'
        }
      )

      expect(config.adapter_options).to include({
        auth: {
          method: :simple,
          username: 'uid=admin,dc=example,dc=com',
          password: 'super_secret'
        }
      })
    end

    it 'sets encryption method to simple_tls when configured as simple_tls' do
      stub_ldap_config(
        options: {
          'host' => 'ldap.example.com',
          'port' => 686,
          'encryption' => 'simple_tls'
        }
      )

      expect(config.adapter_options[:encryption]).to include({ method: :simple_tls })
    end

    it 'sets encryption method to start_tls when configured as start_tls' do
      stub_ldap_config(
        options: {
          'host' => 'ldap.example.com',
          'port' => 686,
          'encryption' => 'start_tls'
        }
      )

      expect(config.adapter_options[:encryption]).to include({ method: :start_tls })
    end

    it 'transforms SSL cert and key to OpenSSL objects' do
      stub_ldap_config(
        options: {
          'host' => 'ldap.example.com',
          'port' => 686,
          'encryption' => 'start_tls',
          'tls_options' => {
            'cert' => raw_cert,
            'key' => raw_key
          }
        }
      )

      expect(config.adapter_options[:encryption][:tls_options][:cert]).to be_a(OpenSSL::X509::Certificate)
      expect(config.adapter_options[:encryption][:tls_options][:key]).to be_a(OpenSSL::PKey::RSA)
    end

    it 'logs an error when an invalid key or cert are configured' do
      allow(Gitlab::AppLogger).to receive(:error)
      stub_ldap_config(
        options: {
          'host' => 'ldap.example.com',
          'port' => 686,
          'encryption' => 'start_tls',
          'tls_options' => {
            'cert' => 'invalid cert',
            'key' => 'invalid_key'
          }
        }
      )

      config.adapter_options

      expect(Gitlab::AppLogger).to have_received(:error).with(/LDAP TLS Options/).twice
    end

    context 'when verify_certificates is enabled' do
      it 'sets tls_options to OpenSSL defaults' do
        stub_ldap_config(
          options: {
            'host' => 'ldap.example.com',
            'port' => 686,
            'encryption' => 'simple_tls',
            'verify_certificates' => true
          }
        )

        expect(config.adapter_options[:encryption]).to include({ tls_options: OpenSSL::SSL::SSLContext::DEFAULT_PARAMS })
      end
    end

    context 'when verify_certificates is disabled' do
      it 'sets verify_mode to OpenSSL VERIFY_NONE' do
        stub_ldap_config(
          options: {
            'host' => 'ldap.example.com',
            'port' => 686,
            'encryption' => 'simple_tls',
            'verify_certificates' => false
          }
        )

        expect(config.adapter_options[:encryption]).to include({
          tls_options: {
            verify_mode: OpenSSL::SSL::VERIFY_NONE
          }
        })
      end
    end

    context 'when ca_file is specified' do
      it 'passes it through in tls_options' do
        stub_ldap_config(
          options: {
            'host' => 'ldap.example.com',
            'port' => 686,
            'encryption' => 'simple_tls',
            'tls_options' => {
              'ca_file' => '/etc/ca.pem'
            }
          }
        )

        expect(config.adapter_options[:encryption][:tls_options]).to include({ ca_file: '/etc/ca.pem' })
      end
    end

    context 'when ca_file is a blank string' do
      it 'does not add the ca_file key to tls_options' do
        stub_ldap_config(
          options: {
            'host' => 'ldap.example.com',
            'port' => 686,
            'encryption' => 'simple_tls',
            'tls_options' => {
              'ca_file' => ' '
            }
          }
        )

        expect(config.adapter_options[:encryption][:tls_options]).not_to have_key(:ca_file)
      end
    end

    context 'when ssl_version is specified' do
      it 'passes it through in tls_options' do
        stub_ldap_config(
          options: {
            'host' => 'ldap.example.com',
            'port' => 686,
            'encryption' => 'simple_tls',
            'tls_options' => {
              'ssl_version' => 'TLSv1_2'
            }
          }
        )

        expect(config.adapter_options[:encryption][:tls_options]).to include({ ssl_version: 'TLSv1_2' })
      end
    end

    context 'when ssl_version is a blank string' do
      it 'does not add the ssl_version key to tls_options' do
        stub_ldap_config(
          options: {
            'host' => 'ldap.example.com',
            'port' => 686,
            'encryption' => 'simple_tls',
            'tls_options' => {
              'ssl_version' => ' '
            }
          }
        )

        expect(config.adapter_options[:encryption][:tls_options]).not_to have_key(:ssl_version)
      end
    end
  end

  describe '#omniauth_options' do
    it 'constructs basic options' do
      stub_ldap_config(
        options: {
          'host' => 'ldap.example.com',
          'port' => 386,
          'base' => 'ou=users,dc=example,dc=com',
          'encryption' => 'plain',
          'uid' => 'uid'
        }
      )

      expect(config.omniauth_options).to include(
        host: 'ldap.example.com',
        port: 386,
        base: 'ou=users,dc=example,dc=com',
        encryption: 'plain',
        filter: '(uid=%{username})'
      )
      expect(config.omniauth_options.keys).not_to include(:bind_dn, :password)
    end

    it 'defaults to plain encryption when not configured' do
      stub_ldap_config(
        options: {
          'host' => 'ldap.example.com',
          'port' => 386,
          'base' => 'ou=users,dc=example,dc=com',
          'uid' => 'uid'
        }
      )

      expect(config.omniauth_options).to include(encryption: 'plain')
    end

    it 'includes authentication options when auth is configured' do
      stub_ldap_config(
        options: {
          'uid' => 'sAMAccountName',
          'user_filter' => '(memberOf=cn=group1,ou=groups,dc=example,dc=com)',
          'bind_dn' => 'uid=admin,dc=example,dc=com',
          'password' => 'super_secret'
        }
      )

      expect(config.omniauth_options).to include(
        filter: '(&(sAMAccountName=%{username})(memberOf=cn=group1,ou=groups,dc=example,dc=com))',
        bind_dn: 'uid=admin,dc=example,dc=com',
        password: 'super_secret'
      )
    end

    it 'transforms SSL cert and key to OpenSSL objects' do
      stub_ldap_config(
        options: {
          'host' => 'ldap.example.com',
          'port' => 686,
          'encryption' => 'start_tls',
          'tls_options' => {
            'cert' => raw_cert,
            'key' => raw_key
          }
        }
      )

      expect(config.omniauth_options[:tls_options][:cert]).to be_a(OpenSSL::X509::Certificate)
      expect(config.omniauth_options[:tls_options][:key]).to be_a(OpenSSL::PKey::RSA)
    end

    context 'when verify_certificates is enabled' do
      it 'specifies disable_verify_certificates as false' do
        stub_ldap_config(
          options: {
            'host' => 'ldap.example.com',
            'port' => 686,
            'encryption' => 'simple_tls',
            'verify_certificates' => true
          }
        )

        expect(config.omniauth_options).to include({ disable_verify_certificates: false })
      end
    end

    context 'when verify_certificates is disabled' do
      it 'specifies disable_verify_certificates as true' do
        stub_ldap_config(
          options: {
            'host' => 'ldap.example.com',
            'port' => 686,
            'encryption' => 'simple_tls',
            'verify_certificates' => false
          }
        )

        expect(config.omniauth_options).to include({ disable_verify_certificates: true })
      end
    end

    context 'when ca_file is present' do
      it 'passes it through' do
        stub_ldap_config(
          options: {
            'host' => 'ldap.example.com',
            'port' => 686,
            'encryption' => 'simple_tls',
            'verify_certificates' => true,
            'tls_options' => {
              'ca_file' => '/etc/ca.pem'
            }
          }
        )

        expect(config.omniauth_options[:tls_options]).to include({ ca_file: '/etc/ca.pem' })
      end
    end

    context 'when ca_file is blank' do
      it 'does not include the ca_file option' do
        stub_ldap_config(
          options: {
            'host' => 'ldap.example.com',
            'port' => 686,
            'encryption' => 'simple_tls',
            'verify_certificates' => true,
            'tls_options' => {
              'ca_file' => ' '
            }
          }
        )

        expect(config.omniauth_options[:tls_options]).not_to have_key(:ca_file)
      end
    end

    context 'when ssl_version is present' do
      it 'passes it through' do
        stub_ldap_config(
          options: {
            'host' => 'ldap.example.com',
            'port' => 686,
            'encryption' => 'simple_tls',
            'verify_certificates' => true,
            'tls_options' => {
              'ssl_version' => 'TLSv1_2'
            }
          }
        )

        expect(config.omniauth_options[:tls_options]).to include({ ssl_version: 'TLSv1_2' })
      end
    end

    context 'when ssl_version is blank' do
      it 'does not include the ssl_version option' do
        stub_ldap_config(
          options: {
            'host' => 'ldap.example.com',
            'port' => 686,
            'encryption' => 'simple_tls',
            'verify_certificates' => true,
            'tls_options' => {
              'ssl_version' => ' '
            }
          }
        )

        # OpenSSL default params includes `ssl_version` so we just check that it's not blank
        expect(config.omniauth_options[:tls_options]).not_to include({ ssl_version: ' ' })
      end
    end
  end

  describe '#has_auth?' do
    it 'is true when password is set' do
      stub_ldap_config(
        options: {
          'bind_dn' => 'uid=admin,dc=example,dc=com',
          'password' => 'super_secret'
        }
      )

      expect(config.has_auth?).to be_truthy
    end

    it 'is true when bind_dn is set and password is empty' do
      stub_ldap_config(
        options: {
          'bind_dn' => 'uid=admin,dc=example,dc=com',
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
            'username' => %w[sAMAccountName],
            'email' => %w[userPrincipalName]
          }
        }
      )

      expect(config.attributes).to include({
        'username' => %w[sAMAccountName],
        'email' => %w[userPrincipalName],
        'name' => 'cn'
      })
    end
  end

  describe '#default_attributes' do
    it 'includes the configured uid attribute in the username attributes' do
      stub_ldap_config(options: { 'uid' => 'my_uid_attr' })

      expect(config.default_attributes['username']).to include('my_uid_attr')
    end

    it 'only includes unique values for username attributes' do
      stub_ldap_config(options: { 'uid' => 'uid' })

      expect(config.default_attributes['username']).to contain_exactly('uid', 'sAMAccountName', 'userid')
    end
  end

  describe '#base' do
    context 'when the configured base is not normalized' do
      it 'returns the normalized base' do
        stub_ldap_config(options: { 'base' => 'DC=example, DC= com' })

        expect(config.base).to eq('dc=example,dc=com')
      end
    end

    context 'when the configured base is normalized' do
      it 'returns the base unaltered' do
        stub_ldap_config(options: { 'base' => 'dc=example,dc=com' })

        expect(config.base).to eq('dc=example,dc=com')
      end
    end

    context 'when the configured base is malformed' do
      it 'returns the base unaltered' do
        stub_ldap_config(options: { 'base' => 'invalid,dc=example,dc=com' })

        expect(config.base).to eq('invalid,dc=example,dc=com')
      end
    end

    context 'when the configured base is blank' do
      it 'returns the base unaltered' do
        stub_ldap_config(options: { 'base' => '' })

        expect(config.base).to eq('')
      end
    end
  end

  describe '#duo_add_on_groups' do
    it 'returns empty array when not set' do
      expect(config.duo_add_on_groups).to be_empty
    end

    context 'when the config is set' do
      before do
        stub_ldap_config(options: { duo_add_on_groups: %w[duo_group_1 duo_group_2] })
      end

      it 'returns configured duo_add_on_groups array' do
        expect(config.duo_add_on_groups).to match_array(%w[duo_group_1 duo_group_2])
      end
    end
  end

  describe 'sign_in_enabled?' do
    using RSpec::Parameterized::TableSyntax

    where(:enabled, :prevent_ldap_sign_in, :result) do
      true | false | true
      'true' | false | true
      true | true | false
      false | nil | false
    end

    with_them do
      it do
        stub_ldap_setting(enabled: enabled, prevent_ldap_sign_in: prevent_ldap_sign_in)

        expect(described_class.sign_in_enabled?).to eq(result)
      end
    end
  end

  describe 'smartcard_ad_cert_format' do
    it 'returns the value contained in options' do
      stub_ldap_config(options: { 'smartcard_ad_cert_format' => 'issuer_and_serial_number' })
      expect(config.smartcard_ad_cert_format).to eq('issuer_and_serial_number')
    end
  end

  describe 'smartcard_ad_cert_field' do
    subject(:smartcard_ad_cert_field) { config.smartcard_ad_cert_field }

    it { is_expected.to eq('altSecurityIdentities') }

    context 'when config value is set' do
      before do
        stub_ldap_config(options: { 'smartcard_ad_cert_field' => 'extensionAttribute1' })
      end

      it { is_expected.to eq('extensionAttribute1') }
    end
  end
end
