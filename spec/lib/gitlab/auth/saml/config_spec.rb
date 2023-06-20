# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Saml::Config do
  describe '.enabled?' do
    subject { described_class.enabled? }

    it { is_expected.to eq(false) }

    context 'when SAML is enabled' do
      before do
        allow(Gitlab::Auth::OAuth::Provider).to receive(:providers).and_return([:saml])
      end

      it { is_expected.to eq(true) }
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
