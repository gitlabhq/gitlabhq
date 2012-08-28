# Stubbing Project <-> git host path
# create project using Factory only
class Project
  def path_to_repo
    File.join(Rails.root, "tmp", "tests", path)
  end

  def satellite
    @satellite ||= FakeSatellite.new
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
