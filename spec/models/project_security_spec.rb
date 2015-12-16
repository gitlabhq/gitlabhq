require 'spec_helper'

describe Project, models: true do
  describe :authorization do
    before do
      @p1 = create(:project)

      @u1 = create(:user)
      @u2 = create(:user)
      @u3 = create(:user)
      @u4 = @p1.owner

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
          expect(@abilities.allowed?(@u1, action, @p1)).to be_falsey
        end
      end
    end

    describe "Guest Rules" do
      before do
        @p1.project_members.create(project: @p1, user: @u2, access_level: ProjectMember::GUEST)
      end

      it "should allow for project user any guest actions" do
        guest_actions.each do |action|
          expect(@abilities.allowed?(@u2, action, @p1)).to be_truthy
        end
      end
    end

    describe "Report Rules" do
      before do
        @p1.project_members.create(project: @p1, user: @u2, access_level: ProjectMember::REPORTER)
      end

      it "should allow for project user any report actions" do
        report_actions.each do |action|
          expect(@abilities.allowed?(@u2, action, @p1)).to be_truthy
        end
      end
    end

    describe "Developer Rules" do
      before do
        @p1.project_members.create(project: @p1, user: @u2, access_level: ProjectMember::REPORTER)
        @p1.project_members.create(project: @p1, user: @u3, access_level: ProjectMember::DEVELOPER)
      end

      it "should deny for developer master-specific actions" do
        [dev_actions - report_actions].each do |action|
          expect(@abilities.allowed?(@u2, action, @p1)).to be_falsey
        end
      end

      it "should allow for project user any dev actions" do
        dev_actions.each do |action|
          expect(@abilities.allowed?(@u3, action, @p1)).to be_truthy
        end
      end
    end

    describe "Master Rules" do
      before do
        @p1.project_members.create(project: @p1, user: @u2, access_level: ProjectMember::DEVELOPER)
        @p1.project_members.create(project: @p1, user: @u3, access_level: ProjectMember::MASTER)
      end

      it "should deny for developer master-specific actions" do
        [master_actions - dev_actions].each do |action|
          expect(@abilities.allowed?(@u2, action, @p1)).to be_falsey
        end
      end

      it "should allow for project user any master actions" do
        master_actions.each do |action|
          expect(@abilities.allowed?(@u3, action, @p1)).to be_truthy
        end
      end
    end

    describe "Admin Rules" do
      before do
        @p1.project_members.create(project: @p1, user: @u2, access_level: ProjectMember::DEVELOPER)
        @p1.project_members.create(project: @p1, user: @u3, access_level: ProjectMember::MASTER)
      end

      it "should deny for masters admin-specific actions" do
        [admin_actions - master_actions].each do |action|
          expect(@abilities.allowed?(@u2, action, @p1)).to be_falsey
        end
      end

      it "should allow for project owner any admin actions" do
        admin_actions.each do |action|
          expect(@abilities.allowed?(@u4, action, @p1)).to be_truthy
        end
      end
    end
  end
end
