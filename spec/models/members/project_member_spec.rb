# == Schema Information
#
# Table name: members
#
#  id                 :integer          not null, primary key
#  access_level       :integer          not null
#  source_id          :integer          not null
#  source_type        :string(255)      not null
#  user_id            :integer          not null
#  notification_level :integer          not null
#  type               :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#

require 'spec_helper'

describe ProjectMember do
  describe :import_team do
    before do
      @abilities = Six.new
      @abilities << Ability

      @project_1 = create :project
      @project_2 = create :project

      @user_1 = create :user
      @user_2 = create :user

      @project_1.team << [ @user_1, :developer ]
      @project_2.team << [ @user_2, :reporter ]

      @status = @project_2.team.import(@project_1)
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

  describe :add_users_into_projects do
    before do
      @project_1 = create :project
      @project_2 = create :project

      @user_1 = create :user
      @user_2 = create :user

      ProjectMember.add_users_into_projects(
        [@project_1.id, @project_2.id],
        [@user_1.id, @user_2.id],
        ProjectMember::MASTER
      )
    end

    it { @project_1.users.should include(@user_1) }
    it { @project_1.users.should include(@user_2) }


    it { @project_2.users.should include(@user_1) }
    it { @project_2.users.should include(@user_2) }
  end

  describe :truncate_teams do
    before do
      @project_1 = create :project
      @project_2 = create :project

      @user_1 = create :user
      @user_2 = create :user

      @project_1.team << [ @user_1, :developer]
      @project_2.team << [ @user_2, :reporter]

      ProjectMember.truncate_teams([@project_1.id, @project_2.id])
    end

    it { @project_1.users.should be_empty }
    it { @project_2.users.should be_empty }
  end
end
