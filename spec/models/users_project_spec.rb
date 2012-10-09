# == Schema Information
#
# Table name: users_projects
#
#  id             :integer         not null, primary key
#  user_id        :integer         not null
#  project_id     :integer         not null
#  created_at     :datetime        not null
#  updated_at     :datetime        not null
#  project_access :integer         default(0), not null
#

require 'spec_helper'

describe UsersProject do
  describe "Associations" do
    it { should belong_to(:project) }
    it { should belong_to(:user) }
  end

  describe "Mass assignment" do
    it { should_not allow_mass_assignment_of(:project_id) }
  end

  describe "Validation" do
    let!(:users_project) { create(:users_project) }

    it { should validate_presence_of(:user) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:project_id).with_message(/already exists/) }

    it { should validate_presence_of(:project) }
  end

  describe "Delegate methods" do
    it { should respond_to(:user_name) }
    it { should respond_to(:user_email) }
  end
end
