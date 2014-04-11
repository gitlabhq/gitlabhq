# == Schema Information
#
# Table name: project_templates
#
#  id          :integer          not null, primary key
#  name        :string(100)
#  description :text
#  upload      :string(400)
#  state       :integer          default(0)
#  created_at  :datetime
#  updated_at  :datetime
#

require 'spec_helper'

describe ProjectTemplate do
  pending "add some examples to (or delete) #{__FILE__}"
end
