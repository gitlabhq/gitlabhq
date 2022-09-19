# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Duration do
  describe '.from_periods' do
    let(:calculated_duration) { calculate(data) }

    shared_examples 'calculating duration' do
      it do
        expect(calculated_duration).to eq(duration)
      end
    end

    context 'test sample A' do
      let(:data) do
        [[0, 1],
         [1, 2],
         [3, 4],
         [5, 6]]
      end

      let(:duration) { 4 }

      it_behaves_like 'calculating duration'
    end

    context 'test sample B' do
      let(:data) do
        [[0, 1],
         [1, 2],
         [2, 3],
         [3, 4],
         [0, 4]]
      end

      let(:duration) { 4 }

      it_behaves_like 'calculating duration'
    end

    context 'test sample C' do
      let(:data) do
        [[0, 4],
         [2, 6],
         [5, 7],
         [8, 9]]
      end

      let(:duration) { 8 }

      it_behaves_like 'calculating duration'
    end

    context 'test sample D' do
      let(:data) do
        [[0, 1],
         [2, 3],
         [4, 5],
         [6, 7]]
      end

      let(:duration) { 4 }

      it_behaves_like 'calculating duration'
    end

    context 'test sample E' do
      let(:data) do
        [[0, 1],
         [3, 9],
         [3, 4],
         [3, 5],
         [3, 8],
         [4, 5],
         [4, 7],
         [5, 8]]
      end

      let(:duration) { 7 }

      it_behaves_like 'calculating duration'
    end

    context 'test sample F' do
      let(:data) do
        [[1, 3],
         [2, 4],
         [2, 4],
         [2, 4],
         [5, 8]]
      end

      let(:duration) { 6 }

      it_behaves_like 'calculating duration'
    end

    context 'test sample G' do
      let(:data) do
        [[1, 3],
         [2, 4],
         [6, 7]]
      end

      let(:duration) { 4 }

      it_behaves_like 'calculating duration'
    end

    def calculate(data)
      periods = data.shuffle.map do |(first, last)|
        described_class::Period.new(first, last)
      end

      described_class.from_periods(periods.sort_by(&:first))
    end
  end

  describe '.from_pipeline' do
    let_it_be(:start_time) { Time.current.change(usec: 0) }
    let_it_be(:current) { start_time + 1000 }
    let_it_be(:pipeline) { create(:ci_pipeline) }
    let_it_be(:success_build) { create_build(:success, started_at: start_time, finished_at: start_time + 60) }
    let_it_be(:failed_build) { create_build(:failed, started_at: start_time + 60, finished_at: start_time + 120) }
    let_it_be(:canceled_build) { create_build(:canceled, started_at: start_time + 120, finished_at: start_time + 180) }
    let_it_be(:skipped_build) { create_build(:skipped, started_at: start_time) }
    let_it_be(:pending_build) { create_build(:pending) }
    let_it_be(:created_build) { create_build(:created) }
    let_it_be(:preparing_build) { create_build(:preparing) }
    let_it_be(:scheduled_build) { create_build(:scheduled) }
    let_it_be(:expired_scheduled_build) { create_build(:expired_scheduled) }
    let_it_be(:manual_build) { create_build(:manual) }

    let!(:running_build) { create_build(:running, started_at: start_time) }

    it 'returns the duration of the running build' do
      travel_to(current) do
        expect(described_class.from_pipeline(pipeline)).to eq 1000.seconds
      end
    end

    context 'when there is no running build' do
      let(:running_build) { nil }

      it 'returns the duration for all the builds' do
        travel_to(current) do
          expect(described_class.from_pipeline(pipeline)).to eq 180.seconds
        end
      end
    end

    context 'when there are bridge jobs' do
      let!(:success_bridge) { create_bridge(:success, started_at: start_time + 220, finished_at: start_time + 280) }
      let!(:failed_bridge) { create_bridge(:failed, started_at: start_time + 180, finished_at: start_time + 240) }
      let!(:skipped_bridge) { create_bridge(:skipped, started_at: start_time) }
      let!(:created_bridge) { create_bridge(:created) }
      let!(:manual_bridge) { create_bridge(:manual) }

      it 'returns the duration of the running build' do
        travel_to(current) do
          expect(described_class.from_pipeline(pipeline)).to eq 1000.seconds
        end
      end

      context 'when there is no running build' do
        let!(:running_build) { nil }

        it 'returns the duration for all the builds and bridge jobs' do
          travel_to(current) do
            expect(described_class.from_pipeline(pipeline)).to eq 280.seconds
          end
        end
      end
    end

    private

    def create_build(trait, **opts)
      create(:ci_build, trait, pipeline: pipeline, **opts)
    end

    def create_bridge(trait, **opts)
      create(:ci_bridge, trait, pipeline: pipeline, **opts)
    end
  end
end
