require 'spec_helper'

describe MergeRequests::Conflicts::ListService do
  describe '#can_be_resolved_in_ui?' do
    def create_merge_request(source_branch)
      create(:merge_request, source_branch: source_branch, target_branch: 'conflict-start') do |mr|
        mr.mark_as_unmergeable
      end
    end

    def conflicts_service(merge_request)
      described_class.new(merge_request)
    end

    it 'returns a falsey value when the MR can be merged without conflicts' do
      merge_request = create_merge_request('master')
      merge_request.mark_as_mergeable

      expect(conflicts_service(merge_request).can_be_resolved_in_ui?).to be_falsey
    end

    it 'returns a falsey value when the MR is marked as having conflicts, but has none' do
      merge_request = create_merge_request('master')

      expect(conflicts_service(merge_request).can_be_resolved_in_ui?).to be_falsey
    end

    it 'returns a falsey value when one of the MR branches is missing' do
      merge_request = create_merge_request('conflict-resolvable')
      merge_request.project.repository.rm_branch(merge_request.author, 'conflict-resolvable')

      expect(conflicts_service(merge_request).can_be_resolved_in_ui?).to be_falsey
    end

    it 'returns a falsey value when the MR does not support new diff notes' do
      merge_request = create_merge_request('conflict-resolvable')
      merge_request.merge_request_diff.update_attributes(start_commit_sha: nil)

      expect(conflicts_service(merge_request).can_be_resolved_in_ui?).to be_falsey
    end

    it 'returns a falsey value when the conflicts contain a large file' do
      merge_request = create_merge_request('conflict-too-large')

      expect(conflicts_service(merge_request).can_be_resolved_in_ui?).to be_falsey
    end

    it 'returns a falsey value when the conflicts contain a binary file' do
      merge_request = create_merge_request('conflict-binary-file')

      expect(conflicts_service(merge_request).can_be_resolved_in_ui?).to be_falsey
    end

    it 'returns a falsey value when the conflicts contain a file edited in one branch and deleted in another' do
      merge_request = create_merge_request('conflict-missing-side')

      expect(conflicts_service(merge_request).can_be_resolved_in_ui?).to be_falsey
    end

    it 'returns a truthy value when the conflicts are resolvable in the UI' do
      merge_request = create_merge_request('conflict-resolvable')

      expect(conflicts_service(merge_request).can_be_resolved_in_ui?).to be_truthy
    end

    it 'returns a truthy value when the conflicts have to be resolved in an editor' do
      merge_request = create_merge_request('conflict-contains-conflict-markers')

      expect(conflicts_service(merge_request).can_be_resolved_in_ui?).to be_truthy
    end

    it 'returns a falsey value when the MR has a missing ref after a force push' do
      merge_request = create_merge_request('conflict-resolvable')
      service = conflicts_service(merge_request)
      allow_any_instance_of(Gitlab::GitalyClient::ConflictsService).to receive(:list_conflict_files).and_raise(GRPC::Unknown)

      expect(service.can_be_resolved_in_ui?).to be_falsey
    end

    it 'returns a falsey value when the MR has a missing revision after a force push' do
      merge_request = create_merge_request('conflict-resolvable')
      service = conflicts_service(merge_request)
      allow(merge_request).to receive_message_chain(:target_branch_head, :raw, :id).and_return(Gitlab::Git::BLANK_SHA)

      expect(service.can_be_resolved_in_ui?).to be_falsey
    end

    context 'with gitaly disabled', :skip_gitaly_mock do
      it 'returns a falsey value when the MR has a missing ref after a force push' do
        merge_request = create_merge_request('conflict-resolvable')
        service = conflicts_service(merge_request)
        allow_any_instance_of(Rugged::Repository).to receive(:merge_commits).and_raise(Rugged::OdbError)

        expect(service.can_be_resolved_in_ui?).to be_falsey
      end

      it 'returns a falsey value when the MR has a missing revision after a force push' do
        merge_request = create_merge_request('conflict-resolvable')
        service = conflicts_service(merge_request)
        allow(merge_request).to receive_message_chain(:target_branch_head, :raw, :id).and_return(Gitlab::Git::BLANK_SHA)

        expect(service.can_be_resolved_in_ui?).to be_falsey
      end
    end
  end
end
