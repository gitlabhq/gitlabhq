# == Schema Information
#
# Table name: user_team_user_relationships
#
#  id           :integer          not null, primary key
#  user_id      :integer
#  user_team_id :integer
#  group_admin  :boolean
#  permission   :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'spec_helper'

describe UserTeamUserRelationship do
  pending "add some examples to (or delete) #{__FILE__}"
end
