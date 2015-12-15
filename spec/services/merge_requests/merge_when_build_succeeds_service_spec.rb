require 'spec_helper'

describe MergeRequests::MergeWhenBuildSucceedsService do
  let(:user)          { create(:user) }
  let(:merge_request) { create(:merge_request) }

  let(:mr_merge_if_green_enabled) do
    create(:merge_request, merge_when_build_succeeds: true, merge_user: user,
                           source_branch: "source_branch", target_branch: project.default_branch,
                           source_project: project, target_project: project, state: "opened")
  end

  let(:project) { create(:project) }
  let(:ci_commit) { create(:ci_commit_with_one_job, ref: mr_merge_if_green_enabled.source_branch, project: project) }
  let(:service) { MergeRequests::MergeWhenBuildSucceedsService.new(project, user, commit_message: 'Awesome message') }

  describe "#execute" do
    context 'first time enabling' do
      before do
        allow(merge_request).to receive(:ci_commit).and_return(ci_commit)
        service.execute(merge_request)
      end

      it 'sets the params, merge_user, and flag' do
        expect(merge_request).to be_valid
        expect(merge_request.merge_when_build_succeeds).to be_truthy
        expect(merge_request.merge_params).to eq commit_message: 'Awesome message'
        expect(merge_request.merge_user).to be user
      end

      it 'creates a system note' do
        note = merge_request.notes.last
        expect(note.note).to match /Enabled an automatic merge when the build for (\w+\/\w+@)?[0-9a-z]{8}/
      end
    end

    context 'already approved' do
      let(:service) { MergeRequests::MergeWhenBuildSucceedsService.new(project, user, new_key: true) }
      let(:build)   { create(:ci_build, ref: mr_merge_if_green_enabled.source_branch) }

      before do
        allow(mr_merge_if_green_enabled).to receive(:ci_commit).and_return(ci_commit)
        allow(mr_merge_if_green_enabled).to receive(:mergeable?).and_return(true)
        allow(ci_commit).to receive(:success?).and_return(true)
      end

      it 'updates the merge params' do
        expect(SystemNoteService).not_to receive(:merge_when_build_succeeds)

        service.execute(mr_merge_if_green_enabled)
        expect(mr_merge_if_green_enabled.merge_params).to have_key(:new_key)
      end
    end
  end

  describe "#trigger" do
    let(:build)     { create(:ci_build, ref: mr_merge_if_green_enabled.source_branch, status: "success") }

    it "merges all merge requests with merge when build succeeds enabled" do
      allow_any_instance_of(MergeRequest).to receive(:ci_commit).and_return(ci_commit)
      allow(ci_commit).to receive(:success?).and_return(true)

      expect(MergeWorker).to receive(:perform_async)
      service.trigger(build)
    end
  end

  describe "#cancel" do
    before do
      service.cancel(mr_merge_if_green_enabled)
    end

    it "resets all the merge_when_build_succeeds params" do
      expect(mr_merge_if_green_enabled.merge_when_build_succeeds).to be_falsey
      expect(mr_merge_if_green_enabled.merge_params).to eq({})
      expect(mr_merge_if_green_enabled.merge_user).to be nil
    end

    it 'Posts a system note' do
      note = mr_merge_if_green_enabled.notes.last
      expect(note.note).to include 'Canceled the automatic merge'
    end
  end
end
