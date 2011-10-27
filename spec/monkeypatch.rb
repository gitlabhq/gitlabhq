# Stubbing Project <-> gitosis path
# create project using Factory only
class Project
  def update_gitosis_project
    true
  end

  def update_gitosis
    true
  end

  def path_to_repo
    File.join(Rails.root, "tmp", "tests", path)
  end
end

class Key
  def update_gitosis
    true
  end

  def gitosis_delete_key
    true
  end
end

class UsersProject
  def update_gitosis_project
    true
  end
end
