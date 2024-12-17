# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Saml::AuthHash, feature_category: :system_access do
  include LoginHelpers

  let(:raw_info_attr) { { 'groups' => %w[Developers Freelancers] } }
  subject(:saml_auth_hash) { described_class.new(omniauth_auth_hash) }

  let(:info_hash) do
    {
      name: 'John',
      email: 'john@mail.com'
    }
  end

  let(:omniauth_auth_hash) do
    OmniAuth::AuthHash.new(
      uid: 'my-uid',
      provider: 'saml',
      info: info_hash,
      extra: { raw_info: OneLogin::RubySaml::Attributes.new(raw_info_attr) }
    )
  end

  before do
    stub_saml_group_config(%w[Developers Freelancers Designers])
  end

  describe '#groups' do
    it 'returns array of groups' do
      expect(saml_auth_hash.groups).to eq(%w[Developers Freelancers])
    end

    context 'raw info hash attributes empty' do
      let(:raw_info_attr) { {} }

      it 'returns an empty array' do
        expect(saml_auth_hash.groups).to be_a(Array)
      end
    end
  end

  describe '#azure_group_overage_claim?' do
    context 'when the claim is not present' do
      let(:raw_info_attr) { {} }

      it 'is false' do
        expect(saml_auth_hash.azure_group_overage_claim?).to eq(false)
      end
    end

    context 'when the claim is present' do
      # The value of the claim is irrelevant, but it's still included
      # in the test response to keep tests as real-world as possible.
      # https://learn.microsoft.com/en-us/security/zero-trust/develop/configure-tokens-group-claims-app-roles#group-overages
      let(:raw_info_attr) do
        {
          'http://schemas.microsoft.com/claims/groups.link' =>
            ['https://graph.windows.net/8c750e43/users/e631c82c/getMemberObjects']
        }
      end

      it 'is true' do
        expect(saml_auth_hash.azure_group_overage_claim?).to eq(true)
      end
    end
  end

  describe '#authn_context' do
    let(:auth_hash_data) do
      {
        provider: 'saml',
        uid: 'some_uid',
        info:
          {
            name: 'mockuser',
            email: 'mock@email.ch',
            image: 'mock_user_thumbnail_url'
          },
        credentials:
          {
            token: 'mock_token',
            secret: 'mock_secret'
          },
        extra:
          {
            raw_info:
              {
                info:
                  {
                    name: 'mockuser',
                    email: 'mock@email.ch',
                    image: 'mock_user_thumbnail_url'
                  }
              }
          }
      }
    end

    subject(:saml_auth_hash) { described_class.new(OmniAuth::AuthHash.new(auth_hash_data)) }

    context 'with response_object' do
      before do
        auth_hash_data[:extra][:response_object] = { document:
                                                         saml_xml(File.read('spec/fixtures/authentication/saml_response.xml')) }
      end

      it 'can extract authn_context' do
        expect(saml_auth_hash.authn_context).to eq 'urn:oasis:names:tc:SAML:2.0:ac:classes:Password'
      end
    end

    context 'with SAML 2.0 response_object' do
      before do
        auth_hash_data[:extra][:response_object] = { document:
                                                         saml_xml(File.read('spec/fixtures/authentication/saml2_response.xml')) }
      end

      it 'can extract authn_context' do
        expect(saml_auth_hash.authn_context).to eq 'urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport'
      end
    end

    context 'with ADFS SAML response_object' do
      before do
        auth_hash_data[:extra][:response_object] = { document:
                                                         saml_xml(File.read('spec/fixtures/authentication/adfs_saml_response.xml')) }
      end

      it 'can extract authn_context' do
        expect(saml_auth_hash.authn_context).to eq 'urn:federation:authentication:windows'
      end
    end

    context 'without response_object' do
      it 'returns an empty string' do
        expect(saml_auth_hash.authn_context).to be_nil
      end
    end
  end
end
