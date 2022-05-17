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
end
