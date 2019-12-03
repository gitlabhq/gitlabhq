# frozen_string_literal: true

require 'spec_helper'

describe Projects::UnlinkForkService, :use_clean_rails_memory_store_caching do
  include ProjectForksHelper

  subject { described_class.new(forked_project, user) }

  let(:project) { create(:project, :public) }
  let!(:forked_project) { fork_project(project, user) }
  let(:user) { create(:user) }

  context 'with opened merge request on the source project' do
    let(:merge_request) { create(:merge_request, source_project: forked_project, target_project: forked_project.forked_from_project) }
    let(:merge_request2) { create(:merge_request, source_project: forked_project, target_project: fork_project(project)) }
    let(:merge_request_in_fork) { create(:merge_request, source_project: forked_project, target_project: forked_project) }

    let(:mr_close_service) { MergeRequests::CloseService.new(forked_project, user) }

    before do
      allow(MergeRequests::CloseService).to receive(:new)
        .with(forked_project, user)
        .and_return(mr_close_service)
    end

    it 'close all pending merge requests' do
      expect(mr_close_service).to receive(:execute).with(merge_request)
      expect(mr_close_service).to receive(:execute).with(merge_request2)

      subject.execute
    end

    it 'does not close merge requests for the project being unlinked' do
      expect(mr_close_service).not_to receive(:execute).with(merge_request_in_fork)
    end
  end

  it 'removes the link to the fork network' do
    expect(forked_project.fork_network_member).to be_present
    expect(forked_project.fork_network).to be_present

    subject.execute
    forked_project.reload

    expect(forked_project.fork_network_member).to be_nil
    expect(forked_project.reload.fork_network).to be_nil
  end

  it 'refreshes the forks count cache of the source project' do
    source = forked_project.forked_from_project

    expect(source.forks_count).to eq(1)

    subject.execute

    expect(source.forks_count).to be_zero
  end

  context 'when the source has LFS objects' do
    let(:lfs_object) { create(:lfs_object) }

    before do
      lfs_object.projects << project
    end

    it 'links the fork to the lfs object before unlinking' do
      subject.execute

      expect(lfs_object.projects).to include(forked_project)
    end

    it 'does not fail if the lfs objects were already linked' do
      lfs_object.projects << forked_project

      expect { subject.execute }.not_to raise_error
    end
  end

  context 'when the original project was deleted' do
    it 'does not fail when the original project is deleted' do
      source = forked_project.forked_from_project
      source.destroy
      forked_project.reload

      expect { subject.execute }.not_to raise_error
    end
  end

  context 'when given project is a source of forks' do
    let!(:forked_project_2) { fork_project(project, user) }
    let!(:fork_of_fork) { fork_project(forked_project, user) }

    subject { described_class.new(project, user) }

    context 'with opened merge requests from fork back to root project' do
      let!(:merge_request) { create(:merge_request, source_project: project, target_project: forked_project) }
      let!(:merge_request2) { create(:merge_request, source_project: project, target_project: fork_project(project)) }
      let!(:merge_request_in_fork) { create(:merge_request, source_project: forked_project, target_project: forked_project) }

      let(:mr_close_service) { MergeRequests::CloseService.new(project, user) }

      before do
        allow(MergeRequests::CloseService).to receive(:new)
                                                .with(project, user)
                                                .and_return(mr_close_service)
      end

      it 'closes all pending merge requests' do
        expect(mr_close_service).to receive(:execute).with(merge_request)
        expect(mr_close_service).to receive(:execute).with(merge_request2)

        subject.execute
      end

      it 'does not close merge requests that do not come from the project being unlinked' do
        expect(mr_close_service).not_to receive(:execute).with(merge_request_in_fork)

        subject.execute
      end
    end

    it 'removes its link to the fork network and updates direct network members' do
      expect(project.fork_network_member).to be_present
      expect(project.fork_network).to be_present
      expect(project.forked_to_members.count).to eq(2)
      expect(forked_project.forked_to_members.count).to eq(1)
      expect(fork_of_fork.forked_to_members.count).to eq(0)

      subject.execute

      project.reload
      forked_project.reload
      fork_of_fork.reload

      expect(project.fork_network_member).to be_nil
      expect(project.fork_network).to be_nil
      expect(forked_project.fork_network).to have_attributes(root_project_id: nil,
                                                             deleted_root_project_name: project.full_name)
      expect(project.forked_to_members.count).to eq(0)
      expect(forked_project.forked_to_members.count).to eq(1)
      expect(fork_of_fork.forked_to_members.count).to eq(0)
    end

    it 'refreshes the forks count cache of the given project' do
      expect(project.forks_count).to eq(2)

      subject.execute

      expect(project.forks_count).to be_zero
    end

    context 'when given project is a fork of an unlinked parent' do
      let!(:fork_of_fork) { fork_project(forked_project, user) }
      let(:lfs_object) { create(:lfs_object) }

      before do
        lfs_object.projects << project
      end

      it 'saves lfs objects to the root project' do
        # Remove parent from network
        described_class.new(forked_project, user).execute

        described_class.new(fork_of_fork, user).execute

        expect(lfs_object.projects).to include(fork_of_fork)
      end
    end

    context 'and is node with a parent' do
      subject { described_class.new(forked_project, user) }

      context 'with opened merge requests from and to given project' do
        let!(:mr_from_parent) { create(:merge_request, source_project: project, target_project: forked_project) }
        let!(:mr_to_parent) { create(:merge_request, source_project: forked_project, target_project: project) }
        let!(:mr_to_child) { create(:merge_request, source_project: forked_project, target_project: fork_of_fork) }
        let!(:mr_from_child) { create(:merge_request, source_project: fork_of_fork, target_project: forked_project) }
        let!(:merge_request_in_fork) { create(:merge_request, source_project: forked_project, target_project: forked_project) }

        let(:mr_close_service) { MergeRequests::CloseService.new(forked_project, user) }

        before do
          allow(MergeRequests::CloseService).to receive(:new)
            .with(forked_project, user)
            .and_return(mr_close_service)
        end

        it 'close all pending merge requests' do
          merge_requests = [mr_from_parent, mr_to_parent, mr_from_child, mr_to_child]

          merge_requests.each do |mr|
            expect(mr_close_service).to receive(:execute).with(mr).and_call_original
          end

          subject.execute

          merge_requests = MergeRequest.where(id: merge_requests)

          expect(merge_requests).to all(have_attributes(state: 'closed'))
        end

        it 'does not close merge requests which do not come from the project being unlinked' do
          expect(mr_close_service).not_to receive(:execute).with(merge_request_in_fork)

          subject.execute
        end
      end

      it 'refreshes the forks count cache of the parent and the given project' do
        expect(project.forks_count).to eq(2)
        expect(forked_project.forks_count).to eq(1)

        subject.execute

        expect(project.forks_count).to eq(1)
        expect(forked_project.forks_count).to eq(0)
      end

      it 'removes its link to the fork network and updates direct network members' do
        expect(project.fork_network).to be_present
        expect(forked_project.fork_network).to be_present
        expect(fork_of_fork.fork_network).to be_present

        expect(project.forked_to_members.count).to eq(2)
        expect(forked_project.forked_to_members.count).to eq(1)
        expect(fork_of_fork.forked_to_members.count).to eq(0)

        subject.execute
        project.reload
        forked_project.reload
        fork_of_fork.reload

        expect(project.fork_network).to be_present
        expect(forked_project.fork_network).to be_nil
        expect(fork_of_fork.fork_network).to be_present

        expect(project.forked_to_members.count).to eq(1) # 1 child is gone
        expect(forked_project.forked_to_members.count).to eq(0)
        expect(fork_of_fork.forked_to_members.count).to eq(0)
      end
    end
  end

  context 'when given project is not part of a fork network' do
    let!(:project_without_forks) { create(:project, :public) }

    subject { described_class.new(project_without_forks, user) }

    it 'does not raise errors' do
      expect { subject.execute }.not_to raise_error
    end
  end
end
