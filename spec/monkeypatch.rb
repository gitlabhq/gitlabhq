# Stubbing Project <-> git host path
# create project using Factory only
class Project
  def update_repository
    true
  end

  def update_repository
    true
  end

  def path_to_repo
    File.join(Rails.root, "tmp", "tests", path)
  end

  def satellite
    @satellite ||= FakeSatellite.new
  end
end

class Key
  def update_repository
    true
  end

  def repository_delete_key
    true
  end
end

class UsersProject
  def update_repository
    true
  end
end

class FakeSatellite
  def exists? 
    true
  end

  def create
    true
  end
end


