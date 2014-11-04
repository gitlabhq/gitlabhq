module ProjectHelpers
  extend self

  def give_push_permission(user, project)
    sign_in(user)
    project.team << [user, :developer]
  end

  def give_fork_permission(user, project)
    sign_in(user)
    project.team << [user, :reporter]
  end
end
