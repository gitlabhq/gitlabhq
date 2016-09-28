module LoginHelpers
  # Internal: Log in as a specific user or a new user of a specific role
  #
  # user_or_role - User object, or a role to create (e.g., :admin, :user)
  #
  # Examples:
  #
  #   # Create a user automatically
  #   login_as(:user)
  #
  #   # Create an admin automatically
  #   login_as(:admin)
  #
  #   # Provide an existing User record
  #   user = create(:user)
  #   login_as(user)
  def login_as(user_or_role)
    if user_or_role.kind_of?(User)
      @user = user_or_role
    else
      @user = create(user_or_role)
    end

    login_with(@user)
  end

  # Internal: Login as the specified user
  #
  # user     - User instance to login with
  # remember - Whether or not to check "Remember me" (default: false)
  def login_with(user, remember: false)
    visit new_user_session_path
    fill_in "user_login", with: user.email
    fill_in "user_password", with: "12345678"
    check 'user_remember_me' if remember
    click_button "Sign in"
    Thread.current[:current_user] = user
  end

  def login_via(provider, user, uid)
    mock_auth_hash(provider, uid, user.email)
    visit new_user_session_path
    click_link provider
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

  # Requires Javascript driver.
  def logout
    find(".header-user-dropdown-toggle").click
    click_link "Sign out"
    expect(page).to have_content('Signed out successfully')
  end

  # Logout without JavaScript driver
  def logout_direct
    page.driver.submit :delete, '/users/sign_out', {}
  end

  def skip_ci_admin_auth
    allow_any_instance_of(Ci::Admin::ApplicationController).to receive_messages(authenticate_admin!: true)
  end
end
