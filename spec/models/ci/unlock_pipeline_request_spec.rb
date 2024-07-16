# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::UnlockPipelineRequest, :unlock_pipelines, :clean_gitlab_redis_shared_state, feature_category: :job_artifacts do
  describe '.enqueue' do
    let(:pipeline_id) { 123 }

    subject(:enqueue) { described_class.enqueue(pipeline_id) }

    it 'creates a redis entry for the given pipeline ID and returns the number of added entries' do
      freeze_time do
        expect(described_class).to receive(:log_event).with(:enqueued, [pipeline_id])
        expect { enqueue }
          .to change { pipeline_ids_waiting_to_be_unlocked }
          .from([])
          .to([pipeline_id])

        expect(enqueue).to eq(1)
        expect_to_have_pending_unlock_pipeline_request(pipeline_id, Time.current.utc.to_i)
      end
    end

    context 'when the pipeline ID is already in the queue' do
      before do
        travel_to(3.minutes.ago) do
          described_class.enqueue(pipeline_id)
        end
      end

      it 'does not create another redis entry for the same pipeline ID nor update it' do
        expect(described_class).not_to receive(:log_event)

        expect { enqueue }
          .to not_change { pipeline_ids_waiting_to_be_unlocked }
          .and not_change { timestamp_of_pending_unlock_pipeline_request(pipeline_id) }

        expect(enqueue).to eq(0)
      end
    end

    context 'when given an array of pipeline IDs' do
      let(:pipeline_ids) { [1, 2, 1] }

      subject(:enqueue) { described_class.enqueue(pipeline_ids) }

      it 'creates a redis entry for each unique pipeline ID' do
        freeze_time do
          expect(described_class).to receive(:log_event).with(:enqueued, pipeline_ids.uniq)
          expect { enqueue }
            .to change { pipeline_ids_waiting_to_be_unlocked }
            .from([])
            .to([1, 2])

          expect(enqueue).to eq(2)

          unix_timestamp = Time.current.utc.to_i
          expect_to_have_pending_unlock_pipeline_request(1, unix_timestamp)
          expect_to_have_pending_unlock_pipeline_request(2, unix_timestamp)
        end
      end
    end
  end

  describe '.next!' do
    subject(:next_result) { described_class.next! }

    context 'when there are pending pipeline IDs' do
      it 'pops and returns the oldest pipeline ID from the queue (FIFO)' do
        expected_enqueue_time = nil
        expected_pipeline_id = 1
        travel_to(3.minutes.ago) do
          expected_enqueue_time = Time.current.utc.to_i
          described_class.enqueue(expected_pipeline_id)
        end

        travel_to(2.minutes.ago) { described_class.enqueue(2) }
        travel_to(1.minute.ago) { described_class.enqueue(3) }

        expect(described_class).to receive(:log_event).with(:picked_next, 1)

        expect { next_result }
          .to change { pipeline_ids_waiting_to_be_unlocked }
          .from([1, 2, 3])
          .to([2, 3])

        pipeline_id, enqueue_timestamp = next_result

        expect(pipeline_id).to eq(expected_pipeline_id)
        expect(enqueue_timestamp).to eq(expected_enqueue_time)
      end
    end

    context 'when the queue is empty' do
      it 'does nothing' do
        expect(described_class).not_to receive(:log_event)
        expect(next_result).to be_nil
      end
    end
  end

  describe '.total_pending' do
    subject { described_class.total_pending }

    before do
      described_class.enqueue(1)
      described_class.enqueue(2)
      described_class.enqueue(3)
    end

    it { is_expected.to eq(3) }
  end
end
