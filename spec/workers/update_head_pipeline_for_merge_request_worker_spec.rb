# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UpdateHeadPipelineForMergeRequestWorker, feature_category: :continuous_integration do
  describe '#perform' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project) }
    let_it_be(:latest_sha) { 'b83d6e391c22777fca1ed3012fce84f633d7fed0' }

    context 'when pipeline exists for the source project and branch' do
      let_it_be(:pipeline) { create(:ci_empty_pipeline, project: project, ref: merge_request.source_branch, sha: latest_sha) }

      it 'updates the head_pipeline_id of the merge_request' do
        expect { subject.perform(merge_request.id) }
          .to change { merge_request.reload.head_pipeline_id }.from(nil).to(pipeline.id)
      end

      it_behaves_like 'an idempotent worker' do
        let(:job_args) { merge_request.id }

        it 'sets the pipeline as the head pipeline when run multiple times' do
          subject

          expect(merge_request.reload.head_pipeline_id).to eq(pipeline.id)
        end
      end

      context 'when merge request sha does not equal pipeline sha' do
        before do
          merge_request.merge_request_diff.update!(head_commit_sha: Digest::SHA1.hexdigest(SecureRandom.hex))
        end

        it 'does not update head pipeline' do
          expect { subject.perform(merge_request.id) }
            .not_to change { merge_request.reload.head_pipeline_id }
        end

        it_behaves_like 'an idempotent worker' do
          let(:job_args) { merge_request.id }

          it 'does not update the head_pipeline_id when run multiple times' do
            expect { subject }
              .not_to change { merge_request.reload.head_pipeline_id }
          end
        end
      end
    end

    context 'when pipeline does not exist for the source project and branch' do
      it 'does not update the head_pipeline_id of the merge_request' do
        expect { subject.perform(merge_request.id) }
          .not_to change { merge_request.reload.head_pipeline_id }
      end

      it_behaves_like 'an idempotent worker' do
        let(:job_args) { merge_request.id }

        it 'does not update the head_pipeline_id when run multiple times' do
          expect { subject }
            .not_to change { merge_request.reload.head_pipeline_id }
        end
      end
    end

    context 'when a merge request pipeline exists' do
      let_it_be(:merge_request_pipeline) do
        create(
          :ci_pipeline,
          project: project,
          source: :merge_request_event,
          sha: latest_sha,
          merge_request: merge_request
        )
      end

      it 'sets the merge request pipeline as the head pipeline' do
        expect { subject.perform(merge_request.id) }
          .to change { merge_request.reload.head_pipeline_id }
          .from(nil).to(merge_request_pipeline.id)
      end

      it_behaves_like 'an idempotent worker' do
        let(:job_args) { merge_request.id }

        it 'sets the merge request pipeline as the head pipeline when run multiple times' do
          subject

          expect(merge_request.reload.head_pipeline_id).to eq(merge_request_pipeline.id)
        end
      end

      context 'when branch pipeline exists' do
        let!(:branch_pipeline) do
          create(:ci_pipeline, project: project, source: :push, sha: latest_sha)
        end

        it 'prioritizes the merge request pipeline as the head pipeline' do
          expect { subject.perform(merge_request.id) }
            .to change { merge_request.reload.head_pipeline_id }
            .from(nil).to(merge_request_pipeline.id)
        end

        it_behaves_like 'an idempotent worker' do
          let(:job_args) { merge_request.id }

          it 'sets the merge request pipeline as the head pipeline when run multiple times' do
            subject

            expect(merge_request.reload.head_pipeline_id).to eq(merge_request_pipeline.id)
          end
        end
      end
    end
  end
end
