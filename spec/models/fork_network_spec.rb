# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ForkNetwork, feature_category: :source_code_management do
  include ProjectForksHelper

  describe "validations" do
    it { is_expected.to belong_to(:organization) }

    describe "#organization_match" do
      let_it_be(:organization) { create(:organization) }
      let_it_be(:project) { create(:project, organization: organization) }

      context "when organization_id matches root_project's organization_id" do
        let(:fork_network) { build(:fork_network, root_project: project, organization: organization) }

        it "is valid" do
          expect(fork_network).to be_valid
        end
      end

      context "when organization_id does not match root_project's organization_id" do
        let_it_be(:different_organization) { create(:organization) }

        let(:fork_network) { build(:fork_network, root_project: project, organization: different_organization) }

        it "is not valid" do
          expect(fork_network).not_to be_valid
          expect(fork_network.errors[:organization_id]).to include("must match the root project organization's ID")
        end
      end

      context "when root_project is nil" do
        let(:fork_network) { build(:fork_network, root_project: nil, organization: organization) }

        it "is valid" do
          expect(fork_network).to be_valid
        end
      end
    end
  end

  describe '#add_root_as_member' do
    it 'adds the root project as a member when creating a new root network' do
      project = create(:project)
      fork_network = described_class.create!(root_project: project, organization_id: project.organization_id)

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
