# frozen_string_literal: true

module StubMemberAccessLevel
  # Stubs access level of a member of +object+.
  #
  # The following types are supported:
  # * `Project` - stubs `project.team.max_member_access(user.id)`
  # * `Group` - stubs `group.max_member_access_for_user(user)`
  #
  # @example
  #
  #   stub_member_access_level(project, maintainer: user)
  #   project.team.max_member_access(user.id) # => Gitlab::Access::MAINTAINER
  #
  #   stub_member_access_level(group, developer: user)
  #   group.max_member_access_for_user(user) # => Gitlab::Access::DEVELOPER
  #
  #   stub_member_access_level(project, reporter: user, guest: [guest1, guest2])
  #   project.team.max_member_access(user.id) # => Gitlab::Access::REPORTER
  #   project.team.max_member_access(guests.first.id) # => Gitlab::Access::GUEST
  #   project.team.max_member_access(guests.last.id) # => Gitlab::Access::GUEST
  #
  # @param object [Project, Group] Object to be stubbed.
  # @param access_levels [Hash<Symbol, User>, Hash<Symbol, [User]>] Map of access level to users
  def stub_member_access_level(object, **access_levels)
    expectation = case object
                  when Project
                    ->(user) { expect(object.team).to receive(:max_member_access).with(user.id) }
                  when Group
                    ->(user) { expect(object).to receive(:max_member_access_for_user).with(user) }
                  else
                    raise ArgumentError,
                      "Stubbing member access level unsupported for #{object.inspect} (#{object.class})"
                  end

    access_levels.each do |access_level, users|
      access_level = Gitlab::Access.sym_options_with_owner.fetch(access_level) do
        raise ArgumentError, "Invalid access level #{access_level.inspect}"
      end

      Array(users).each do |user|
        expectation.call(user).at_least(1).times.and_return(access_level)
      end
    end
  end
end
