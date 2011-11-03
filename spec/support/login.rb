module LoginMacros
  def login_as role
    @user = User.create(:email => "user#{User.count}@mail.com",
                        :name => "John Smith",
                        :password => "123456",
                        :password_confirmation => "123456",
                        :skype => 'user_skype')

    if role == :admin
      @user.admin = true
      @user.save!
    end

    visit new_user_session_path
    fill_in "user_email", :with => @user.email
    fill_in "user_password", :with => "123456"
    click_button "Sign in"
  end

  def login_with(user)
    visit new_user_session_path
    fill_in "user_email", :with => user.email
    fill_in "user_password", :with => "123456"
    click_button "Sign in"
  end

  def logout
    click_link "Logout" rescue nil
  end
end
