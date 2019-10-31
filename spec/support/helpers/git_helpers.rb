# frozen_string_literal: true

module GitHelpers
  def rugged_repo(repository)
    path = File.join(TestEnv.repos_path, repository.disk_path + '.git')

    Rugged::Repository.new(path)
  end
end
