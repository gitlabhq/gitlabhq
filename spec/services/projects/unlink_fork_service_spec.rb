require 'spec_helper'

describe Projects::UnlinkForkService do
  subject { described_class.new(fork_project, user) }

  let(:fork_link) { create(:forked_project_link) }
  let(:fork_project) { fork_link.forked_to_project }
  let(:user) { create(:user) }

  context 'with opened merge request on the source project' do
    let(:merge_request) { create(:merge_request, source_project: fork_project, target_project: fork_link.forked_from_project) }
    let(:mr_close_service) { MergeRequests::CloseService.new(fork_project, user) }

    before do
      allow(MergeRequests::CloseService).to receive(:new)
        .with(fork_project, user)
        .and_return(mr_close_service)
    end

    it 'close all pending merge requests' do
      expect(mr_close_service).to receive(:execute).with(merge_request)

      subject.execute
    end
  end

  it 'remove fork relation' do
    expect(fork_project.forked_project_link).to receive(:destroy)

    subject.execute
  end
end
