# frozen_string_literal: true

module StubMemberAccessLevel
  # Stubs access level of a member of +object+.
  #
  # The following types are supported:
  # * `Project` - stubs `project.max_member_access_for_user(user)`
  # * `Group` - stubs `group.max_member_access_for_user(user)`
  #
  # @example
  #
  #   stub_member_access_level(project, maintainer: user)
  #   project.max_member_access_for_user(user) # => Gitlab::Access::MAINTAINER
  #
  #   stub_member_access_level(group, developer: user)
  #   group.max_member_access_for_user(user) # => Gitlab::Access::DEVELOPER
  #
  #   stub_member_access_level(project, reporter: user, guest: [guest1, guest2])
  #   project.max_member_access_for_user(user) # => Gitlab::Access::REPORTER
  #   project.max_member_access_for_user(guests.first) # => Gitlab::Access::GUEST
  #   project.max_member_access_for_user(guests.last) # => Gitlab::Access::GUEST
  #
  # @param object [Project, Group] Object to be stubbed.
  # @param access_levels [Hash<Symbol, User>, Hash<Symbol, [User]>] Map of access level to users
  def stub_member_access_level(object, **access_levels)
    access_levels.each do |access_level, users|
      access_level = Gitlab::Access.sym_options_with_owner.fetch(access_level) do
        raise ArgumentError, "Invalid access level #{access_level.inspect}"
      end

      Array(users).each do |user|
        expect(object).to receive(:max_member_access_for_user).with(user).at_least(:once).and_return(access_level)
      end
    end
  end
end
