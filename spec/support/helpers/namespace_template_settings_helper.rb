# frozen_string_literal: true

# TODO: Remove in 19.2 when namespaces.file_template_project_id and
# namespaces.custom_project_templates_group_id columns are dropped.
# After that, specs can write directly via the model or factory.
#
# Helper for specs that need to set file_template_project_id or
# custom_project_templates_group_id on a group. These columns are now
# ignored on namespaces and live in namespace_template_settings.
# This helper writes directly to the DB (bypassing callbacks) and
# reloads the group's association cache.
module NamespaceTemplateSettingsHelper
  def set_file_template_project_id(group, project_id)
    Namespaces::TemplateSetting
      .find_or_create_by!(namespace_id: group.id)
      .update_column(:file_template_project_id, project_id)
    group.reset
  end
end

RSpec.configure do |config|
  config.include NamespaceTemplateSettingsHelper
end
