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
  # user - User instance to login with
  def login_with(user)
    visit new_user_session_path
    fill_in "user_login", with: user.email
    fill_in "user_password", with: "12345678"
    click_button "Sign in"
    Thread.current[:current_user] = user
  end

  # Requires Javascript driver.
  def logout
    find(:css, ".fa.fa-sign-out").click
  end

  # Logout without JavaScript driver
  def logout_direct
    page.driver.submit :delete, '/users/sign_out', {}
  end

  def skip_ci_admin_auth
    allow_any_instance_of(Ci::Admin::ApplicationController).to receive_messages(authenticate_admin!: true)
  end
end
