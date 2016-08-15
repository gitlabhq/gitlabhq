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
  describe 'associations' do
    it { is_expected.to belong_to(:project).class_name('Project').with_foreign_key(:source_id) }
  end

  describe 'validations' do
    it { is_expected.to allow_value('Project').for(:source_type) }
    it { is_expected.not_to allow_value('project').for(:source_type) }
    it { is_expected.to validate_inclusion_of(:access_level).in_array(Gitlab::Access.values) }
  end

  describe 'modules' do
    it { is_expected.to include_module(Gitlab::ShellAdapter) }
  end

  describe '#real_source_type' do
    subject { create(:project_member).real_source_type }

    it { is_expected.to eq 'Project' }
  end

  describe "#destroy" do
    let(:owner)   { create(:project_member, access_level: ProjectMember::MASTER) }
    let(:project) { owner.project }
    let(:master)  { create(:project_member, project: project) }

    let(:owner_todos)  { (0...2).map { create(:todo, user: owner.user, project: project) } }
    let(:master_todos) { (0...3).map { create(:todo, user: master.user, project: project) } }

    before do
      owner_todos
      master_todos
    end

    it "destroys itself and delete associated todos" do
      expect(owner.user.todos.size).to eq(2)
      expect(master.user.todos.size).to eq(3)
      expect(Todo.count).to eq(5)

      master_todo_ids = master_todos.map(&:id)
      master.destroy

      expect(owner.user.todos.size).to eq(2)
      expect(Todo.count).to eq(2)
      master_todo_ids.each do |id|
        expect(Todo.exists?(id)).to eq(false)
      end
    end
  end

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

  describe '.add_users_to_projects' do
    before do
      @project_1 = create :project
      @project_2 = create :project

      @user_1 = create :user
      @user_2 = create :user

      ProjectMember.add_users_to_projects(
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

  describe '.truncate_teams' do
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

  describe 'notifications' do
    describe '#after_accept_request' do
      it 'calls NotificationService.new_project_member' do
        member = create(:project_member, user: build_stubbed(:user), requested_at: Time.now)

        expect_any_instance_of(NotificationService).to receive(:new_project_member)

        member.__send__(:after_accept_request)
      end
    end
  end
end
