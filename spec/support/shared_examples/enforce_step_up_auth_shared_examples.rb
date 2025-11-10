# frozen_string_literal: true

RSpec.shared_examples 'enforces step-up authentication' do
  let(:oidc_provider_config) do
    GitlabSettings::Options.new(
      name: 'openid_connect',
      step_up_auth: {
        namespace: {
          id_token: {
            required: { acr: 'gold' }
          }
        }
      }
    )
  end

  let(:oidc_provider_name) { oidc_provider_config.name }

  let(:session_step_up_succeeded) do
    { 'omniauth_step_up_auth' => {
      oidc_provider_name => { 'namespace' => { 'state' => 'succeeded' } }
    } }
  end

  let(:session_step_up_failed) do
    { 'omniauth_step_up_auth' => {
      oidc_provider_name => { 'namespace' => { 'state' => 'failed' } }
    } }
  end

  # Default: no session data (nested contexts can override)
  let(:session_data) { nil }

  before do
    stub_omniauth_setting(enabled: true, providers: [oidc_provider_config])
    allow(Devise).to receive(:omniauth_providers).and_return([oidc_provider_name])

    # Handle session stubbing centrally
    if session_data
      test_session = ActionController::TestSession.new({
        'warden.user.user.key' => [[user.id], user.authenticatable_salt]
      }.merge(session_data))

      allow_next_instance_of(ActionDispatch::Request) do |instance|
        allow(instance).to receive(:session).and_return(test_session)
      end
    end
  end

  context 'when group requires step-up auth' do
    before do
      group.namespace_settings.update!(step_up_auth_required_oauth_provider: oidc_provider_name)
    end

    context 'when step-up auth has not been completed' do
      it 'redirects to step-up auth page' do
        subject

        expect(response).to redirect_to(new_group_step_up_auth_path(group))
        expect(response).to have_gitlab_http_status(:found)
      end

      it 'sets flash notice about step-up auth requirement' do
        subject

        expect(flash[:notice]).to include('Step-up authentication required')
      end
    end

    context 'when step-up auth session is failed' do
      let(:session_data) { session_step_up_failed }

      it 'redirects to step-up auth page' do
        subject

        expect(response).to redirect_to(new_group_step_up_auth_path(group))
        expect(response).to have_gitlab_http_status(:found)
      end
    end

    context 'when step-up auth session is succeeded' do
      let(:session_data) { session_step_up_succeeded }

      it 'allows access to the action' do
        subject

        expect(response).to have_gitlab_http_status(expected_success_status)
        expect(response).not_to redirect_to(new_group_step_up_auth_path(group))
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(omniauth_step_up_auth_for_namespace: false)
      end

      it 'allows access without step-up auth' do
        subject

        expect(response).to have_gitlab_http_status(expected_success_status)
        expect(response).not_to redirect_to(new_group_step_up_auth_path(group))
      end
    end
  end

  context 'when group does not require step-up auth' do
    before do
      group.namespace_settings.update!(step_up_auth_required_oauth_provider: nil)
    end

    it 'allows access without step-up auth' do
      subject

      expect(response).to have_gitlab_http_status(expected_success_status)
      expect(response).not_to redirect_to(new_group_step_up_auth_path(group))
    end
  end
end

RSpec.shared_examples 'does not enforce step-up authentication' do
  let(:oidc_provider_config) do
    GitlabSettings::Options.new(
      name: 'openid_connect',
      step_up_auth: {
        namespace: {
          id_token: {
            required: { acr: 'gold' }
          }
        }
      }
    )
  end

  let(:oidc_provider_name) { oidc_provider_config.name }

  before do
    stub_omniauth_setting(enabled: true, providers: [oidc_provider_config])
    allow(Devise).to receive(:omniauth_providers).and_return([oidc_provider_name])
    group.namespace_settings.update!(step_up_auth_required_oauth_provider: oidc_provider_name)
  end

  it 'allows access without step-up auth' do
    subject

    expect(response).to have_gitlab_http_status(expected_success_status)
    expect(response).not_to redirect_to(new_group_step_up_auth_path(group))
  end
end
