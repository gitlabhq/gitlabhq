module ProjectForksHelper
  def fork_project(project, user = nil, params = {})
    # Load the `fork_network` for the project to fork as there might be one that
    # wasn't loaded yet.
    project.reload unless project.fork_network

    unless user
      user = create(:user)
      project.add_developer(user)
    end

    unless params[:namespace] || params[:namespace_id]
      params[:namespace] = create(:group)
      params[:namespace].add_owner(user)
    end

    service = Projects::ForkService.new(project, user, params)

    create_repository = params.delete(:repository)
    # Avoid creating a repository
    unless create_repository
      allow(RepositoryForkWorker).to receive(:perform_async).and_return(true)
      shell = double('gitlab_shell', fork_repository: true)
      allow(service).to receive(:gitlab_shell).and_return(shell)
    end

    forked_project = service.execute

    # Reload the both projects so they know about their newly created fork_network
    if forked_project.persisted?
      project.reload
      forked_project.reload
    end

    if create_repository
      # The call to project.repository.after_import in RepositoryForkWorker does
      # not reset the @exists variable of this forked_project.repository
      # so we have to explicitely call this method to clear the @exists variable.
      # of the instance we're returning here.
      forked_project.repository.after_import
    end

    forked_project
  end

  def fork_project_with_submodules(project, user = nil, params = {})
    forked_project = fork_project(project, user, params)
    TestEnv.copy_repo(forked_project,
                      bare_repo: TestEnv.forked_repo_path_bare,
                      refs: TestEnv::FORKED_BRANCH_SHA)
    forked_project.repository.after_import
    forked_project
  end
end
