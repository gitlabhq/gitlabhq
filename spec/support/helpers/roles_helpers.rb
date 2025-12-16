# frozen_string_literal: true

module RolesHelpers
  module_function

  def assignable_roles
    {
      owner: [:owner, :maintainer, :planner, :developer, :security_manager, :reporter, :guest],
      maintainer: [:maintainer, :developer, :reporter, :guest],
      developer: [:developer, :reporter, :guest],
      security_manager: [:security_manager, :reporter, :guest],
      reporter: [:reporter, :guest],
      planner: [:planner, :guest],
      guest: [:guest]
    }
  end

  def access_level_value(name)
    Gitlab::Access.sym_options_with_owner[name]
  end

  def testable_roles(include_owner: false)
    roles = include_owner ? Gitlab::Access.sym_options_with_owner.keys : Gitlab::Access.sym_options.keys
    ## TODO: remove this hack in the MR that added the add_security_manager method (https://gitlab.com/gitlab-org/gitlab/-/merge_requests/215015)
    roles.map(&:to_sym).reject { |role| role == :security_manager }
  end
end
