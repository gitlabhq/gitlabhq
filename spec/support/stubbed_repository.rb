# Stubs out all Git repository access done by models so that specs can run
# against fake repositories without Grit complaining that they don't exist.
module StubbedRepository
  def path_to_repo
    if new_record? || path == 'newproject'
      # There are a couple Project specs and features that expect the Project's
      # path to be in the returned path, so let's patronize them.
      Rails.root.join('tmp', 'repositories', path)
    else
      # For everything else, just give it the path to one of our real seeded
      # repos.
      Rails.root.join('tmp', 'repositories', 'gitlabhq')
    end
  end

  def satellite
    FakeSatellite.new
  end

  class FakeSatellite
    def exists?
      true
    end

    def create
      true
    end
  end
end

Project.send(:include, StubbedRepository)
