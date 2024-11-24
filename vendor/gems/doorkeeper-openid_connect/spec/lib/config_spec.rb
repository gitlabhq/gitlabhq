# frozen_string_literal: true

require 'rails_helper'

describe Doorkeeper::OpenidConnect, 'configuration' do
  subject { described_class.configuration }

  describe '#configure' do
    it 'fails if not set to :active_record' do
      # stub ORM setup to avoid Doorkeeper exceptions
      allow(Doorkeeper).to receive(:setup_orm_adapter)
      allow(Doorkeeper).to receive(:setup_orm_models)
      allow(Doorkeeper).to receive(:setup_application_owner)

      Doorkeeper.configure do
        orm :mongoid
      end

      expect do
        described_class.configure {}
      end.to raise_error Doorkeeper::OpenidConnect::Errors::InvalidConfiguration
    end
  end

  describe 'jws_private_key' do
    it 'delegates to signing_key' do
      value = 'private_key'
      described_class.configure do
        jws_private_key value
      end
      expect(subject.signing_key).to eq(value)
    end
  end

  describe 'signing_key' do
    it 'sets the value that is accessible via signing_key' do
      value = 'private_key'
      described_class.configure do
        signing_key value
      end
      expect(subject.signing_key).to eq(value)
    end
  end

  describe 'issuer' do
    it 'sets the value that is accessible via issuer' do
      value = 'issuer'
      described_class.configure do
        issuer value
      end
      expect(subject.issuer).to eq(value)
    end

    it 'sets the block that is accessible via issuer' do
      block = proc {}
      described_class.configure do
        issuer(&block)
      end
      expect(subject.issuer).to eq(block)
    end
  end

  describe 'resource_owner_from_access_token' do
    it 'sets the block that is accessible via resource_owner_from_access_token' do
      block = proc {}
      described_class.configure do
        resource_owner_from_access_token(&block)
      end
      expect(subject.resource_owner_from_access_token).to eq(block)
    end

    it 'fails if unset' do
      described_class.configure {}

      expect do
        subject.resource_owner_from_access_token.call
      end.to raise_error Doorkeeper::OpenidConnect::Errors::InvalidConfiguration
    end
  end

  describe 'auth_time_from_resource_owner' do
    it 'sets the block that is accessible via auth_time_from_resource_owner' do
      block = proc {}
      described_class.configure do
        auth_time_from_resource_owner(&block)
      end
      expect(subject.auth_time_from_resource_owner).to eq(block)
    end

    it 'fails if unset' do
      described_class.configure {}

      expect do
        subject.auth_time_from_resource_owner.call
      end.to raise_error Doorkeeper::OpenidConnect::Errors::InvalidConfiguration
    end
  end

  describe 'reauthenticate_resource_owner' do
    it 'sets the block that is accessible via reauthenticate_resource_owner' do
      block = proc {}
      described_class.configure do
        reauthenticate_resource_owner(&block)
      end
      expect(subject.reauthenticate_resource_owner).to eq(block)
    end

    it 'fails if unset' do
      described_class.configure {}

      expect do
        subject.reauthenticate_resource_owner.call
      end.to raise_error Doorkeeper::OpenidConnect::Errors::InvalidConfiguration
    end
  end

  describe 'select_account_for_resource_owner' do
    it 'sets the block that is accessible via select_account_for_resource_owner' do
      block = proc {}
      described_class.configure do
        select_account_for_resource_owner(&block)
      end
      expect(subject.select_account_for_resource_owner).to eq(block)
    end

    it 'fails if unset' do
      described_class.configure {}

      expect do
        subject.select_account_for_resource_owner.call
      end.to raise_error Doorkeeper::OpenidConnect::Errors::InvalidConfiguration
    end
  end

  describe 'subject' do
    it 'sets the block that is accessible via subject' do
      block = proc {}
      described_class.configure do
        subject(&block)
      end
      expect(subject.subject).to eq(block)
    end

    it 'fails if unset' do
      described_class.configure {}

      expect do
        subject.subject.call
      end.to raise_error Doorkeeper::OpenidConnect::Errors::InvalidConfiguration
    end
  end

  describe 'expiration' do
    it 'sets the value that is accessible via expiration' do
      value = 'expiration'
      described_class.configure do
        expiration value
      end
      expect(subject.expiration).to eq(value)
    end
  end

  describe 'claims' do
    it 'sets the claims configuration that is accessible via claims' do
      described_class.configure do
        claims do
        end
      end
      expect(subject.claims).not_to be_nil
    end
  end

  describe 'protocol' do
    it 'defaults to https in production' do
      expect(::Rails.env).to receive(:production?).and_return(true)

      expect(subject.protocol.call).to eq(:https)
    end

    it 'defaults to http in other environments' do
      expect(::Rails.env).to receive(:production?).and_return(false)

      expect(subject.protocol.call).to eq(:http)
    end

    it 'can be set to other protocols' do
      described_class.configure do
        protocol { :ftp }
      end

      expect(subject.protocol.call).to eq(:ftp)
    end
  end

  describe 'end_session_endpoint' do
    it 'defaults to nil' do
      expect(subject.end_session_endpoint.call).to be_nil
    end

    it 'can be set to a custom url' do
      described_class.configure do
        end_session_endpoint { 'http://test.host/logout' }
      end

      expect(subject.end_session_endpoint.call).to eq('http://test.host/logout')
    end
  end

  describe 'discovery_url_options' do
    it 'defaults to empty hash' do
      expect(subject.discovery_url_options.call).to be_kind_of(Hash)
      expect(subject.discovery_url_options.call).to be_empty
    end

    it 'can be set to other hosts' do
      Doorkeeper::OpenidConnect.configure do
        discovery_url_options do |request|
          {
            authorization: { host: 'alternate-authorization-host' },
            token: { host: 'alternate-token-host' },
            revocation: { host: 'alternate-revocation-host' },
            introspection: { host: 'alternate-introspection-host' },
            userinfo: { host: 'alternate-userinfo-host' },
            jwks: { host: 'alternate-jwks-host' }
          }
        end
      end

      expect(subject.discovery_url_options.call[:authorization]).to eq(host: 'alternate-authorization-host')
    end
  end
end
