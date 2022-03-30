# frozen_string_literal: true

RSpec::Matchers.define :be_in_sync_with_project do |project|
  match do |project_namespace|
    # if project is not persisted make sure we do not have a persisted project_namespace for it
    break false if project.new_record? && project_namespace&.persisted?
    # don't really care if project is not in sync if the project was never persisted.
    break true if project.new_record? && !project_namespace.present?

    project_namespace.present? &&
      project.name == project_namespace.name &&
      project.path == project_namespace.path &&
      project.namespace_id == project_namespace.parent_id &&
      project.visibility_level == project_namespace.visibility_level &&
      project.shared_runners_enabled == project_namespace.shared_runners_enabled
  end

  failure_message_when_negated do |project_namespace|
    if project.new_record? && project_namespace&.persisted?
      "expected that a non persisted project #{project} does not have a persisted project namespace #{project_namespace}"
    else
      <<-MSG
        expected that the project's attributes name, path, namespace_id, visibility_level, shared_runners_enabled
        are in sync with the corresponding project namespace attributes
      MSG
    end
  end
end
