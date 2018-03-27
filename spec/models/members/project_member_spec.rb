require 'spec_helper'

describe ProjectMember do
  describe 'associations' do
    it { is_expected.to belong_to(:project).with_foreign_key(:source_id) }
  end

  describe 'validations' do
    it { is_expected.to allow_value('Project').for(:source_type) }
    it { is_expected.not_to allow_value('project').for(:source_type) }
    it { is_expected.to validate_inclusion_of(:access_level).in_array(Gitlab::Access.values) }
  end

  describe 'modules' do
    it { is_expected.to include_module(Gitlab::ShellAdapter) }
  end

  describe '.access_level_roles' do
    it 'returns Gitlab::Access.options' do
      expect(described_class.access_level_roles).to eq(Gitlab::Access.options)
    end
  end

  describe '.add_user' do
    it 'adds the user as a member' do
      user = create(:user)
      project = create(:project)

      expect(project.users).not_to include(user)

      described_class.add_user(project, user, :master, current_user: project.owner)

      expect(project.users.reload).to include(user)
    end
  end

  describe '#real_source_type' do
    subject { create(:project_member).real_source_type }

    it { is_expected.to eq 'Project' }
  end

  describe "#destroy" do
    let(:owner)   { create(:project_member, access_level: ProjectMember::MASTER) }
    let(:project) { owner.project }
    let(:master)  { create(:project_member, project: project) }

    it "creates an expired event when left due to expiry" do
      expired = create(:project_member, project: project, expires_at: Time.now - 6.days)
      expired.destroy
      expect(Event.recent.first.action).to eq(Event::EXPIRED)
    end

    it "creates a left event when left due to leave" do
      master.destroy
      expect(Event.recent.first.action).to eq(Event::LEFT)
    end
  end

  describe '.import_team' do
    before do
      @project_1 = create(:project)
      @project_2 = create(:project)

      @user_1 = create :user
      @user_2 = create :user

      @project_1.add_developer(@user_1)
      @project_2.add_reporter(@user_2)

      @status = @project_2.team.import(@project_1)
    end

    it { expect(@status).to be_truthy }

    describe 'project 2 should get user 1 as developer. user_2 should not be changed' do
      it { expect(@project_2.users).to include(@user_1) }
      it { expect(@project_2.users).to include(@user_2) }

      it { expect(Ability.allowed?(@user_1, :create_project, @project_2)).to be_truthy }
      it { expect(Ability.allowed?(@user_2, :read_project, @project_2)).to be_truthy }
    end

    describe 'project 1 should not be changed' do
      it { expect(@project_1.users).to include(@user_1) }
      it { expect(@project_1.users).not_to include(@user_2) }
    end
  end

  describe '.add_users_to_projects' do
    it 'adds the given users to the given projects' do
      projects = create_list(:project, 2)
      users = create_list(:user, 2)

      described_class.add_users_to_projects(
        [projects.first.id, projects.second.id],
        [users.first.id, users.second],
        described_class::MASTER)

      expect(projects.first.users).to include(users.first)
      expect(projects.first.users).to include(users.second)

      expect(projects.second.users).to include(users.first)
      expect(projects.second.users).to include(users.second)
    end
  end

  describe '.truncate_teams' do
    before do
      @project_1 = create(:project)
      @project_2 = create(:project)

      @user_1 = create :user
      @user_2 = create :user

      @project_1.add_developer(@user_1)
      @project_2.add_reporter(@user_2)

      described_class.truncate_teams([@project_1.id, @project_2.id])
    end

    it { expect(@project_1.users).to be_empty }
    it { expect(@project_2.users).to be_empty }
  end

  describe 'notifications' do
    describe '#after_accept_request' do
      it 'calls NotificationService.new_project_member' do
        member = create(:project_member, user: create(:user), requested_at: Time.now)

        expect_any_instance_of(NotificationService).to receive(:new_project_member)

        member.__send__(:after_accept_request)
      end
    end
  end
end
