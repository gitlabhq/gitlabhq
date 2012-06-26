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
#  id             :integer(4)      not null, primary key
#  user_id        :integer(4)      not null
#  project_id     :integer(4)      not null
#  created_at     :datetime        not null
#  updated_at     :datetime        not null
#  project_access :integer(4)      default(0), not null
#

