# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::SystemNotes::MergeRequestsService do
  include Gitlab::Routing

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:author) { create(:user) }

  let(:noteable) { create(:merge_request, source_project: project, target_project: project) }

  let(:service) { described_class.new(noteable: noteable, project: project, author: author) }

  describe '.merge_when_pipeline_succeeds' do
    let(:pipeline) { build(:ci_pipeline) }

    subject { service.merge_when_pipeline_succeeds(pipeline.sha) }

    it_behaves_like 'a system note' do
      let(:action) { 'merge' }
    end

    it "posts the 'merge when pipeline succeeds' system note" do
      expect(subject.note).to match(%r{enabled an automatic merge when the pipeline for (\w+/\w+@)?\h{40} succeeds})
    end
  end

  describe '.cancel_merge_when_pipeline_succeeds' do
    subject { service.cancel_merge_when_pipeline_succeeds }

    it_behaves_like 'a system note' do
      let(:action) { 'merge' }
    end

    it "posts the 'merge when pipeline succeeds' system note" do
      expect(subject.note).to eq "canceled the automatic merge"
    end
  end

  describe '.abort_merge_when_pipeline_succeeds' do
    subject { service.abort_merge_when_pipeline_succeeds('merge request was closed') }

    it_behaves_like 'a system note' do
      let(:action) { 'merge' }
    end

    it "posts the 'merge when pipeline succeeds' system note" do
      expect(subject.note).to eq "aborted the automatic merge because merge request was closed"
    end
  end

  describe '.handle_merge_request_draft' do
    context 'adding draft note' do
      let(:noteable) { create(:merge_request, source_project: project, title: 'Draft: Lorem ipsum') }

      subject { service.handle_merge_request_draft }

      it_behaves_like 'a system note' do
        let(:action) { 'title' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq 'marked this merge request as **draft**'
      end
    end

    context 'removing draft note' do
      subject { service.handle_merge_request_draft }

      it_behaves_like 'a system note' do
        let(:action) { 'title' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq 'marked this merge request as **ready**'
      end
    end
  end

  describe '.add_merge_request_draft_from_commit' do
    subject { service.add_merge_request_draft_from_commit(noteable.diff_head_commit) }

    it_behaves_like 'a system note' do
      let(:action) { 'title' }
    end

    it "posts the 'marked this merge request as draft from commit' system note" do
      expect(subject.note).to match(
        /marked this merge request as \*\*draft\*\* from #{Commit.reference_pattern}/
      )
    end
  end

  describe '.resolve_all_discussions' do
    subject { service.resolve_all_discussions }

    it_behaves_like 'a system note' do
      let(:action) { 'discussion' }
    end

    it 'sets the note text' do
      expect(subject.note).to eq 'resolved all threads'
    end
  end

  describe '.diff_discussion_outdated' do
    let(:discussion) { create(:diff_note_on_merge_request, project: project).to_discussion }
    let(:merge_request) { discussion.noteable }
    let(:change_position) { discussion.position }

    def reloaded_merge_request
      MergeRequest.find(merge_request.id)
    end

    let(:service) { described_class.new(project: project, author: author) }

    subject { service.diff_discussion_outdated(discussion, change_position) }

    it_behaves_like 'a system note' do
      let(:expected_noteable) { discussion.first_note.noteable }
      let(:action)            { 'outdated' }
    end

    context 'when the change_position is valid for the discussion' do
      it 'creates a new note in the discussion' do
        # we need to completely rebuild the merge request object, or the `@discussions` on the merge request are not reloaded.
        expect { subject }.to change { reloaded_merge_request.discussions.first.notes.size }.by(1)
      end

      it 'links to the diff in the system note' do
        diff_id = merge_request.merge_request_diff.id
        line_code = change_position.line_code(project.repository)
        link = diffs_project_merge_request_path(project, merge_request, diff_id: diff_id, anchor: line_code)

        expect(subject.note).to eq("changed this line in [version 1 of the diff](#{link})")
      end

      context 'discussion is on an image' do
        let(:discussion) { create(:image_diff_note_on_merge_request, project: project).to_discussion }

        it 'links to the diff in the system note' do
          diff_id = merge_request.merge_request_diff.id
          file_hash = change_position.file_hash
          link = diffs_project_merge_request_path(project, merge_request, diff_id: diff_id, anchor: file_hash)

          expect(subject.note).to eq("changed this file in [version 1 of the diff](#{link})")
        end
      end
    end

    context 'when the change_position does not point to a valid version' do
      before do
        allow(merge_request).to receive(:version_params_for).and_return(nil)
      end

      it 'creates a new note in the discussion' do
        # we need to completely rebuild the merge request object, or the `@discussions` on the merge request are not reloaded.
        expect { subject }.to change { reloaded_merge_request.discussions.first.notes.size }.by(1)
      end

      it 'does not create a link' do
        expect(subject.note).to eq('changed this line in version 1 of the diff')
      end
    end
  end

  describe '.change_branch' do
    let(:old_branch) { 'old_branch'}
    let(:new_branch) { 'new_branch'}

    it_behaves_like 'a system note' do
      let(:action) { 'branch' }

      subject { service.change_branch('target', 'update', old_branch, new_branch) }
    end

    context 'when target branch name changed' do
      context 'on update' do
        subject { service.change_branch('target', 'update', old_branch, new_branch) }

        it 'sets the note text' do
          expect(subject.note).to eq "changed target branch from `#{old_branch}` to `#{new_branch}`"
        end
      end

      context 'on delete' do
        subject { service.change_branch('target', 'delete', old_branch, new_branch) }

        it 'sets the note text' do
          expect(subject.note).to eq "deleted the `#{old_branch}` branch. This merge request now targets the `#{new_branch}` branch"
        end
      end

      context 'for invalid event_type' do
        subject { service.change_branch('target', 'invalid', old_branch, new_branch) }

        it 'raises exception' do
          expect { subject }.to raise_error /invalid value for event_type/
        end
      end
    end
  end

  describe '.change_branch_presence' do
    subject { service.change_branch_presence(:source, 'feature', :delete) }

    it_behaves_like 'a system note' do
      let(:action) { 'branch' }
    end

    context 'when source branch deleted' do
      it 'sets the note text' do
        expect(subject.note).to eq "deleted source branch `feature`"
      end
    end
  end

  describe '.new_issue_branch' do
    let(:branch) { '1-mepmep' }

    subject { service.new_issue_branch(branch, branch_project: branch_project) }

    shared_examples_for 'a system note for new issue branch' do
      it_behaves_like 'a system note' do
        let(:action) { 'branch' }
      end

      context 'when a branch is created from the new branch button' do
        it 'sets the note text' do
          expect(subject.note).to start_with("created branch [`#{branch}`]")
        end
      end
    end

    context 'branch_project is set' do
      let(:branch_project) { create(:project, :repository) }

      it_behaves_like 'a system note for new issue branch'
    end

    context 'branch_project is not set' do
      let(:branch_project) { nil }

      it_behaves_like 'a system note for new issue branch'
    end
  end

  describe '.new_merge_request' do
    subject { service.new_merge_request(merge_request) }

    let!(:merge_request) { create(:merge_request, source_project: project, source_branch: generate(:branch), target_project: project) }

    it_behaves_like 'a system note' do
      let(:action) { 'merge' }
    end

    it 'sets the new merge request note text' do
      expect(subject.note).to eq("created merge request #{merge_request.to_reference(project)} to address this issue")
    end
  end

  describe '.picked_into_branch' do
    let(:branch_name) { 'a-branch' }
    let(:commit_sha) { project.commit.sha }
    let(:merge_request) { noteable }

    subject { service.picked_into_branch(branch_name, commit_sha) }

    it_behaves_like 'a system note' do
      let(:action) { 'cherry_pick' }
    end

    it "posts the 'picked merge request' system note" do
      expect(subject.note).to eq("picked the changes into the branch [`#{branch_name}`](/#{project.full_path}/-/tree/#{branch_name}) with commit #{commit_sha}")
    end

    it 'links the merge request and the cherry-pick commit' do
      expect(subject.noteable).to eq(merge_request)
      expect(subject.commit_id).to eq(commit_sha)
    end
  end

  describe '#approve_mr' do
    subject { described_class.new(noteable: noteable, project: project, author: author).approve_mr }

    it_behaves_like 'a system note' do
      let(:action) { 'approved' }
    end

    context 'when merge request approved' do
      it 'sets the note text' do
        expect(subject.note).to eq "approved this merge request"
      end
    end
  end
end
