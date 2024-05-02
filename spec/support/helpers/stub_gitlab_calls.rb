# frozen_string_literal: true

module StubGitlabCalls
  def stub_gitlab_calls
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

  def gitlab_ci_yaml
    File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
  end

  def stub_ci_pipeline_yaml_file(ci_yaml_content)
    blob = instance_double(Blob, empty?: ci_yaml_content.blank?, data: ci_yaml_content)
    allow(blob).to receive(:load_all_data!)

    allow_any_instance_of(Repository)
      .to receive(:blob_at)
      .and_call_original

    allow_any_instance_of(Repository)
      .to receive(:blob_at)
      .with(String, '.gitlab-ci.yml')
      .and_return(blob)

    # Ensure we don't hit auto-devops when config not found in repository
    unless ci_yaml_content
      allow_any_instance_of(Project).to receive(:auto_devops_enabled?).and_return(false)
    end

    # Stub the first call to `include:[local: .gitlab-ci.yml]` when
    # evaluating the CI root config content.
    allow_any_instance_of(Gitlab::Ci::Config::External::File::Local)
      .to receive(:content)
      .and_return(ci_yaml_content)
  end

  def stub_pipeline_modified_paths(pipeline, modified_paths)
    allow(pipeline).to receive(:modified_paths).and_return(modified_paths)
  end

  def stub_ci_builds_disabled
    allow_any_instance_of(Project).to receive(:builds_enabled?).and_return(false)
  end

  def stub_container_registry_config(registry_settings)
    allow(Gitlab.config.registry).to receive_messages(registry_settings)
    allow(Auth::ContainerRegistryAuthenticationService)
      .to receive(:full_access_token).and_return('token')
  end

  def stub_container_registry_tags(repository: :any, tags: [], with_manifest: false)
    repository = any_args if repository == :any

    allow_any_instance_of(ContainerRegistry::Client)
      .to receive(:repository_tags).with(repository)
      .and_return({ 'tags' => tags })

    if with_manifest
      tags.each do |tag|
        allow_any_instance_of(ContainerRegistry::Client)
          .to receive(:repository_tag_digest)
          .with(repository, tag)
          .and_return('sha256:4c8e63ca4cb663ce6c688cb06f1c3' \
                      '72b088dac5b6d7ad7d49cd620d85cf72a15')
      end

      allow_any_instance_of(ContainerRegistry::Client)
        .to receive(:repository_manifest).with(repository, anything)
        .and_return(stub_container_registry_tag_manifest_content)

      allow_any_instance_of(ContainerRegistry::Client)
        .to receive(:blob).with(repository, anything, 'application/octet-stream')
        .and_return(stub_container_registry_blob_content)
    end
  end

  def stub_container_registry_info(info: {})
    allow(ContainerRegistry::Client)
      .to receive(:registry_info)
      .and_return(info)
  end

  def stub_container_registry_network_error(client_method:)
    allow_next_instance_of(ContainerRegistry::Client) do |client|
      allow(client).to receive(client_method).and_raise(::Faraday::Error, nil, nil)
    end
  end

  def stub_commonmark_sourcepos_disabled
    engine = Banzai::Filter::MarkdownFilter.new('foo', {}).render_engine

    allow_next_instance_of(engine) do |instance|
      allow(instance).to receive(:sourcepos_disabled?).and_return(true)
    end
  end

  def stub_commonmark_sourcepos_enabled
    engine = Banzai::Filter::MarkdownFilter.new('foo', {}).render_engine

    allow_next_instance_of(engine) do |instance|
      allow(instance).to receive(:sourcepos_disabled?).and_return(false)
    end
  end

  private

  def stub_container_registry_tag_manifest_content
    fixture_path = 'spec/fixtures/container_registry/tag_manifest.json'

    Gitlab::Json.parse(File.read(Rails.root + fixture_path))
  end

  def stub_container_registry_blob_content
    fixture_path = 'spec/fixtures/container_registry/config_blob.json'

    File.read(Rails.root + fixture_path)
  end

  def gitlab_url
    Gitlab.config.gitlab.url
  end

  def stub_user
    f = File.read(Rails.root.join('spec/support/gitlab_stubs/user.json'))

    stub_request(:get, "#{gitlab_url}api/v4/user?private_token=Wvjy2Krpb7y8xi93owUz")
      .with(headers: { 'Content-Type' => 'application/json' })
      .to_return(status: 200, body: f, headers: { 'Content-Type' => 'application/json' })

    stub_request(:get, "#{gitlab_url}api/v4/user?access_token=some_token")
      .with(headers: { 'Content-Type' => 'application/json' })
      .to_return(status: 200, body: f, headers: { 'Content-Type' => 'application/json' })
  end

  def stub_project_8
    data = File.read(Rails.root.join('spec/support/gitlab_stubs/project_8.json'))
    allow_any_instance_of(Network).to receive(:project).and_return(Gitlab::Json.parse(data))
  end

  def stub_project_8_hooks
    data = File.read(Rails.root.join('spec/support/gitlab_stubs/project_8_hooks.json'))
    allow_any_instance_of(Network).to receive(:project_hooks).and_return(Gitlab::Json.parse(data))
  end

  def stub_projects
    f = File.read(Rails.root.join('spec/support/gitlab_stubs/projects.json'))

    stub_request(:get, "#{gitlab_url}api/v4/projects.json?archived=false&ci_enabled_first=true&private_token=Wvjy2Krpb7y8xi93owUz")
      .with(headers: { 'Content-Type' => 'application/json' })
      .to_return(status: 200, body: f, headers: { 'Content-Type' => 'application/json' })
  end

  def stub_projects_owned
    stub_request(:get, "#{gitlab_url}api/v4/projects?owned=true&archived=false&ci_enabled_first=true&private_token=Wvjy2Krpb7y8xi93owUz")
      .with(headers: { 'Content-Type' => 'application/json' })
      .to_return(status: 200, body: "", headers: {})
  end

  def stub_ci_enable
    stub_request(:put, "#{gitlab_url}api/v4/projects/2/services/gitlab-ci.json?private_token=Wvjy2Krpb7y8xi93owUz")
      .with(headers: { 'Content-Type' => 'application/json' })
      .to_return(status: 200, body: "", headers: {})
  end

  def stub_webide_config_file(content, sha: anything)
    allow_any_instance_of(Repository)
      .to receive(:blob_data_at).with(sha, '.gitlab/.gitlab-webide.yml')
      .and_return(content)
  end

  def project_hash_array
    f = File.read(Rails.root.join('spec/support/gitlab_stubs/projects.json'))
    Gitlab::Json.parse(f)
  end
end

StubGitlabCalls.prepend_mod_with('StubGitlabCalls')
