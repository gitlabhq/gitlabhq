# Stubs out all Git repository access done by models so that specs can run
# against fake repositories without Grit complaining that they don't exist.
module StubbedRepository
  extend ActiveSupport::Concern

  included do
    # If a class defines the method we want to stub directly, rather than
    # inheriting it from a module (as is the case in UsersProject), that method
    # will overwrite our stub, so use alias_method to ensure it's our stub
    # getting called.

    alias_method :update_repository,     :fake_update_repository
    alias_method :destroy_repository,    :fake_destroy_repository
    alias_method :repository_delete_key, :fake_repository_delete_key
    alias_method :path_to_repo,          :fake_path_to_repo
    alias_method :satellite,             :fake_satellite
  end

  def fake_update_repository
    true
  end

  def fake_destroy_repository
    true
  end

  def fake_repository_delete_key
    true
  end

  def fake_path_to_repo
    if new_record?
      # There are a couple Project specs that expect the Project's path to be
      # in the returned path, so let's patronize them.
      File.join(Rails.root, 'tmp', 'tests', path)
    else
      # For everything else, just give it the path to one of our real seeded
      # repos.
      File.join(Rails.root, 'tmp', 'tests', 'gitlabhq_1')
    end
  end

  def fake_satellite
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

[Project, Key, ProtectedBranch, UsersProject].each do |c|
  c.send(:include, StubbedRepository)
end
