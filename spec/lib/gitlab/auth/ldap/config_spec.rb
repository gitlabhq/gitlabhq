require 'spec_helper'

describe Gitlab::Auth::LDAP::Config do
  include LdapHelpers

  let(:config) { described_class.new('ldapmain') }

  describe '.servers' do
    it 'returns empty array if no server information is available' do
      allow(Gitlab.config).to receive(:ldap).and_return('enabled' => false)

      expect(described_class.servers).to eq []
    end
  end

  describe '#initialize' do
    it 'requires a provider' do
      expect { described_class.new }.to raise_error ArgumentError
    end

    it 'works' do
      expect(config).to be_a described_class
    end

    it 'raises an error if a unknown provider is used' do
      expect { described_class.new 'unknown' }.to raise_error(RuntimeError)
    end
  end

  describe '#adapter_options' do
    it 'constructs basic options' do
      stub_ldap_config(
        options: {
          'host'       => 'ldap.example.com',
          'port'       => 386,
          'encryption' => 'plain'
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
          'host'                => 'ldap.example.com',
          'port'                => 686,
          'encryption'          => 'simple_tls',
          'verify_certificates' => true,
          'bind_dn'             => 'uid=admin,dc=example,dc=com',
          'password'            => 'super_secret'
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
          'host'                => 'ldap.example.com',
          'port'                => 686,
          'encryption'          => 'simple_tls'
        }
      )

      expect(config.adapter_options[:encryption]).to include({ method: :simple_tls })
    end

    it 'sets encryption method to start_tls when configured as start_tls' do
      stub_ldap_config(
        options: {
          'host'                => 'ldap.example.com',
          'port'                => 686,
          'encryption'          => 'start_tls'
        }
      )

      expect(config.adapter_options[:encryption]).to include({ method: :start_tls })
    end

    context 'when verify_certificates is enabled' do
      it 'sets tls_options to OpenSSL defaults' do
        stub_ldap_config(
          options: {
            'host'                => 'ldap.example.com',
            'port'                => 686,
            'encryption'          => 'simple_tls',
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
            'host'                => 'ldap.example.com',
            'port'                => 686,
            'encryption'          => 'simple_tls',
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
            'host'                => 'ldap.example.com',
            'port'                => 686,
            'encryption'          => 'simple_tls',
            'ca_file'             => '/etc/ca.pem'
          }
        )

        expect(config.adapter_options[:encryption][:tls_options]).to include({ ca_file: '/etc/ca.pem' })
      end
    end

    context 'when ca_file is a blank string' do
      it 'does not add the ca_file key to tls_options' do
        stub_ldap_config(
          options: {
            'host'                => 'ldap.example.com',
            'port'                => 686,
            'encryption'          => 'simple_tls',
            'ca_file'             => ' '
          }
        )

        expect(config.adapter_options[:encryption][:tls_options]).not_to have_key(:ca_file)
      end
    end

    context 'when ssl_version is specified' do
      it 'passes it through in tls_options' do
        stub_ldap_config(
          options: {
            'host'                => 'ldap.example.com',
            'port'                => 686,
            'encryption'          => 'simple_tls',
            'ssl_version'         => 'TLSv1_2'
          }
        )

        expect(config.adapter_options[:encryption][:tls_options]).to include({ ssl_version: 'TLSv1_2' })
      end
    end

    context 'when ssl_version is a blank string' do
      it 'does not add the ssl_version key to tls_options' do
        stub_ldap_config(
          options: {
            'host'                => 'ldap.example.com',
            'port'                => 686,
            'encryption'          => 'simple_tls',
            'ssl_version'         => ' '
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
          'host'       => 'ldap.example.com',
          'port'       => 386,
          'base'       => 'ou=users,dc=example,dc=com',
          'encryption' => 'plain',
          'uid'        => 'uid'
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

    context 'when verify_certificates is enabled' do
      it 'specifies disable_verify_certificates as false' do
        stub_ldap_config(
          options: {
            'host'                => 'ldap.example.com',
            'port'                => 686,
            'encryption'          => 'simple_tls',
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
            'host'                => 'ldap.example.com',
            'port'                => 686,
            'encryption'          => 'simple_tls',
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
            'host'                => 'ldap.example.com',
            'port'                => 686,
            'encryption'          => 'simple_tls',
            'verify_certificates' => true,
            'ca_file'             => '/etc/ca.pem'
          }
        )

        expect(config.omniauth_options).to include({ ca_file: '/etc/ca.pem' })
      end
    end

    context 'when ca_file is blank' do
      it 'does not include the ca_file option' do
        stub_ldap_config(
          options: {
            'host'                => 'ldap.example.com',
            'port'                => 686,
            'encryption'          => 'simple_tls',
            'verify_certificates' => true,
            'ca_file'             => ' '
          }
        )

        expect(config.omniauth_options).not_to have_key(:ca_file)
      end
    end

    context 'when ssl_version is present' do
      it 'passes it through' do
        stub_ldap_config(
          options: {
            'host'                => 'ldap.example.com',
            'port'                => 686,
            'encryption'          => 'simple_tls',
            'verify_certificates' => true,
            'ssl_version'         => 'TLSv1_2'
          }
        )

        expect(config.omniauth_options).to include({ ssl_version: 'TLSv1_2' })
      end
    end

    context 'when ssl_version is blank' do
      it 'does not include the ssl_version option' do
        stub_ldap_config(
          options: {
            'host'                => 'ldap.example.com',
            'port'                => 686,
            'encryption'          => 'simple_tls',
            'verify_certificates' => true,
            'ssl_version'         => ' '
          }
        )

        expect(config.omniauth_options).not_to have_key(:ssl_version)
      end
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
