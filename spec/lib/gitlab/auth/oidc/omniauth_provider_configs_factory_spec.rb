# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'omniauth_provider_config factory', feature_category: :system_access do
  it 'creates a valid Gitlab::Configs::Options instance' do
    config = build(:omniauth_provider_config)

    expect(config).to be_a(Gitlab::Configs::Options)
    expect(config.name).to eq('openid_connect')
  end

  it 'works with stub_omniauth_setting helper' do
    config = build(:omniauth_provider_config)

    stub_omniauth_setting(enabled: true, providers: [config])

    expect(Gitlab.config.omniauth.enabled).to be(true)
    expect(Gitlab.config.omniauth.providers.first.name).to eq('openid_connect')
  end
end
