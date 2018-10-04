require 'spec_helper'

describe Gitlab::Auth::Saml::AuthHash do
  include LoginHelpers

  let(:raw_info_attr) { { 'groups' => %w(Developers Freelancers) } }
  subject(:saml_auth_hash) { described_class.new(omniauth_auth_hash) }

  let(:info_hash) do
    {
      name: 'John',
      email: 'john@mail.com'
    }
  end

  let(:omniauth_auth_hash) do
    OmniAuth::AuthHash.new(uid: 'my-uid',
                           provider: 'saml',
                           info: info_hash,
                           extra: { raw_info: OneLogin::RubySaml::Attributes.new(raw_info_attr) } )
  end

  before do
    stub_saml_group_config(%w(Developers Freelancers Designers))
  end

  describe '#groups' do
    it 'returns array of groups' do
      expect(saml_auth_hash.groups).to eq(%w(Developers Freelancers))
    end

    context 'raw info hash attributes empty' do
      let(:raw_info_attr) { {} }

      it 'returns an empty array' do
        expect(saml_auth_hash.groups).to be_a(Array)
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

    context 'without response_object' do
      it 'returns an empty string' do
        expect(saml_auth_hash.authn_context).to be_nil
      end
    end
  end
end
