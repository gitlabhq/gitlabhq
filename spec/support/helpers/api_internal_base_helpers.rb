# frozen_string_literal: true

require_relative 'gitlab_shell_helpers'

module APIInternalBaseHelpers
  include GitlabShellHelpers

  def gl_repository_for(container)
    case container
    when ProjectWiki
      Gitlab::GlRepository::WIKI.identifier_for_container(container)
    when Project
      Gitlab::GlRepository::PROJECT.identifier_for_container(container)
    when Snippet
      Gitlab::GlRepository::SNIPPET.identifier_for_container(container)
    end
  end

  def full_path_for(container)
    case container
    when PersonalSnippet
      "snippets/#{container.id}"
    when ProjectSnippet
      "#{container.project.full_path}/snippets/#{container.id}"
    else
      container.full_path
    end
  end

  def pull(key, container, protocol = 'ssh')
    post(
      api("/internal/allowed"),
      params: {
        key_id: key.id,
        project: full_path_for(container),
        gl_repository: gl_repository_for(container),
        action: 'git-upload-pack',
        protocol: protocol
      },
      headers: gitlab_shell_internal_api_request_header
    )
  end

  def push(key, container, protocol = 'ssh', env: nil, changes: nil)
    push_with_path(
      key,
      full_path: full_path_for(container),
      gl_repository: gl_repository_for(container),
      protocol: protocol,
      env: env,
      changes: changes,
      relative_path: container.repository.relative_path
    )
  end

  def push_with_path(key, full_path:, gl_repository: nil, protocol: 'ssh', env: nil, changes: nil, relative_path: nil)
    changes ||= 'd14d6c0abdd253381df51a723d58691b2ee1ab08 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/master'

    params = {
      changes: changes,
      key_id: key.id,
      project: full_path,
      action: 'git-receive-pack',
      protocol: protocol,
      env: env,
      relative_path: relative_path
    }
    params[:gl_repository] = gl_repository if gl_repository

    post(
      api("/internal/allowed"),
      params: params,
      headers: gitlab_shell_internal_api_request_header
    )
  end

  def archive(key, container)
    post(
      api("/internal/allowed"),
      params: {
        ref: 'master',
        key_id: key.id,
        project: full_path_for(container),
        gl_repository: gl_repository_for(container),
        action: 'git-upload-archive',
        protocol: 'ssh'
      },
      headers: gitlab_shell_internal_api_request_header
    )
  end
end
