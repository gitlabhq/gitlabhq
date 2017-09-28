require 'spec_helper'

describe ForkNetwork do
  include ProjectForksHelper

  describe '#add_root_as_member' do
    it 'adds the root project as a member when creating a new root network' do
      project = create(:project)
      fork_network = described_class.create(root_project: project)

      expect(fork_network.projects).to include(project)
    end
  end

  context 'for a deleted project' do
    it 'keeps the fork network' do
      project = create(:project, :public)
      forked = fork_project(project)
      project.destroy!

      fork_network = forked.reload.fork_network

      expect(fork_network.projects).to contain_exactly(forked)
      expect(fork_network.root_project).to be_nil
    end

    it 'allows multiple fork networks where the root project is deleted' do
      first_project = create(:project)
      second_project = create(:project)
      first_fork = fork_project(first_project)
      second_fork = fork_project(second_project)

      first_project.destroy
      second_project.destroy

      expect(first_fork.fork_network).not_to be_nil
      expect(first_fork.fork_network.root_project).to be_nil
      expect(second_fork.fork_network).not_to be_nil
      expect(second_fork.fork_network.root_project).to be_nil
    end
  end
end
