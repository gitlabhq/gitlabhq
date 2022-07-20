# frozen_string_literal: true

module HarborHelper
  def harbor_repository_url(container, *args)
    if container.is_a?(Project)
      project_harbor_repositories_path(container, *args)
    else
      group_harbor_repositories_path(container, *args)
    end
  end

  def harbor_artifact_url(container, *args)
    if container.is_a?(Project)
      project_harbor_repository_artifacts_path(container, *args)
    else
      group_harbor_repository_artifacts_path(container, *args)
    end
  end

  def harbor_tag_url(container, *args)
    if container.is_a?(Project)
      project_harbor_repository_artifact_tags_path(container, *args)
    else
      group_harbor_repository_artifact_tags_path(container, *args)
    end
  end
end
