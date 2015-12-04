# == Schema Information
#
# Table name: ci_runner_projects
#
#  id         :integer          not null, primary key
#  runner_id  :integer          not null
#  project_id :integer          not null
#  created_at :datetime
#  updated_at :datetime
#

require 'spec_helper'

describe Ci::RunnerProject do
  pending "add some examples to (or delete) #{__FILE__}"
end
