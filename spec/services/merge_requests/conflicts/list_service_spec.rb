# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::Conflicts::ListService, feature_category: :code_review_workflow do
  describe '#can_be_resolved_in_ui?' do
    def create_merge_request(source_branch, target_branch = 'conflict-start')
      create(:merge_request, source_branch: source_branch, target_branch: target_branch, merge_status: :unchecked) do |mr|
        mr.mark_as_unmergeable
      end
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
      merge_request.merge_request_diff.update!(start_commit_sha: nil)

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
      allow_next_instance_of(Gitlab::GitalyClient::ConflictsService) do |instance|
        allow(instance).to receive(:list_conflict_files).and_raise(GRPC::Unknown)
      end

      expect(service.can_be_resolved_in_ui?).to be_falsey
    end

    it 'returns a falsey value when the MR has a missing revision after a force push' do
      merge_request = create_merge_request('conflict-resolvable')
      service = conflicts_service(merge_request)
      allow(merge_request).to receive_message_chain(:target_branch_head, :raw, :id).and_return(Gitlab::Git::SHA1_BLANK_SHA)

      expect(service.can_be_resolved_in_ui?).to be_falsey
    end

    it 'returns a falsey value when the conflict is in a submodule revision' do
      merge_request = create_merge_request('update-gitlab-shell-v-6-0-3', 'update-gitlab-shell-v-6-0-1')

      expect(conflicts_service(merge_request).can_be_resolved_in_ui?).to be_falsey
    end
  end

  describe '#conflicts' do
    let(:merge_request) { build_stubbed(:merge_request) }
    let(:file_collection) { [instance_double(Gitlab::Conflict::FileCollection)] }

    it 'returns conflict file collection' do
      expect(Gitlab::Conflict::FileCollection)
        .to receive(:new)
        .with(
          merge_request,
          allow_tree_conflicts: nil,
          skip_content: nil
        )
        .and_return(file_collection)

      expect(conflicts_service(merge_request).conflicts).to eq(file_collection)
    end

    context 'when allow_tree_conflicts is set to true' do
      it 'returns conflict file collection with allow_tree_conflicts as true' do
        expect(Gitlab::Conflict::FileCollection)
          .to receive(:new)
          .with(
            merge_request,
            allow_tree_conflicts: true,
            skip_content: nil
          )
          .and_return(file_collection)

        expect(conflicts_service(merge_request, allow_tree_conflicts: true).conflicts)
          .to eq(file_collection)
      end
    end

    context 'when skip_content is set to true' do
      it 'returns conflict file collection with skip_content as true' do
        expect(Gitlab::Conflict::FileCollection)
          .to receive(:new)
          .with(
            merge_request,
            allow_tree_conflicts: nil,
            skip_content: true
          )
          .and_return(file_collection)

        expect(conflicts_service(merge_request, skip_content: true).conflicts)
          .to eq(file_collection)
      end
    end
  end

  def conflicts_service(merge_request, params = {})
    described_class.new(merge_request, params)
  end
end
