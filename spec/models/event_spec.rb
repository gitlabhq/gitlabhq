# == Schema Information
#
# Table name: events
#
#  id         :integer         not null, primary key
#  data_type  :string(255)
#  data_id    :string(255)
#  title      :string(255)
#  data       :text
#  project_id :integer
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

require 'spec_helper'

describe Event do
  pending "add some examples to (or delete) #{__FILE__}"
end
