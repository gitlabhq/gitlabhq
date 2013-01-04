# Stubs out all Git repository access done by models so that specs can run
# against fake repositories without Grit complaining that they don't exist.
class Project
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

class Repository
  def repo
    @repo ||= Grit::Repo.new(Rails.root.join('tmp', 'repositories', 'gitlabhq'))
  end
end
