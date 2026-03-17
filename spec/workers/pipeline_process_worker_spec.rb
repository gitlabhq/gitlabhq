# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PipelineProcessWorker, feature_category: :continuous_integration do
  let_it_be(:pipeline) { create(:ci_pipeline) }

  it 'has the `until_executed` deduplicate strategy' do
    expect(described_class.get_deduplicate_strategy).to eq(:until_executed)
  end

  it 'has the option to reschedule once if deduplicated and a TTL of 1 minute' do
    expect(described_class.get_deduplication_options).to include({ if_deduplicated: :reschedule_once, ttl: 1.minute })
  end

  it_behaves_like 'an idempotent worker' do
    let(:pipeline) { create(:ci_pipeline, :created) }
    let(:job_args) { [pipeline.id] }

    before do
      create(:ci_build, :created, pipeline: pipeline)
    end

    it 'processes the pipeline' do
      expect(pipeline.status).to eq('created')
      expect(pipeline.processables.pluck(:status)).to contain_exactly('created')

      subject

      expect(pipeline.reload.status).to eq('pending')
      expect(pipeline.processables.pluck(:status)).to contain_exactly('pending')

      subject

      expect(pipeline.reload.status).to eq('pending')
      expect(pipeline.processables.pluck(:status)).to contain_exactly('pending')
    end
  end

  describe '#perform' do
    context 'when pipeline exists' do
      it 'processes pipeline' do
        expect_any_instance_of(Ci::ProcessPipelineService).to receive(:execute)

        described_class.new.perform(pipeline.id)
      end
    end

    context 'when pipeline does not exist' do
      it 'does not raise exception' do
        expect { described_class.new.perform(non_existing_record_id) }
          .not_to raise_error
      end
    end

    context 'with ci_partition_pruning_workers feature flag' do
      context 'when pipeline belongs to the current partition' do
        let_it_be(:current_partition) do
          Ci::Partition.with_status(:current).update_all(status: Ci::Partition.statuses[:active])
          Ci::Partition.with_status(:current).find_or_create_by!(id: pipeline.partition_id)
        end

        it 'finds the pipeline using the partition-scoped query and processes it' do
          recorder = ActiveRecord::QueryRecorder.new do
            described_class.new.perform(pipeline.id)
          end

          expect(recorder.log)
            .to include(/"partition_id" = #{current_partition.id} AND "p_ci_pipelines"."id" = #{pipeline.id}/)
        end
      end

      # rubocop:disable Layout/LineLength -- otherwise sql is creating unnecessary newlines.
      context 'when pipeline does not belong to the current partition' do
        let_it_be(:current_partition) do
          Ci::Partition.with_status(:current).update_all(status: Ci::Partition.statuses[:active])
          Ci::Partition.with_status(:current).find_or_create_by!(id: pipeline.partition_id + 1)
        end

        it 'falls back to the unscoped query and processes the pipeline' do
          recorder = ActiveRecord::QueryRecorder.new do
            described_class.new.perform(pipeline.id)
          end

          expect(recorder.log)
            .to include(/WHERE "p_ci_pipelines"."partition_id" = #{current_partition.id} AND "p_ci_pipelines"."id" = #{pipeline.id}/)

          expect(recorder.log)
            .to include(/WHERE "p_ci_pipelines"."id" = #{pipeline.id}/)
        end
      end
      # rubocop:enable Layout/LineLength

      context 'when pipeline does not exist' do
        it 'does not raise exception' do
          expect { described_class.new.perform(non_existing_record_id) }
            .not_to raise_error
        end

        it 'does not call ProcessPipelineService' do
          expect(Ci::ProcessPipelineService).not_to receive(:new)

          described_class.new.perform(non_existing_record_id)
        end
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(ci_partition_pruning_workers: false)
        end

        it 'skips the partition-scoped query and uses the unscoped lookup' do
          expect_any_instance_of(Ci::ProcessPipelineService).to receive(:execute)

          described_class.new.perform(pipeline.id)
        end

        context 'when pipeline does not exist' do
          it 'does not raise exception' do
            expect { described_class.new.perform(non_existing_record_id) }
              .not_to raise_error
          end
        end
      end
    end
  end
end
