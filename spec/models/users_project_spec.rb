# == Schema Information
#
# Table name: users_projects
#
#  id             :integer          not null, primary key
#  user_id        :integer          not null
#  project_id     :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  project_access :integer          default(0), not null
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
    it { should ensure_inclusion_of(:project_access).in_array(UsersProject.access_roles.values) }
  end

  describe "Delegate methods" do
    it { should respond_to(:user_name) }
    it { should respond_to(:user_email) }
  end

  describe :import_team do
    before do
      @abilities = Six.new
      @abilities << Ability

      @project_1 = create :project
      @project_2 = create :project

      @user_1 = create :user
      @user_2 = create :user

      @project_1.add_access @user_1, :write
      @project_2.add_access @user_2, :read

      @status = UsersProject.import_team(@project_1, @project_2)
    end

    it { @status.should be_true }

    describe 'project 2 should get user 1 as developer. user_2 should not be changed' do
      it { @project_2.users.should include(@user_1) }
      it { @project_2.users.should include(@user_2) }

      it { @abilities.allowed?(@user_1, :write_project, @project_2).should be_true }
      it { @abilities.allowed?(@user_2, :read_project, @project_2).should be_true }
    end

    describe 'project 1 should not be changed' do
      it { @project_1.users.should include(@user_1) }
      it { @project_1.users.should_not include(@user_2) }
    end
  end
end
