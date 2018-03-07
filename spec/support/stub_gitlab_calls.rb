module StubGitlabCalls
  def stub_gitlab_calls
    stub_session
    stub_user
    stub_project_8
    stub_project_8_hooks
    stub_projects
    stub_projects_owned
    stub_ci_enable
  end

  def stub_js_gitlab_calls
    allow_any_instance_of(Network).to receive(:projects) { project_hash_array }
  end

  def stub_ci_pipeline_to_return_yaml_file
    stub_ci_pipeline_yaml_file(gitlab_ci_yaml)
  end

  def stub_ci_pipeline_yaml_file(ci_yaml)
    allow_any_instance_of(Ci::Pipeline).to receive(:ci_yaml_file) { ci_yaml }
  end

  def stub_repository_ci_yaml_file(sha:, path: '.gitlab-ci.yml')
    allow_any_instance_of(Repository)
      .to receive(:gitlab_ci_yml_for).with(sha, path)
      .and_return(gitlab_ci_yaml)
  end

  def stub_ci_builds_disabled
    allow_any_instance_of(Project).to receive(:builds_enabled?).and_return(false)
  end

  def stub_container_registry_config(registry_settings)
    allow(Gitlab.config.registry).to receive_messages(registry_settings)
    allow(Auth::ContainerRegistryAuthenticationService)
      .to receive(:full_access_token).and_return('token')
  end

  def stub_container_registry_tags(repository: :any, tags:)
    repository = any_args if repository == :any

    allow_any_instance_of(ContainerRegistry::Client)
      .to receive(:repository_tags).with(repository)
      .and_return({ 'tags' => tags })

    allow_any_instance_of(ContainerRegistry::Client)
      .to receive(:repository_manifest).with(repository, anything)
      .and_return(stub_container_registry_tag_manifest)

    allow_any_instance_of(ContainerRegistry::Client)
      .to receive(:blob).with(repository, anything, 'application/octet-stream')
      .and_return(stub_container_registry_blob)
  end

  private

  def stub_container_registry_tag_manifest
    fixture_path = 'spec/fixtures/container_registry/tag_manifest.json'

    JSON.parse(File.read(Rails.root + fixture_path))
  end

  def stub_container_registry_blob
    fixture_path = 'spec/fixtures/container_registry/config_blob.json'

    File.read(Rails.root + fixture_path)
  end

  def gitlab_url
    Gitlab.config.gitlab.url
  end

  def stub_session
    f = File.read(Rails.root.join('spec/support/gitlab_stubs/session.json'))

    stub_request(:post, "#{gitlab_url}api/v3/session.json")
      .with(body: "{\"email\":\"test@test.com\",\"password\":\"123456\"}",
            headers: { 'Content-Type' => 'application/json' })
      .to_return(status: 201, body: f, headers: { 'Content-Type' => 'application/json' })
  end

  def stub_user
    f = File.read(Rails.root.join('spec/support/gitlab_stubs/user.json'))

    stub_request(:get, "#{gitlab_url}api/v3/user?private_token=Wvjy2Krpb7y8xi93owUz")
      .with(headers: { 'Content-Type' => 'application/json' })
      .to_return(status: 200, body: f, headers: { 'Content-Type' => 'application/json' })

    stub_request(:get, "#{gitlab_url}api/v3/user?access_token=some_token")
      .with(headers: { 'Content-Type' => 'application/json' })
      .to_return(status: 200, body: f, headers: { 'Content-Type' => 'application/json' })
  end

  def stub_project_8
    data = File.read(Rails.root.join('spec/support/gitlab_stubs/project_8.json'))
    allow_any_instance_of(Network).to receive(:project).and_return(JSON.parse(data))
  end

  def stub_project_8_hooks
    data = File.read(Rails.root.join('spec/support/gitlab_stubs/project_8_hooks.json'))
    allow_any_instance_of(Network).to receive(:project_hooks).and_return(JSON.parse(data))
  end

  def stub_projects
    f = File.read(Rails.root.join('spec/support/gitlab_stubs/projects.json'))

    stub_request(:get, "#{gitlab_url}api/v3/projects.json?archived=false&ci_enabled_first=true&private_token=Wvjy2Krpb7y8xi93owUz")
      .with(headers: { 'Content-Type' => 'application/json' })
      .to_return(status: 200, body: f, headers: { 'Content-Type' => 'application/json' })
  end

  def stub_projects_owned
    stub_request(:get, "#{gitlab_url}api/v3/projects/owned.json?archived=false&ci_enabled_first=true&private_token=Wvjy2Krpb7y8xi93owUz")
      .with(headers: { 'Content-Type' => 'application/json' })
      .to_return(status: 200, body: "", headers: {})
  end

  def stub_ci_enable
    stub_request(:put, "#{gitlab_url}api/v3/projects/2/services/gitlab-ci.json?private_token=Wvjy2Krpb7y8xi93owUz")
      .with(headers: { 'Content-Type' => 'application/json' })
      .to_return(status: 200, body: "", headers: {})
  end

  def project_hash_array
    f = File.read(Rails.root.join('spec/support/gitlab_stubs/projects.json'))
    JSON.parse f
  end
end
