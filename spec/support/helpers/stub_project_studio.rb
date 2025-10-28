# frozen_string_literal: true

module StubProjectStudio
  # This can't run in a `before_all` block as long as we set all feature flags to be `false` in the `spec_helper`
  def enable_project_studio!(user)
    stub_feature_flags(paneled_view: user)

    user.project_studio_enabled = true
  end
end
