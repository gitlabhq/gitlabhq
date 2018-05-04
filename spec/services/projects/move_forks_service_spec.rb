require 'spec_helper'

describe Projects::MoveForksService do
  include ProjectForksHelper

  let!(:user) { create(:user) }
  let!(:project_with_forks) { create(:project, namespace: user.namespace) }
  let!(:target_project) { create(:project, namespace: user.namespace) }
  let!(:lvl1_forked_project_1) { fork_project(project_with_forks, user) }
  let!(:lvl1_forked_project_2) { fork_project(project_with_forks, user) }
  let!(:lvl2_forked_project_1_1) { fork_project(lvl1_forked_project_1, user) }
  let!(:lvl2_forked_project_1_2) { fork_project(lvl1_forked_project_1, user) }

  subject { described_class.new(target_project, user) }

  describe '#execute' do
    context 'when moving a root forked project' do
      it 'moves the descendant forks' do
        expect(project_with_forks.forks.count).to eq 2
        expect(target_project.forks.count).to eq 0

        subject.execute(project_with_forks)

        expect(project_with_forks.forks.count).to eq 0
        expect(target_project.forks.count).to eq 2
        expect(lvl1_forked_project_1.forked_from_project).to eq target_project
        expect(lvl1_forked_project_1.fork_network_member.forked_from_project).to eq target_project
        expect(lvl1_forked_project_2.forked_from_project).to eq target_project
        expect(lvl1_forked_project_2.fork_network_member.forked_from_project).to eq target_project
      end

      it 'updates the fork network' do
        expect(project_with_forks.fork_network.root_project).to eq project_with_forks
        expect(project_with_forks.fork_network.fork_network_members.map(&:project)).to include project_with_forks

        subject.execute(project_with_forks)

        expect(target_project.reload.fork_network.root_project).to eq target_project
        expect(target_project.fork_network.fork_network_members.map(&:project)).not_to include project_with_forks
      end
    end

    context 'when moving a intermediate forked project' do
      it 'moves the descendant forks' do
        expect(lvl1_forked_project_1.forks.count).to eq 2
        expect(target_project.forks.count).to eq 0

        subject.execute(lvl1_forked_project_1)

        expect(lvl1_forked_project_1.forks.count).to eq 0
        expect(target_project.forks.count).to eq 2
        expect(lvl2_forked_project_1_1.forked_from_project).to eq target_project
        expect(lvl2_forked_project_1_1.fork_network_member.forked_from_project).to eq target_project
        expect(lvl2_forked_project_1_2.forked_from_project).to eq target_project
        expect(lvl2_forked_project_1_2.fork_network_member.forked_from_project).to eq target_project
      end

      it 'moves the ascendant fork' do
        subject.execute(lvl1_forked_project_1)

        expect(target_project.forked_from_project).to eq project_with_forks
        expect(target_project.fork_network_member.forked_from_project).to eq project_with_forks
      end

      it 'does not update fork network' do
        subject.execute(lvl1_forked_project_1)

        expect(target_project.reload.fork_network.root_project).to eq project_with_forks
      end
    end

    context 'when moving a leaf forked project' do
      it 'moves the ascendant fork' do
        subject.execute(lvl2_forked_project_1_1)

        expect(target_project.forked_from_project).to eq lvl1_forked_project_1
        expect(target_project.fork_network_member.forked_from_project).to eq lvl1_forked_project_1
      end

      it 'does not update fork network' do
        subject.execute(lvl2_forked_project_1_1)

        expect(target_project.reload.fork_network.root_project).to eq project_with_forks
      end
    end

    it 'rollbacks changes if transaction fails' do
      allow(subject).to receive(:success).and_raise(StandardError)

      expect { subject.execute(project_with_forks) }.to raise_error(StandardError)

      expect(project_with_forks.forks.count).to eq 2
      expect(target_project.forks.count).to eq 0
    end
  end
end
