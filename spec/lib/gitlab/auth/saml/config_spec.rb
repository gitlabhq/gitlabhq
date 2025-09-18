# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Saml::Config do
  include LoginHelpers

  describe '.enabled?' do
    subject { described_class.enabled? }

    it { is_expected.to eq(false) }

    context 'when SAML is enabled' do
      before do
        stub_basic_saml_config
      end

      it { is_expected.to eq(true) }
    end
  end

  describe '.default_attribute_statements' do
    it 'includes upstream defaults, nickname and Microsoft values' do
      expect(described_class.default_attribute_statements).to eq(
        {
          nickname: [
            'username',
            'nickname',
            'urn:oid:0.9.2342.19200300.100.1.1'
          ],
          name: [
            'name',
            'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name',
            'http://schemas.microsoft.com/ws/2008/06/identity/claims/name',
            'urn:oid:2.16.840.1.113730.3.1.241',
            'urn:oid:2.5.4.3'
          ],
          email: [
            'email',
            'mail',
            'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress',
            'http://schemas.microsoft.com/ws/2008/06/identity/claims/emailaddress',
            'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/email',
            'http://schemas.microsoft.com/ws/2008/06/identity/claims/email',
            'urn:oid:0.9.2342.19200300.100.1.3'
          ],
          first_name: [
            'first_name',
            'firstname',
            'firstName',
            'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname',
            'http://schemas.microsoft.com/ws/2008/06/identity/claims/givenname',
            'urn:oid:2.5.4.42'
          ],
          last_name: [
            'last_name',
            'lastname',
            'lastName',
            'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname',
            'http://schemas.microsoft.com/ws/2008/06/identity/claims/surname',
            'urn:oid:2.5.4.4'
          ]
        }
      )
    end
  end

  describe '#external_groups' do
    let(:config_1) { described_class.new('saml1') }

    let(:config_2) { described_class.new('saml2') }

    before do
      saml1_config = ActiveSupport::InheritableOptions.new(name: 'saml1', label: 'saml1', args: {
        'strategy_class' => 'OmniAuth::Strategies::SAML'
      })

      saml2_config = ActiveSupport::InheritableOptions.new(name: 'saml2',
        external_groups: ['FreeLancers'],
        label: 'saml2',
        args: {
          'strategy_class' => 'OmniAuth::Strategies::SAML'
        })

      stub_omniauth_setting(enabled: true, auto_link_saml_user: true, providers: [saml1_config, saml2_config])
    end

    it "lists groups" do
      expect(config_1.external_groups).to be_nil
      expect(config_2.external_groups).to be_eql(['FreeLancers'])
    end
  end
end
