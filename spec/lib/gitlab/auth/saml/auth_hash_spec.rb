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
end
