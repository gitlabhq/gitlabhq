require 'spec_helper'

describe Project do
  describe :authorization do
    before do
      @p1 = Factory :project
      @u1 = Factory :user
      @u2 = Factory :user
      @abilities = Six.new
      @abilities << Ability
    end

    describe "read access" do
      before do
        @p1.users_projects.create(:project => @p1, :user => @u2, :project_access => UsersProject::REPORTER)
      end

      it { @abilities.allowed?(@u1, :read_project, @p1).should be_false }
      it { @abilities.allowed?(@u2, :read_project, @p1).should be_true }
    end

    describe "write access" do
      before do
        @p1.users_projects.create(:project => @p1, :user => @u2, :project_access => UsersProject::DEVELOPER)
      end

      it { @abilities.allowed?(@u1, :write_project, @p1).should be_false }
      it { @abilities.allowed?(@u2, :write_project, @p1).should be_true }
    end

    describe "admin access" do
      before do
        @p1.users_projects.create(:project => @p1, :user => @u1, :project_access => UsersProject::DEVELOPER)
        @p1.users_projects.create(:project => @p1, :user => @u2, :project_access => UsersProject::MASTER)
      end

      it { @abilities.allowed?(@u1, :admin_project, @p1).should be_false }
      it { @abilities.allowed?(@u2, :admin_project, @p1).should be_true }
    end
  end
end
# == Schema Information
#
# Table name: projects
#
#  id           :integer         not null, primary key
#  name         :string(255)
#  path         :string(255)
#  description  :text
#  created_at   :datetime
#  updated_at   :datetime
#  private_flag :boolean         default(TRUE), not null
#  code         :string(255)
#

