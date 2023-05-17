# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::UpdateHeadPipelineWorker, feature_category: :code_review_workflow do
  include ProjectForksHelper

  let_it_be(:project) { create(:project, :repository) }

  let(:ref) { 'master' }
  let(:pipeline) { create(:ci_pipeline, project: project, ref: ref) }
  let(:event) { Ci::PipelineCreatedEvent.new(data: { pipeline_id: pipeline.id }) }

  subject { consume_event(subscriber: described_class, event: event) }

  it_behaves_like 'subscribes to event'

  context 'when merge requests already exist for this source branch', :sidekiq_inline do
    let(:merge_request_1) do
      create(:merge_request, source_branch: 'feature', target_branch: "master", source_project: project)
    end

    let(:merge_request_2) do
      create(:merge_request, source_branch: 'feature', target_branch: "v1.1.0", source_project: project)
    end

    context 'when the head pipeline sha equals merge request sha' do
      let(:ref) { 'feature' }

      before do
        pipeline.update!(sha: project.repository.commit(ref).id)
      end

      it 'updates head pipeline of each merge request' do
        merge_request_1
        merge_request_2

        subject

        expect(merge_request_1.reload.head_pipeline).to eq(pipeline)
        expect(merge_request_2.reload.head_pipeline).to eq(pipeline)
      end

      context 'when the merge request is not open' do
        before do
          merge_request_1.close!
        end

        it 'only updates the open merge requests' do
          merge_request_1
          merge_request_2

          subject

          expect(merge_request_1.reload.head_pipeline).not_to eq(pipeline)
          expect(merge_request_2.reload.head_pipeline).to eq(pipeline)
        end
      end
    end

    context 'when the head pipeline sha does not equal merge request sha' do
      let(:ref) { 'feature' }

      it 'does not update the head piepeline of MRs' do
        merge_request_1
        merge_request_2

        subject

        expect(merge_request_1.reload.head_pipeline).not_to eq(pipeline)
        expect(merge_request_2.reload.head_pipeline).not_to eq(pipeline)
      end
    end

    context 'when there is no pipeline for source branch' do
      it "does not update merge request head pipeline" do
        merge_request = create(
          :merge_request,
          source_branch: 'feature',
          target_branch: "branch_1",
          source_project: project
        )

        subject

        expect(merge_request.reload.head_pipeline).not_to eq(pipeline)
      end
    end

    context 'when merge request target project is different from source project' do
      let(:project) { fork_project(target_project, nil, repository: true) }
      let(:target_project) { create(:project, :repository) }
      let(:user) { create(:user) }
      let(:ref) { 'feature' }

      before do
        project.add_developer(user)
        pipeline.update!(sha: project.repository.commit(ref).id)
      end

      it 'updates head pipeline for merge request' do
        merge_request = create(
          :merge_request,
          source_branch: 'feature',
          target_branch: "master",
          source_project: project,
          target_project: target_project
        )

        subject

        expect(merge_request.reload.head_pipeline).to eq(pipeline)
      end
    end

    context 'when the pipeline is not the latest for the branch' do
      it 'does not update merge request head pipeline' do
        merge_request = create(
          :merge_request,
          source_branch: 'master',
          target_branch: "branch_1",
          source_project: project
        )

        create(:ci_pipeline, project: pipeline.project, ref: pipeline.ref)

        subject

        expect(merge_request.reload.head_pipeline).to be_nil
      end
    end

    context 'when pipeline has errors' do
      before do
        pipeline.update!(yaml_errors: 'some errors', status: :failed)
      end

      it 'updates merge request head pipeline reference' do
        merge_request = create(
          :merge_request,
          source_branch: 'master',
          target_branch: 'feature',
          source_project: project
        )

        subject

        expect(merge_request.reload.head_pipeline).to eq(pipeline)
      end
    end
  end
end
