# == Schema Information
#
# Table name: protected_branches
#
#  id         :integer         not null, primary key
#  project_id :integer         not null
#  name       :string(255)     not null
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

require 'spec_helper'

describe ProtectedBranch do
  pending "add some examples to (or delete) #{__FILE__}"
end
