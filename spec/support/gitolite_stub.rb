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
    gitolite_config = double('Gitlab::GitoliteConfig')
    gitolite_config.stub(
      apply: ->() { yield(self) },
      write_key: true,
      rm_key: true,
      update_projects: true,
      update_project: true,
      update_project!: true,
      destroy_project: true,
      destroy_project!: true,
      admin_all_repo: true,
      admin_all_repo!: true,

    )

    Gitlab::GitoliteConfig.stub(new: gitolite_config)
  end
end
