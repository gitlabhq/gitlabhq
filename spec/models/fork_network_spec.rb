# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ForkNetwork do
  include ProjectForksHelper

  describe '#add_root_as_member' do
    it 'adds the root project as a member when creating a new root network' do
      project = create(:project)
      fork_network = described_class.create!(root_project: project)

      expect(fork_network.projects).to include(project)
    end
  end

  describe '#find_fork_in' do
    it 'finds all fork of the current network in al collection' do
      network = create(:fork_network)
      root_project = network.root_project
      another_project = fork_project(root_project)
      create(:project)

      expect(network.find_forks_in(Project.all))
               .to contain_exactly(another_project, root_project)
    end
  end

  describe '#merge_requests' do
    it 'finds merge requests within the fork network' do
      project = create(:project)
      forked_project = fork_project(project)
      merge_request = create(:merge_request, source_project: forked_project, target_project: project)

      expect(project.fork_network.merge_requests).to include(merge_request)
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

      first_project.destroy!
      second_project.destroy!

      expect(first_fork.fork_network).not_to be_nil
      expect(first_fork.fork_network.root_project).to be_nil
      expect(second_fork.fork_network).not_to be_nil
      expect(second_fork.fork_network.root_project).to be_nil
    end
  end
end
