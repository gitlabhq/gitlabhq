# frozen_string_literal: true

module StubProjectStudio
  # This can't run in a `before_all` block as long as we set all feature flags to be `false` in the `spec_helper`
  def enable_project_studio!(user)
    stub_feature_flags(tailwind_container_queries: user, paneled_view: user, global_topbar: user)

    user.project_studio_enabled = true
  end

  def disable_project_studio!(user)
    stub_feature_flags(tailwind_container_queries: false, paneled_view: false, global_topbar: false)

    user.project_studio_enabled = false
  end
end
