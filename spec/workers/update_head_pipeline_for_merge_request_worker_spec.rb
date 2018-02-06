require 'spec_helper'

describe UpdateHeadPipelineForMergeRequestWorker do
  describe '#perform' do
    let(:user) { create(:user) }
    let(:project) { create(:project, :repository) }
    let(:merge_request) { create(:merge_request, source_project: project) }
    let(:latest_sha) { 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }

    context 'when pipeline exists for the source project and branch' do
      before do
        create(:ci_empty_pipeline, project: project, ref: merge_request.source_branch, sha: latest_sha)
      end

      it 'updates the head_pipeline_id of the merge_request' do
        expect { subject.perform(merge_request.id) }.to change { merge_request.reload.head_pipeline_id }
      end

      context 'when merge request sha does not equal pipeline sha' do
        before do
          merge_request.merge_request_diff.update(head_commit_sha: 'different_sha')
        end

        it 'does not update head_pipeline_id' do
          expect { subject.perform(merge_request.id) }.not_to raise_error

          expect(merge_request.reload.head_pipeline_id).to eq(nil)
        end
      end
    end

    context 'when pipeline does not exist for the source project and branch' do
      it 'does not update the head_pipeline_id of the merge_request' do
        expect { subject.perform(merge_request.id) }.not_to change { merge_request.reload.head_pipeline_id }
      end
    end
  end
end
