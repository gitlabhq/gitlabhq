require 'spec_helper'

describe UsersProject do
  describe "Associations" do
    it { should belong_to(:project) }
    it { should belong_to(:user) }
  end

  describe "Validation" do
    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:project_id) }
  end

  describe "Delegate methods" do
    it { should respond_to(:user_name) }
    it { should respond_to(:user_email) }
  end
end
# == Schema Information
#
# Table name: users_projects
#
#  id             :integer         not null, primary key
#  user_id        :integer         not null
#  project_id     :integer         not null
#  created_at     :datetime
#  updated_at     :datetime
#  repo_access    :integer         default(0), not null
#  project_access :integer         default(0), not null
#

