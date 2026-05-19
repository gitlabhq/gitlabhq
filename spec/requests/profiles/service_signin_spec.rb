# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Service sign-in', feature_category: :system_access do
  include LoginHelpers

  let(:user) { create(:user, :with_namespace, username: 'foo') }

  before do
    sign_in(user)
  end

  context 'when an identity does not exist' do
    before do
      allow(Devise).to receive_messages(omniauth_configs: { google_oauth2: {} })
    end

    it 'allows the user to connect' do
      get profile_two_factor_auth_path

      expect(response.body).to include('Connect Google')
      expect(response.body).to include('/users/auth/google_oauth2')
    end
  end

  context 'when an identity already exists' do
    before do
      stub_omniauth_setting(enabled: true, providers: [
        GitlabSettings::Options.new(name: 'google_oauth2'),
        GitlabSettings::Options.new(name: 'saml')
      ])

      allow(Devise).to receive(:omniauth_providers).and_return([:google_oauth2, :saml])

      create(:identity, user: user, provider: :google_oauth2)
      create(:identity, user: user, provider: :saml)
    end

    it 'allows the user to disconnect when there is an existing identity' do
      get profile_two_factor_auth_path

      expect(response.body).to include('Disconnect Google')
      expect(response.body).to include('/-/profile/account/unlink?provider=google_oauth2')
    end

    it 'shows active for a provider that is not allowed to unlink' do
      get profile_two_factor_auth_path

      expect(response.body).to include('Saml')
      expect(response.body).to include('Active')
    end

    context "with federated identities" do
      before do
        stub_omniauth_setting(enabled: true, providers: [
          GitlabSettings::Options.new(name: 'iam_github')
        ])
        allow(Devise).to receive(:omniauth_providers).and_return([:github, :iam_github])
        allow_next_instance_of(ActionDispatch::Routing::RoutesProxy) do |instance|
          allow(instance).to receive(:user_iam_github_omniauth_authorize_path)
            .and_return('/users/auth/iam_github')
        end
      end

      it 'allows the user to connect' do
        get profile_two_factor_auth_path
        expect(response.body).to include('Connect GitHub')
        expect(response.body).to include('/users/auth/iam_github')
      end

      it 'allows the user to disconnect' do
        create(:identity, user: user, provider: :github)

        get profile_two_factor_auth_path
        expect(response.body).to include('Disconnect GitHub')
        expect(response.body).to include('/-/profile/account/unlink?provider=github')
      end
    end
  end
end
