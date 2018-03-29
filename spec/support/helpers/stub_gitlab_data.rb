module StubGitlabData
  def gitlab_ci_yaml
    File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
  end
end
