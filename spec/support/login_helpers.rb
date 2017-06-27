module LoginHelpers
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
    @user =
      if user_or_role.is_a?(User)
        user_or_role
      else
        create(user_or_role)
      end

    gitlab_sign_in_with(@user, **kwargs)
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
    # check the sign_in button
    expect(page).to have_button('Sign in')
  end

  # Logout without JavaScript driver
  def gitlab_sign_out_direct
    page.driver.submit :delete, '/users/sign_out', {}
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

    Thread.current[:current_user] = user
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
end
