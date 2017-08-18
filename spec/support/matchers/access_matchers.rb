# AccessMatchers
#
# The custom matchers contained in this module are used to test a user's access
# to a URL by emulating a specific user or type of user account, visiting the
# URL, and then checking the response status code and resulting path.
module AccessMatchers
  extend RSpec::Matchers::DSL
  include Warden::Test::Helpers

  def emulate_user(user, membership = nil)
    case user
    when :user
      login_as(create(:user))
    when :visitor
      logout
    when :admin
      login_as(create(:admin))
    when :external
      login_as(create(:user, external: true))
    when User
      login_as(user)
    when *Gitlab::Access.sym_options_with_owner.keys
      raise ArgumentError, "cannot emulate #{user} without membership parent" unless membership

      role = user

      if role == :owner && membership.owner
        user = membership.owner
      else
        user = create(:user)
        membership.public_send(:"add_#{role}", user)
      end

      login_as(user)
    else
      raise ArgumentError, "cannot emulate user #{user}"
    end
  end

  def description_for(user, type)
    if user.is_a?(User)
      # User#inspect displays too much information for RSpec's descriptions
      "be #{type} for the specified user"
    else
      "be #{type} for #{user}"
    end
  end

  matcher :be_allowed_for do |user|
    match do |url|
      emulate_user(user, @membership)
      visit(url)

      status_code == 200 && current_path != new_user_session_path
    end

    chain :of do |membership|
      @membership = membership
    end

    description { description_for(user, 'allowed') }
  end

  matcher :be_denied_for do |user|
    match do |url|
      emulate_user(user, @membership)
      visit(url)

      [401, 404].include?(status_code) || current_path == new_user_session_path
    end

    chain :of do |membership|
      @membership = membership
    end

    description { description_for(user, 'denied') }
  end
end
