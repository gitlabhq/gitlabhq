require 'spec_helper'

describe Project do
  describe :authorization do
    before do
      @p1 = create(:project)

      @u1 = create(:user)
      @u2 = create(:user)
      @u3 = create(:user)
      @u4 = @p1.chief

      @abilities = Six.new
      @abilities << Ability
    end

    let(:guest_actions) { Ability.project_guest_rules }
    let(:report_actions) { Ability.project_report_rules }
    let(:dev_actions) { Ability.project_dev_rules }
    let(:master_actions) { Ability.project_master_rules }
    let(:admin_actions) { Ability.project_admin_rules }

    describe "Non member rules" do
      it "should deny for non-project users any actions" do
        admin_actions.each do |action|
          @abilities.allowed?(@u1, action, @p1).should be_false
        end
      end
    end

    describe "Guest Rules" do
      before do
        @p1.users_projects.create(project: @p1, user: @u2, project_access: UsersProject::GUEST)
      end

      it "should allow for project user any guest actions" do
        guest_actions.each do |action|
          @abilities.allowed?(@u2, action, @p1).should be_true
        end
      end
    end

    describe "Report Rules" do
      before do
        @p1.users_projects.create(project: @p1, user: @u2, project_access: UsersProject::REPORTER)
      end

      it "should allow for project user any report actions" do
        report_actions.each do |action|
          @abilities.allowed?(@u2, action, @p1).should be_true
        end
      end
    end

    describe "Developer Rules" do
      before do
        @p1.users_projects.create(project: @p1, user: @u2, project_access: UsersProject::REPORTER)
        @p1.users_projects.create(project: @p1, user: @u3, project_access: UsersProject::DEVELOPER)
      end

      it "should deny for developer master-specific actions" do
        [dev_actions - report_actions].each do |action|
          @abilities.allowed?(@u2, action, @p1).should be_false
        end
      end

      it "should allow for project user any dev actions" do
        dev_actions.each do |action|
          @abilities.allowed?(@u3, action, @p1).should be_true
        end
      end
    end

    describe "Master Rules" do
      before do
        @p1.users_projects.create(project: @p1, user: @u2, project_access: UsersProject::DEVELOPER)
        @p1.users_projects.create(project: @p1, user: @u3, project_access: UsersProject::MASTER)
      end

      it "should deny for developer master-specific actions" do
        [master_actions - dev_actions].each do |action|
          @abilities.allowed?(@u2, action, @p1).should be_false
        end
      end

      it "should allow for project user any master actions" do
        master_actions.each do |action|
          @abilities.allowed?(@u3, action, @p1).should be_true
        end
      end
    end

    describe "Admin Rules" do
      before do
        @p1.users_projects.create(project: @p1, user: @u2, project_access: UsersProject::DEVELOPER)
        @p1.users_projects.create(project: @p1, user: @u3, project_access: UsersProject::MASTER)
      end

      it "should deny for masters admin-specific actions" do
        [admin_actions - master_actions].each do |action|
          @abilities.allowed?(@u2, action, @p1).should be_false
        end
      end

      it "should allow for project owner any admin actions" do
        admin_actions.each do |action|
          @abilities.allowed?(@u4, action, @p1).should be_true
        end
      end
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

