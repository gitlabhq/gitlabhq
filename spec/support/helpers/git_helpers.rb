# frozen_string_literal: true

module GitHelpers
  def rugged_repo(repository)
    rugged_repo_at_path(repository.disk_path + '.git')
  end

  def rugged_repo_at_path(relative_path)
    path = File.join(TestEnv.repos_path, relative_path)
    Rugged::Repository.new(path)
  end
end
