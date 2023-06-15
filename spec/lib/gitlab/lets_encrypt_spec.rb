# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::LetsEncrypt, feature_category: :pages do
  include LetsEncryptHelpers

  before do
    stub_lets_encrypt_settings
  end

  describe '.enabled?' do
    subject { described_class.enabled? }

    context 'when terms of service are accepted' do
      it { is_expected.to eq(true) }
    end

    context 'when terms of service are not accepted' do
      before do
        stub_application_setting(lets_encrypt_terms_of_service_accepted: false)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '.terms_of_service_url' do
    before do
      stub_lets_encrypt_client
    end

    subject { described_class.terms_of_service_url }

    it 'returns the url' do
      is_expected.to eq("https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf")
    end
  end
end
