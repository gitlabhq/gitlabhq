require "repository"
require "project"
require "merge_request"
require "shell"

# Stubs out all Git repository access done by models so that specs can run
# against fake repositories without Grit complaining that they don't exist.
class Project
  def repository
    if path == "empty" || !path
      nil
    else
      GitLabTestRepo.new(path_with_namespace)
    end
  end

  def satellite
    FakeSatellite.new
  end

  class FakeSatellite
    def exists?
      true
    end

    def destroy
      true
    end

    def create
      true
    end
  end
end

class MergeRequest
  def check_if_can_be_merged
    true
  end
end

class GitLabTestRepo < Repository
  def repo
    @repo ||= Grit::Repo.new(Rails.root.join('tmp', 'repositories', 'gitlabhq'))
  end

  # patch repo size (in mb)
  def size
    12.45
  end
end

module Gitlab
  class Shell
    def add_repository name
      true
    end

    def mv_repository name, new_name
      true
    end

    def remove_repository name
      true
    end

    def add_key id, key
      true
    end

    def remove_key id, key
      true
    end
  end
end
