# frozen_string_literal: true

require 'spec_helper'

describe ::Gitlab::LetsEncrypt do
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
end
