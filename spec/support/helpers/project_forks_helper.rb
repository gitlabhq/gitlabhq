# frozen_string_literal: true

module ProjectForksHelper
  def fork_project(project, user = nil, params = {})
    Gitlab::GitalyClient.allow_n_plus_1_calls do
      fork_project_direct(project, user, params)
    end
  end

  def fork_project_direct(project, user = nil, params = {})
    # Load the `fork_network` for the project to fork as there might be one that
    # wasn't loaded yet.
    project.reload unless project.fork_network

    unless user
      user = create(:user)
      project.add_developer(user)
    end

    unless params[:namespace]
      params[:namespace] = create(:group)
      params[:namespace].add_owner(user)
    end

    namespace = params[:namespace]
    create_repository = params.delete(:repository)

    unless params[:target_project] || params[:using_service]
      target_level = [project.visibility_level, namespace.visibility_level].min
      visibility_level = Gitlab::VisibilityLevel.closest_allowed_level(target_level)
      # Builds and MRs can't have higher visibility level than repository access level.
      builds_access_level = [project.builds_access_level, project.repository_access_level].min

      params[:target_project] =
        create(:project,
          (:repository if create_repository),
          visibility_level: visibility_level,
          builds_access_level: builds_access_level,
          creator: user, namespace: namespace)
    end

    service = Projects::ForkService.new(project, user, params)

    # Avoid creating a repository
    unless create_repository
      allow(RepositoryForkWorker).to receive(:perform_async).and_return(true)
      shell = double('gitlab_shell', fork_repository: true)
      allow(service).to receive(:gitlab_shell).and_return(shell)
    end

    response = service.execute(params[:target_project])

    # This helper is expected to return a valid result.
    # This exception will be raised if someone tries to test failed states using fork_project method (not recommended).
    raise ArgumentError, response.message if response.error?

    forked_project = response[:project]

    # Reload the both projects so they know about their newly created fork_network
    if forked_project.persisted?
      project.reload
      forked_project.reload
    end

    if create_repository
      # The call to project.repository.after_import in RepositoryForkWorker does
      # not reset the @exists variable of this forked_project.repository
      # so we have to explicitly call this method to clear the @exists variable.
      # of the instance we're returning here.
      forked_project.repository.expire_content_cache
    end

    forked_project
  end

  def fork_project_with_submodules(project, user = nil, params = {})
    Gitlab::GitalyClient.allow_n_plus_1_calls do
      forked_project = fork_project_direct(project, user, params)
      repo = Gitlab::GlRepository::PROJECT.repository_for(forked_project)
      repo.create_from_bundle(TestEnv.forked_repo_bundle_path)
      repo.expire_content_cache

      forked_project
    end
  end
end
