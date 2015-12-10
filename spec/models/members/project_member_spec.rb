# == Schema Information
#
# Table name: members
#
#  id                 :integer          not null, primary key
#  access_level       :integer          not null
#  source_id          :integer          not null
#  source_type        :string(255)      not null
#  user_id            :integer
#  notification_level :integer          not null
#  type               :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#  created_by_id      :integer
#  invite_email       :string(255)
#  invite_token       :string(255)
#  invite_accepted_at :datetime
#

require 'spec_helper'

describe ProjectMember, models: true do
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

    it { expect(@status).to be_truthy }

    describe 'project 2 should get user 1 as developer. user_2 should not be changed' do
      it { expect(@project_2.users).to include(@user_1) }
      it { expect(@project_2.users).to include(@user_2) }

      it { expect(@abilities.allowed?(@user_1, :create_project, @project_2)).to be_truthy }
      it { expect(@abilities.allowed?(@user_2, :read_project, @project_2)).to be_truthy }
    end

    describe 'project 1 should not be changed' do
      it { expect(@project_1.users).to include(@user_1) }
      it { expect(@project_1.users).not_to include(@user_2) }
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

    it { expect(@project_1.users).to include(@user_1) }
    it { expect(@project_1.users).to include(@user_2) }


    it { expect(@project_2.users).to include(@user_1) }
    it { expect(@project_2.users).to include(@user_2) }
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

    it { expect(@project_1.users).to be_empty }
    it { expect(@project_2.users).to be_empty }
  end
end
