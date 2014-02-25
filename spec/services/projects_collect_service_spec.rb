require 'spec_helper'

describe Projects::CollectService do
  let(:user) { create :user }
  let(:group) { create :group }

  let(:project1) { create(:empty_project, group: group, visibility_level: Project::PUBLIC) }
  let(:project2) { create(:empty_project, group: group, visibility_level: Project::INTERNAL) }
  let(:project3) { create(:empty_project, group: group, visibility_level: Project::PRIVATE) }
  let(:project4) { create(:empty_project, group: group, visibility_level: Project::PRIVATE) }

  context 'non authenticated' do
    subject { Projects::CollectService.new.execute(nil, group: group) }

    it { should include(project1) }
    it { should_not include(project2) }
    it { should_not include(project3) }
    it { should_not include(project4) }
  end

  context 'authenticated' do
    subject { Projects::CollectService.new.execute(user, group: group) }

    it { should include(project1) }
    it { should include(project2) }
    it { should_not include(project3) }
    it { should_not include(project4) }
  end

  context 'authenticated, project member' do
    before { project3.team << [user, :developer] }

    subject { Projects::CollectService.new.execute(user, group: group) }

    it { should include(project1) }
    it { should include(project2) }
    it { should include(project3) }
    it { should_not include(project4) }
  end

  context 'authenticated, group member' do
    before { group.add_user(user, Gitlab::Access::DEVELOPER) }

    subject { Projects::CollectService.new.execute(user, group: group) }

    it { should include(project1) }
    it { should include(project2) }
    it { should include(project3) }
    it { should include(project4) }
  end
end
