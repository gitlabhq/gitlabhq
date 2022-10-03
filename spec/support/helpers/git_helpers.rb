# frozen_string_literal: true

module GitHelpers
  def rugged_repo(repository)
    path = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
      File.join(TestEnv.repos_path, repository.disk_path + '.git')
    end

    Rugged::Repository.new(path)
  end
end
