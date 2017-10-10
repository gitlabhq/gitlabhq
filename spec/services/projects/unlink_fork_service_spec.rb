require 'spec_helper'

describe Projects::UnlinkForkService do
  include ProjectForksHelper

  subject { described_class.new(forked_project, user) }

  let(:fork_link) { forked_project.forked_project_link }
  let(:project) { create(:project, :public) }
  let(:forked_project) { fork_project(project, user) }
  let(:user) { create(:user) }

  context 'with opened merge request on the source project' do
    let(:merge_request) { create(:merge_request, source_project: forked_project, target_project: fork_link.forked_from_project) }
    let(:mr_close_service) { MergeRequests::CloseService.new(forked_project, user) }

    before do
      allow(MergeRequests::CloseService).to receive(:new)
        .with(forked_project, user)
        .and_return(mr_close_service)
    end

    it 'close all pending merge requests' do
      expect(mr_close_service).to receive(:execute).with(merge_request)

      subject.execute
    end
  end

  it 'remove fork relation' do
    expect(forked_project.forked_project_link).to receive(:destroy)

    subject.execute
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
end
