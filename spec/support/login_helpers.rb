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
        create(user_or_role)
      end

    gitlab_sign_in_with(user, **kwargs)

    @current_user = user
  end

  def gitlab_sign_in_via(provider, user, uid)
    mock_auth_hash(provider, uid, user.email)
    visit new_user_session_path
    click_link provider
  end

  # Requires Javascript driver.
  def gitlab_sign_out
    find(".header-user-dropdown-toggle").click
    click_link "Sign out"
    @current_user = nil

    expect(page).to have_button('Sign in')
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

  def login_via(provider, user, uid, remember_me: false)
    mock_auth_hash(provider, uid, user.email)
    visit new_user_session_path
    expect(page).to have_content('Sign in with')

    check 'remember_me' if remember_me

    click_link "oauth-login-#{provider}"
  end

  def mock_auth_hash(provider, uid, email)
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
        raw_info: {
          info: {
            name: 'mockuser',
            email: email,
            image: 'mock_user_thumbnail_url'
          }
        }
      }
    })
    Rails.application.env_config['omniauth.auth'] = OmniAuth.config.mock_auth[:saml]
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

  def stub_omniauth_provider(provider, context: Rails.application)
    env = env_from_context(context)

    set_devise_mapping(context: context)
    env['omniauth.auth'] = OmniAuth.config.mock_auth[provider]
  end

  def stub_omniauth_saml_config(messages)
    set_devise_mapping(context: Rails.application)
    Rails.application.routes.disable_clear_and_finalize = true
    Rails.application.routes.draw do
      post '/users/auth/saml' => 'omniauth_callbacks#saml'
    end
    allow(Gitlab::Auth::OAuth::Provider).to receive_messages(providers: [:saml], config_for: mock_saml_config)
    stub_omniauth_setting(messages)
    allow_any_instance_of(Object).to receive(:user_saml_omniauth_authorize_path).and_return('/users/auth/saml')
    allow_any_instance_of(Object).to receive(:omniauth_authorize_path).with(:user, "saml").and_return('/users/auth/saml')
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
