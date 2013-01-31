# == Schema Information
#
# Table name: user_team_project_relationships
#
#  id              :integer          not null, primary key
#  project_id      :integer
#  user_team_id    :integer
#  greatest_access :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require 'spec_helper'

describe UserTeamProjectRelationship do
  pending "add some examples to (or delete) #{__FILE__}"
end
