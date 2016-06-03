# == Schema Information
#
# Table name: ci_runner_projects
#
#  id            :integer          not null, primary key
#  runner_id     :integer          not null
#  project_id    :integer
#  created_at    :datetime
#  updated_at    :datetime
#  gl_project_id :integer
#

require 'spec_helper'

describe Ci::RunnerProject, models: true do
  pending "add some examples to (or delete) #{__FILE__}"
end
