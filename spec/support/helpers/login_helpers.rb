# frozen_string_literal: true

require_relative 'devise_helpers'

module LoginHelpers
  include DeviseHelpers

  # Overriding Devise::Test::IntegrationHelpers#sign_in to store @current_user
  # since we may need it in LiveDebugger#live_debug.
  def sign_in(resource, scope: nil)
    super

    @current_user = resource
  end

  # Overriding Devise::Test::IntegrationHelpers#sign_out to clear @current_user.
  def sign_out(resource_or_scope)
    super

    @current_user = nil
  end

  # Internal: Log in as a specific user or a new user of a specific role
  #
  # user_or_role - User object, or a role to create (e.g., :admin, :user)
  #
  # Examples:
  #
  #   # Create a user automatically
  #   gitlab_sign_in(:user)
  #
  #   # Create an admin automatically
  #   gitlab_sign_in(:admin)
  #
  #   # Provide an existing User record
  #   user = create(:user)
  #   gitlab_sign_in(user)
  def gitlab_sign_in(user_or_role, **kwargs)
    user =
      if user_or_role.is_a?(User)
        user_or_role
      else
        create(user_or_role) # rubocop:disable Rails/SaveBang
      end

    gitlab_sign_in_with(user, **kwargs)

    @current_user = user
  end

  def gitlab_enable_admin_mode_sign_in(user)
    visit new_admin_session_path
    fill_in 'user_password', with: user.password
    click_button 'Enter Admin Mode'
  end

  def gitlab_sign_in_via(provider, user, uid, saml_response = nil)
    mock_auth_hash_with_saml_xml(provider, uid, user.email, saml_response)
    visit new_user_session_path
    click_button provider
  end

  def gitlab_enable_admin_mode_sign_in_via(provider, user, uid, saml_response = nil)
    mock_auth_hash_with_saml_xml(provider, uid, user.email, saml_response)
    visit new_admin_session_path
    click_button provider
  end

  # Requires Javascript driver.
  def gitlab_sign_out
    find(".header-user-dropdown-toggle").click
    click_link "Sign out"
    @current_user = nil

    expect(page).to have_button('Sign in')
  end

  # Requires Javascript driver.
  def gitlab_disable_admin_mode
    open_top_nav

    within_top_nav do
      click_on 'Leave Admin Mode'
    end
  end

  private

  # Private: Login as the specified user
  #
  # user     - User instance to login with
  # remember - Whether or not to check "Remember me" (default: false)
  def gitlab_sign_in_with(user, remember: false)
    visit new_user_session_path

    fill_in "user_login", with: user.email
    fill_in "user_password", with: "12345678"
    check 'user_remember_me' if remember

    click_button "Sign in"
  end

  def login_via(provider, user, uid, remember_me: false, additional_info: {})
    mock_auth_hash(provider, uid, user.email, additional_info: additional_info)
    visit new_user_session_path
    expect(page).to have_content('Sign in with')

    check 'remember_me' if remember_me

    click_button "oauth-login-#{provider}"
  end

  def fake_successful_u2f_authentication
    allow(U2fRegistration).to receive(:authenticate).and_return(true)
    FakeU2fDevice.new(page, nil).fake_u2f_authentication
  end

  def fake_successful_webauthn_authentication
    allow_any_instance_of(Webauthn::AuthenticateService).to receive(:execute).and_return(true)
    FakeWebauthnDevice.new(page, nil).fake_webauthn_authentication
  end

  def mock_auth_hash_with_saml_xml(provider, uid, email, saml_response)
    response_object = { document: saml_xml(saml_response) }
    mock_auth_hash(provider, uid, email, response_object: response_object)
  end

  def configure_mock_auth(provider, uid, email, response_object: nil, additional_info: {})
    # The mock_auth configuration allows you to set per-provider (or default)
    # authentication hashes to return during integration testing.

    OmniAuth.config.mock_auth[provider.to_sym] = OmniAuth::AuthHash.new({
      provider: provider,
      uid: uid,
      info: {
        name: 'mockuser',
        email: email,
        image: 'mock_user_thumbnail_url'
      },
      credentials: {
        token: 'mock_token',
        secret: 'mock_secret'
      },
      extra: {
        raw_info: OneLogin::RubySaml::Attributes.new(
          {
            info: {
              name: 'mockuser',
              email: email,
              image: 'mock_user_thumbnail_url'
            }
          }
        ),
        response_object: response_object
      }
    }).merge(additional_info) { |_, old_hash, new_hash| old_hash.merge(new_hash) }
  end

  def mock_auth_hash(provider, uid, email, additional_info: {}, response_object: nil)
    configure_mock_auth(provider, uid, email, additional_info: additional_info, response_object: response_object)

    original_env_config_omniauth_auth = Rails.application.env_config['omniauth.auth']
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[provider.to_sym]

    original_env_config_omniauth_auth
  end

  def saml_xml(raw_saml_response)
    return '' if raw_saml_response.blank?

    XMLSecurity::SignedDocument.new(raw_saml_response, [])
  end

  def mock_saml_config
    OpenStruct.new(name: 'saml', label: 'saml', args: {
      assertion_consumer_service_url: 'https://localhost:3443/users/auth/saml/callback',
      idp_cert_fingerprint: '26:43:2C:47:AF:F0:6B:D0:07:9C:AD:A3:74:FE:5D:94:5F:4E:9E:52',
      idp_sso_target_url: 'https://idp.example.com/sso/saml',
      issuer: 'https://localhost:3443/',
      name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient'
    })
  end

  def mock_saml_config_with_upstream_two_factor_authn_contexts
    config = mock_saml_config
    config.args[:upstream_two_factor_authn_contexts] = %w(urn:oasis:names:tc:SAML:2.0:ac:classes:CertificateProtectedTransport
                                                          urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorOTPSMS
                                                          urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorIGTOKEN)
    config
  end

  def stub_omniauth_provider(provider, context: Rails.application)
    env = env_from_context(context)

    set_devise_mapping(context: context)
    env['omniauth.auth'] = OmniAuth.config.mock_auth[provider.to_sym]
  end

  def stub_omniauth_failure(strategy, message_key, exception = nil)
    env = @request.env

    env['omniauth.error'] = exception
    env['omniauth.error.type'] = message_key.to_sym
    env['omniauth.error.strategy'] = strategy
  end

  def stub_omniauth_saml_config(context: Rails.application, **messages)
    set_devise_mapping(context: context)
    routes = Rails.application.routes
    routes.disable_clear_and_finalize = true
    routes.formatter.clear
    routes.draw do
      post '/users/auth/saml' => 'omniauth_callbacks#saml'
    end
    saml_config = messages.key?(:providers) ? messages[:providers].first : mock_saml_config
    allow(Gitlab::Auth::OAuth::Provider).to receive_messages(providers: [:saml], config_for: saml_config)
    stub_omniauth_setting(messages)
    stub_saml_authorize_path_helpers
  end

  def stub_saml_authorize_path_helpers
    allow_any_instance_of(ActionDispatch::Routing::RoutesProxy)
      .to receive(:user_saml_omniauth_authorize_path)
      .and_return('/users/auth/saml')
    allow(Devise::OmniAuth::UrlHelpers)
      .to receive(:omniauth_authorize_path)
      .with(:user, "saml")
      .and_return('/users/auth/saml')
  end

  def stub_omniauth_config(messages)
    allow(Gitlab.config.omniauth).to receive_messages(messages)
  end

  def stub_basic_saml_config
    allow(Gitlab::Auth::Saml::Config).to receive_messages({ options: { name: 'saml', args: {} } })
  end

  def stub_saml_group_config(groups)
    allow(Gitlab::Auth::Saml::Config).to receive_messages({ options: { name: 'saml', groups_attribute: 'groups', external_groups: groups, args: {} } })
  end
end

LoginHelpers.prepend_mod_with('LoginHelpers')
