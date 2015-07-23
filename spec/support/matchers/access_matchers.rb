# AccessMatchers
#
# The custom matchers contained in this module are used to test a user's access
# to a URL by emulating a specific user or type of user account, visiting the
# URL, and then checking the response status code and resulting path.
module AccessMatchers
  extend RSpec::Matchers::DSL
  include Warden::Test::Helpers

  def emulate_user(user)
    case user
    when :user
      login_as(create(:user))
    when :visitor
      logout
    when :admin
      login_as(create(:admin))
    when User
      login_as(user)
    else
      raise ArgumentError, "cannot emulate user #{user}"
    end
  end

  def description_for(user, type)
    if user.kind_of?(User)
      # User#inspect displays too much information for RSpec's description
      # messages
      "be #{type} for supplied User"
    else
      "be #{type} for #{user}"
    end
  end

  matcher :be_allowed_for do |user|
    match do |url|
      emulate_user(user)
      visit url
      status_code != 404 && current_path != new_user_session_path
    end

    description { description_for(user, 'allowed') }
  end

  matcher :be_denied_for do |user|
    match do |url|
      emulate_user(user)
      visit url
      status_code == 404 || current_path == new_user_session_path
    end

    description { description_for(user, 'denied') }
  end
end
