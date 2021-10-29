# frozen_string_literal: true

# AccessMatchers
#
# The custom matchers contained in this module are used to test a user's access
# to a URL by emulating a specific user or type of user account, visiting the
# URL, and then checking the response status code and resulting path.
module AccessMatchers
  extend RSpec::Matchers::DSL
  include Warden::Test::Helpers

  def emulate_user(user_type_or_trait, membership = nil)
    case user_type_or_trait
    when :user, :admin
      login_as(create(user_type_or_trait))
    when :external, :auditor
      login_as(create(:user, user_type_or_trait))
    when :visitor
      logout
    when User
      login_as(user_type_or_trait)
    when *Gitlab::Access.sym_options_with_owner.keys
      raise ArgumentError, "cannot emulate #{user_type_or_trait} without membership parent" unless membership

      role = user_type_or_trait
      user =
        if role == :owner && membership.owner
          membership.owner
        else
          create(:user).tap do |new_user|
            membership.public_send(:"add_#{role}", new_user)
          end
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

      [200, 204].include?(status_code) && !current_path.in?([new_user_session_path, new_admin_session_path])
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

      [401, 404, 403].include?(status_code) || current_path.in?([new_user_session_path, new_admin_session_path])
    end

    chain :of do |membership|
      @membership = membership
    end

    description { description_for(user, 'denied') }
  end
end
