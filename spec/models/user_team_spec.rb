# == Schema Information
#
# Table name: user_teams
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  path       :string(255)
#  owner_id   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'spec_helper'

describe UserTeam do
  pending "add some examples to (or delete) #{__FILE__}"
end
