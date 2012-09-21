module GitoliteStub
  def stub_gitolite!
    stub_gitlab_gitolite
    stub_gitolite_admin
  end

  def stub_gitolite_admin
    gitolite_admin = double('Gitolite::GitoliteAdmin')
    gitolite_admin.as_null_object

    Gitolite::GitoliteAdmin.stub(new: gitolite_admin)
  end

  def stub_gitlab_gitolite
    gitolite_config = double('Gitlab::GitoliteConfig')
    gitolite_config.stub(apply: ->() { yield(self) })
    gitolite_config.as_null_object

    Gitlab::GitoliteConfig.stub(new: gitolite_config)
  end
end
