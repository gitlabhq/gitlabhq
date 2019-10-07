# frozen_string_literal: true

module GroupAPIHelpers
  extend self

  def attributes_for_group_api(params = {})
    # project_creation_level and subgroup_creation_level are Integers in the model
    # but are strings in the API
    attributes_for(:group, params).except(:project_creation_level, :subgroup_creation_level)
  end
end
