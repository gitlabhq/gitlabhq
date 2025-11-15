# frozen_string_literal: true

module RolesHelpers
  module_function

  def assignable_roles
    {
      owner: [:owner, :maintainer, :planner, :developer, :reporter, :guest],
      maintainer: [:maintainer, :developer, :reporter, :guest],
      developer: [:developer, :reporter, :guest],
      reporter: [:reporter, :guest],
      planner: [:planner, :guest],
      guest: [:guest]
    }
  end

  def access_level_value(name)
    Gitlab::Access.sym_options_with_owner[name]
  end
end
