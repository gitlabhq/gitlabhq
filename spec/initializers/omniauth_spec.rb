# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OmniAuth initializer for GitLab' do
  def load_omniauth_initializer
    load Rails.root.join('config/initializers/omniauth.rb')
  end

  describe '#full_host' do
    subject { OmniAuth.config.full_host }

    let(:base_url) { 'http://localhost/test' }

    before do
      allow(Settings).to receive(:gitlab).and_return({ 'base_url' => base_url })
      allow(Gitlab::OmniauthInitializer).to receive(:full_host).and_return('proc')

      load_omniauth_initializer
    end

    # to clear existing mocks and prevent order-dependent failures
    after(:all) do
      load_omniauth_initializer
    end

    it { is_expected.to eq('proc') }
  end
end
