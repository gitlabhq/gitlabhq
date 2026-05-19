# frozen_string_literal: true

require_relative 'devise_helpers'

module LoginHelpers
  include AdminModeHelper
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

    submit_sign_in_form_for(user, **kwargs)
    expect(page).not_to have_current_path(new_user_session_path)

    @current_user = user
  end

  def gitlab_sign_in_via(provider, user, uid, saml_response = nil)
    mock_auth_hash_with_saml_xml(provider, uid, user.email, saml_response)
    click_oauth_provider(provider)
  end

  def gitlab_enable_admin_mode_sign_in_via(provider, user, uid, saml_response: nil, expect_fail: false, additional_info: {})
    response_object = saml_xml(saml_response) if saml_response.present?
    mock_auth_hash(provider, uid, user.email, response_object: response_object, additional_info: additional_info)
    click_oauth_provider(provider, sign_in_path: new_admin_session_path, expect_fail: expect_fail)
  end

  # Requires Javascript driver.
  def gitlab_sign_out(user = @current_user)
    within_testid('user-dropdown') do
      click_on "#{user.name} user’s menu"
      click_link _('Sign out')
    end
    @current_user = nil
    expect(page).to have_button(_('Sign in'))
  end

  # Submit the login form as the specified user
  # When using this helper, make sure to assert on the expected page state after signing in,
  # e.g., that the user is redirected to the dashboard or an error is shown.
  # If the expectation is to success upon sign-in use `gitlab_sign_in` instead.
  #
  # user - User instance to login with
  # remember - Whether or not to check "Remember me" (default: false)
  # two_factor_auth - If two-factor authentication is enabled (default: false)
  # password - password to attempt to login with (default: user.password)
  def submit_sign_in_form_for(user, remember: false, two_factor_auth: false, password: nil, visit: true)
    visit new_user_session_path if visit

    fill_in "user_login", with: user.email

    # When JavaScript is enabled, wait for the password field, with class `.js-password`,
    # to be replaced by the Vue password component,
    # `app/assets/javascripts/authentication/password/components/password_input.vue`.
    expect(page).not_to have_selector('.js-password') if javascript_test?

    fill_in "user_password", with: password || user.password

    check 'user_remember_me' if remember

    find('[data-testid="sign-in-button"]:enabled').click

    return unless two_factor_auth

    fill_in "user_otp_attempt", with: user.reload.current_otp
    click_button "Verify code"
  end

  private

  def login_via(provider, user, uid, remember_me: false, additional_info: {})
    mock_auth_hash(provider, uid, user.email, additional_info: additional_info)
    click_oauth_provider(provider, remember_me: remember_me)
  end

  # The remember_me functionality requires Javascript driver.
  def click_oauth_provider(provider, remember_me: false, sign_in_path: new_user_session_path, expect_fail: false)
    wait = expect_fail ? 3 : 10
    attempts = 3
    attempts.times do
      visit sign_in_path
      expect(page).to have_button(Gitlab::Auth::OAuth::Provider.label_for(provider))

      check_remember_me_omniauth(provider) if remember_me

      navigated = click_oauth_provider_button(provider, sign_in_path, wait)
      break if expect_fail ? !navigated : navigated
    rescue CsrfRetry
      # retry
    end

    expect_oauth_provider_navigation(sign_in_path, expect_fail)
  end

  def check_remember_me_omniauth(provider)
    within('body.page-initialised') do
      check 'js-remember-me-omniauth'
    end
    find("form[action='/users/auth/#{provider}?remember_me=1']")
  end

  # Clicks the OAuth provider button and returns whether navigation occurred.
  # Raises CsrfRetry if the session cookie is missing (Chrome intermittent bug), signalling the caller to retry.
  def click_oauth_provider_button(provider, sign_in_path, wait)
    if javascript_test?
      click_oauth_provider_button_js(provider, sign_in_path, wait)
    else
      click_button Gitlab::Auth::OAuth::Provider.label_for(provider)

      # Wait for navigation, then retry if needed.
      page.has_no_current_path?(sign_in_path, ignore_query: true, wait: wait)
    end
  end

  CsrfRetry = Class.new(StandardError)

  def click_oauth_provider_button_js(provider, sign_in_path, wait)
    navigated = false
    reqs = inspect_requests do
      click_button Gitlab::Auth::OAuth::Provider.label_for(provider)

      # Wait for navigation, then retry if needed.
      navigated = page.has_no_current_path?(sign_in_path, ignore_query: true, wait: wait)
    end

    # Chrome intermittently fails to send cookies on the POST request, causing a silent
    # CSRF failure that redirects back to sign-in.
    post_request = reqs.find { |r| r.url&.include?("/users/auth/#{provider}") }
    raise CsrfRetry unless post_request&.request_headers&.fetch('Cookie', '')&.include?('_gitlab_session')

    navigated
  end

  def expect_oauth_provider_navigation(sign_in_path, expect_fail)
    if expect_fail
      expect(page).to have_current_path(sign_in_path, ignore_query: true)
    else
      expect(page).to have_no_current_path(sign_in_path, ignore_query: true)
    end
  end

  def sign_in_using_ldap!(user, ldap_tab, ldap_name)
    visit new_user_session_path
    click_link ldap_tab
    fill_in 'username', with: user.username
    fill_in 'password', with: user.password
    within("##{ldap_name}") do
      click_button 'Sign in'
    end
  end

  def register_via(provider, uid, email, additional_info: {})
    mock_auth_hash(provider, uid, email, additional_info: additional_info)
    click_oauth_provider(provider, sign_in_path: new_user_registration_path)
  end

  def fake_successful_webauthn_authentication
    allow_next_instance_of(Webauthn::AuthenticateService) do |instance|
      allow(instance).to receive(:execute).and_return(
        ServiceResponse.success
      )
    end

    FakeWebauthnDevice.new(page, nil).fake_webauthn_authentication
  end

  def mock_auth_hash_with_saml_xml(provider, uid, email, saml_response)
    response_object = saml_xml(saml_response)
    mock_auth_hash(provider, uid, email, response_object: response_object)
  end

  def configure_mock_auth(provider, uid, email, response_object: nil, additional_info: {}, name: 'mockuser', groups: [])
    # The mock_auth configuration allows you to set per-provider (or default)
    # authentication hashes to return during integration testing.

    OmniAuth.config.mock_auth[provider.to_sym] = OmniAuth::AuthHash.new({
      provider: provider,
      uid: uid,
      info: {
        name: name,
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
            },
            'groups' => groups
          }
        ),
        response_object: response_object
      }
    }).merge(additional_info)
  end

  def mock_auth_hash(provider, uid, email, additional_info: {}, response_object: nil, name: 'mockuser', groups: [])
    configure_mock_auth(
      provider, uid, email, additional_info: additional_info, response_object: response_object, name: name, groups: groups
    )

    original_env_config_omniauth_auth = Rails.application.env_config['omniauth.auth']
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[provider.to_sym]

    original_env_config_omniauth_auth
  end

  def saml_xml(raw_saml_response)
    return '' if raw_saml_response.blank?

    OneLogin::RubySaml::Response.new(raw_saml_response)
  end

  def mock_saml_config
    ActiveSupport::InheritableOptions.new(name: 'saml', label: 'SAML', args: {
      assertion_consumer_service_url: 'https://localhost:3443/users/auth/saml/callback',
      idp_cert_fingerprint: '26:43:2C:47:AF:F0:6B:D0:07:9C:AD:A3:74:FE:5D:94:5F:4E:9E:52',
      idp_sso_target_url: 'https://idp.example.com/sso/saml',
      issuer: 'https://localhost:3443/',
      name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient'
    })
  end

  def mock_saml_config_with_upstream_two_factor_authn_contexts
    config = mock_saml_config
    config.args[:upstream_two_factor_authn_contexts] = %w[urn:oasis:names:tc:SAML:2.0:ac:classes:CertificateProtectedTransport
      urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorOTPSMS
      urn:oasis:names:tc:SAML:2.0:ac:classes:SecondFactorIGTOKEN]
    config
  end

  # Adds a provider route for use in controller specs.
  #
  # This is the only safe way to add OmniAuth provider routes in tests.
  # It tags the current example so that an after(:each) hook
  # (registered in spec/support/omniauth.rb) automatically:
  #   1. Resets disable_clear_and_finalize
  #   2. Reloads routes
  #   3. Re-aliases missing provider actions on OmniauthCallbacksController
  #
  # Do NOT manipulate routes.disable_clear_and_finalize or draw provider
  # routes directly - the cleanup won't run and state will leak.
  def prepare_provider_route(provider_name)
    routes = Rails.application.routes
    routes.disable_clear_and_finalize = true
    routes.formatter.clear
    routes.draw do
      post "/users/auth/#{provider_name}" => "omniauth_callbacks##{provider_name}"
    end

    # Ensure the controller has an action for this provider (it may not if the
    # provider was not configured at class-load time, e.g. iam_* providers).
    unless OmniauthCallbacksController.method_defined?(provider_name.to_sym)
      OmniauthCallbacksController.alias_method provider_name.to_sym, :handle_omniauth
    end

    # Tag the example so the after hook in spec/support/omniauth.rb
    # calls cleanup_provider_routes after the test.
    RSpec.current_example.metadata[:provider_routes_modified] = true
  end

  # Reverses the global side effects of prepare_provider_route.
  # Called from the after hook in spec/support/omniauth.rb.
  #
  # Must restore:
  # 1. The route set flag so subsequent draws clear/finalize properly.
  # 2. The full route table via reload_routes!.
  # 3. Any provider actions on OmniauthCallbacksController that were lost
  #    when the controller was autoloaded while Provider.providers was
  #    stubbed to a subset (e.g. only [:saml]).
  def self.cleanup_provider_routes
    Rails.application.routes.disable_clear_and_finalize = false
    Rails.application.reload_routes!

    # Mirror the filtering from AuthHelper.providers_for_base_controller
    # (which we can't call here because Provider.providers may still be stubbed):
    # exclude LDAP providers (handled by Ldap::OmniauthCallbacksController)
    # and :group_saml (EE group-level provider, handled by Groups::OmniauthCallbacksController).
    providers = Devise.omniauth_providers.reject { |p| p.to_s.start_with?('ldap') || p == :group_saml }
    providers.each do |provider|
      next if OmniauthCallbacksController.method_defined?(provider)

      OmniauthCallbacksController.alias_method provider, :handle_omniauth
    end
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
    saml_config = messages.key?(:providers) ? messages[:providers].first : mock_saml_config
    prepare_provider_route(saml_config.name)
    allow(Gitlab::Auth::OAuth::Provider).to receive_messages(providers: [saml_config.name], config_for: saml_config)
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
    allow(Gitlab.config.omniauth).to receive_messages(GitlabSettings::Options.build(messages))
  end

  def stub_basic_saml_config
    stub_omniauth_config(providers: [{ name: 'saml', args: {} }])
  end

  def stub_saml_group_config(groups)
    stub_omniauth_config(providers: [{ name: 'saml', groups_attribute: 'groups', external_groups: groups, args: {} }])
  end
end

LoginHelpers.prepend_mod_with('LoginHelpers')
