# frozen_string_literal: true

require 'spec_helper'

describe AutoMerge::MergeWhenPipelineSucceedsService do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  let(:mr_merge_if_green_enabled) do
    create(:merge_request, merge_when_pipeline_succeeds: true, merge_user: user,
                           source_branch: "master", target_branch: 'feature',
                           source_project: project, target_project: project, state: "opened")
  end

  let(:pipeline) do
    create(:ci_pipeline, ref: mr_merge_if_green_enabled.source_branch, project: project)
  end

  let(:service) do
    described_class.new(project, user, commit_message: 'Awesome message')
  end

  describe "#available_for?" do
    subject { service.available_for?(mr_merge_if_green_enabled) }

    let(:pipeline_status) { :running }

    before do
      create(:ci_pipeline, pipeline_status, ref: mr_merge_if_green_enabled.source_branch,
                                            sha: mr_merge_if_green_enabled.diff_head_sha,
                                            project: mr_merge_if_green_enabled.source_project)
      mr_merge_if_green_enabled.update_head_pipeline
    end

    it { is_expected.to be_truthy }

    context 'when the head pipeline succeeded' do
      let(:pipeline_status) { :success }

      it { is_expected.to be_falsy }
    end
  end

  describe "#execute" do
    let(:merge_request) do
      create(:merge_request, target_project: project, source_project: project,
                             source_branch: "feature", target_branch: 'master')
    end

    context 'first time enabling' do
      before do
        allow(merge_request)
          .to receive_messages(head_pipeline: pipeline, actual_head_pipeline: pipeline)

        service.execute(merge_request)
      end

      it 'sets the params, merge_user, and flag' do
        expect(merge_request).to be_valid
        expect(merge_request.merge_when_pipeline_succeeds).to be_truthy
        expect(merge_request.merge_params).to include 'commit_message' => 'Awesome message'
        expect(merge_request.merge_user).to be user
        expect(merge_request.auto_merge_strategy).to eq AutoMergeService::STRATEGY_MERGE_WHEN_PIPELINE_SUCCEEDS
      end

      it 'creates a system note' do
        pipeline = build(:ci_pipeline)
        allow(merge_request).to receive(:actual_head_pipeline) { pipeline }

        note = merge_request.notes.last
        expect(note.note).to match "enabled an automatic merge when the pipeline for #{pipeline.sha}"
      end
    end

    context 'already approved' do
      let(:service) { described_class.new(project, user, should_remove_source_branch: true) }
      let(:build)   { create(:ci_build, ref: mr_merge_if_green_enabled.source_branch) }

      before do
        allow(mr_merge_if_green_enabled)
          .to receive_messages(head_pipeline: pipeline, actual_head_pipeline: pipeline)

        allow(mr_merge_if_green_enabled).to receive(:mergeable?)
          .and_return(true)

        allow(pipeline).to receive(:success?).and_return(true)
      end

      it 'updates the merge params' do
        expect(SystemNoteService).not_to receive(:merge_when_pipeline_succeeds)

        service.execute(mr_merge_if_green_enabled)
        expect(mr_merge_if_green_enabled.merge_params).to have_key('should_remove_source_branch')
      end
    end
  end

  describe "#process" do
    let(:merge_request_ref) { mr_merge_if_green_enabled.source_branch }
    let(:merge_request_head) do
      project.commit(mr_merge_if_green_enabled.source_branch).id
    end

    context 'when triggered by pipeline with valid ref and sha' do
      let(:triggering_pipeline) do
        create(:ci_pipeline, project: project, ref: merge_request_ref,
                             sha: merge_request_head, status: 'success',
                             head_pipeline_of: mr_merge_if_green_enabled)
      end

      it "merges all merge requests with merge when the pipeline succeeds enabled" do
        allow(mr_merge_if_green_enabled)
          .to receive_messages(head_pipeline: triggering_pipeline, actual_head_pipeline: triggering_pipeline)

        expect(MergeWorker).to receive(:perform_async)
        service.process(mr_merge_if_green_enabled)
      end
    end

    context 'when triggered by an old pipeline' do
      let(:old_pipeline) do
        create(:ci_pipeline, project: project, ref: merge_request_ref,
                             sha: '1234abcdef', status: 'success')
      end

      it 'does not merge request' do
        expect(MergeWorker).not_to receive(:perform_async)
        service.process(mr_merge_if_green_enabled)
      end
    end

    context 'when triggered by pipeline from a different branch' do
      let(:unrelated_pipeline) do
        create(:ci_pipeline, project: project, ref: 'feature',
                             sha: merge_request_head, status: 'success')
      end

      it 'does not merge request' do
        expect(MergeWorker).not_to receive(:perform_async)
        service.process(mr_merge_if_green_enabled)
      end
    end

    context 'when pipeline is merge request pipeline' do
      let(:pipeline) do
        create(:ci_pipeline, :success,
          source: :merge_request_event,
          ref: mr_merge_if_green_enabled.merge_ref_path,
          merge_request: mr_merge_if_green_enabled,
          merge_requests_as_head_pipeline: [mr_merge_if_green_enabled])
      end

      it 'merges the associated merge request' do
        allow(mr_merge_if_green_enabled)
          .to receive_messages(head_pipeline: pipeline, actual_head_pipeline: pipeline)

        expect(MergeWorker).to receive(:perform_async)
        service.process(mr_merge_if_green_enabled)
      end
    end
  end

  describe "#cancel" do
    before do
      service.cancel(mr_merge_if_green_enabled)
    end

    it "resets all the pipeline succeeds params" do
      expect(mr_merge_if_green_enabled.merge_when_pipeline_succeeds).to be_falsey
      expect(mr_merge_if_green_enabled.merge_params).to eq({})
      expect(mr_merge_if_green_enabled.merge_user).to be nil
    end

    it 'Posts a system note' do
      note = mr_merge_if_green_enabled.notes.last
      expect(note.note).to include 'canceled the automatic merge'
    end
  end

  describe "#abort" do
    before do
      service.abort(mr_merge_if_green_enabled, 'an error')
    end

    it 'posts a system note' do
      note = mr_merge_if_green_enabled.notes.last
      expect(note.note).to include 'aborted the automatic merge'
    end
  end

  describe 'pipeline integration' do
    context 'when there are multiple stages in the pipeline' do
      let(:ref) { mr_merge_if_green_enabled.source_branch }
      let(:sha) { project.commit(ref).id }

      let(:pipeline) do
        create(:ci_empty_pipeline, ref: ref, sha: sha, project: project)
      end

      let!(:build) do
        create(:ci_build, :created, pipeline: pipeline, ref: ref,
                                    name: 'build', stage: 'build')
      end

      let!(:test) do
        create(:ci_build, :created, pipeline: pipeline, ref: ref,
                                    name: 'test', stage: 'test')
      end

      before do
        # This behavior of MergeRequest: we instantiate a new object
        #
        allow_any_instance_of(MergeRequest)
          .to receive(:head_pipeline)
          .and_wrap_original do
            Ci::Pipeline.find(pipeline.id)
          end
      end

      it "doesn't merge if any of stages failed" do
        expect(MergeWorker).not_to receive(:perform_async)

        build.success
        test.reload
        test.drop
      end

      it 'merges when all stages succeeded', :sidekiq_might_not_need_inline do
        expect(MergeWorker).to receive(:perform_async)

        build.success
        test.reload
        test.success
      end
    end
  end
end
