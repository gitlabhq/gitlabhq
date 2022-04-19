# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OmniAuth initializer for GitLab' do
  let(:load_omniauth_initializer) do
    load Rails.root.join('config/initializers/omniauth.rb')
  end

  describe '#full_host' do
    subject { OmniAuth.config.full_host }

    let(:base_url) { 'http://localhost/test' }

    before do
      allow(Settings).to receive(:gitlab).and_return({ 'base_url' => base_url })
      allow(Gitlab::OmniauthInitializer).to receive(:full_host).and_return('proc')
    end

    context 'with feature flags not available' do
      before do
        expect(Feature).to receive(:feature_flags_available?).and_return(false)
        load_omniauth_initializer
      end

      it { is_expected.to eq(base_url) }
    end

    context 'with the omniauth_initializer_fullhost_proc FF disabled' do
      before do
        stub_feature_flags(omniauth_initializer_fullhost_proc: false)
        load_omniauth_initializer
      end

      it { is_expected.to eq(base_url) }
    end

    context 'with the omniauth_initializer_fullhost_proc FF disabled' do
      before do
        load_omniauth_initializer
      end

      it { is_expected.to eq('proc') }
    end
  end
end
