module GitoliteStub
  def stub_gitolite!
    stub_gitlab_gitolite
    stub_gitolite_admin
  end

  def stub_gitolite_admin
    gitolite_repo = mock(
      clean_permissions: true,
      add_permission: true
    )

    gitolite_config = mock(
      add_repo: true,
      get_repo: gitolite_repo,
      has_repo?: true
    )

    gitolite_admin = double(
      'Gitolite::GitoliteAdmin', 
      config: gitolite_config,
      save: true,
    )

    Gitolite::GitoliteAdmin.stub(new: gitolite_admin)

  end

  def stub_gitlab_gitolite
    gitlab_gitolite = Gitlab::Gitolite.new
    Gitlab::Gitolite.stub(new: gitlab_gitolite)
    gitlab_gitolite.stub(configure: ->() { yield(self) })
    gitlab_gitolite.stub(update_keys: true)
  end
end
