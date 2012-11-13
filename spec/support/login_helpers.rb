module LoginHelpers
  # Internal: Create and log in as a user of the specified role
  #
  # role - User role (e.g., :admin, :user)
  def login_as(role)
    @user = create(role)
    login_with(@user)
  end

  # Internal: Login as the specified user
  #
  # user - User instance to login with
  def login_with(user)
    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: "123456"
    click_button "Sign in"
  end

  def logout
    click_link "Logout" rescue nil
  end
end
