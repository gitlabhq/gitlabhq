# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Duration, feature_category: :continuous_integration do
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

      described_class.send(:from_periods, periods.sort_by(&:first))
    end
  end

  describe '.from_pipeline' do
    let_it_be_with_reload(:pipeline) { create(:ci_pipeline) }

    let_it_be(:start_time) { Time.current.change(usec: 0) }
    let_it_be(:current) { start_time + 1000 }
    let_it_be(:success_build) { create_build(:success, started_at: start_time, finished_at: start_time + 50) }
    let_it_be(:failed_build) { create_build(:failed, started_at: start_time + 60, finished_at: start_time + 110) }
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
      let!(:running_build) { nil }

      it 'returns the duration for all the builds' do
        travel_to(current) do
          # 160 =  success (50) + failed (50) + canceled (60)
          expect(described_class.from_pipeline(pipeline)).to eq 160.seconds
        end
      end
    end

    context 'when there are direct bridge jobs' do
      let_it_be(:success_bridge) do
        create_bridge(:success, started_at: start_time + 220, finished_at: start_time + 280)
      end

      let_it_be(:failed_bridge) { create_bridge(:failed, started_at: start_time + 180, finished_at: start_time + 240) }
      # NOTE: bridge won't be `canceled` as it will be marked as failed when downstream pipeline is canceled
      # @see Ci::Bridge#inherit_status_from_downstream
      let_it_be(:canceled_bridge) do
        create_bridge(:failed, started_at: start_time + 180, finished_at: start_time + 210)
      end

      let_it_be(:skipped_bridge) { create_bridge(:skipped, started_at: start_time) }
      let_it_be(:created_bridge) { create_bridge(:created) }
      let_it_be(:manual_bridge) { create_bridge(:manual) }

      let_it_be(:success_bridge_pipeline) do
        create(:ci_pipeline, :success, started_at: start_time + 230, finished_at: start_time + 280).tap do |p|
          create(:ci_sources_pipeline, source_job: success_bridge, pipeline: p)
          create_build(:success, pipeline: p, started_at: start_time + 235, finished_at: start_time + 280)
          create_bridge(:success, pipeline: p, started_at: start_time + 240, finished_at: start_time + 280)
        end
      end

      let_it_be(:failed_bridge_pipeline) do
        create(:ci_pipeline, :failed, started_at: start_time + 225, finished_at: start_time + 240).tap do |p|
          create(:ci_sources_pipeline, source_job: failed_bridge, pipeline: p)
          create_build(:failed, pipeline: p, started_at: start_time + 230, finished_at: start_time + 240)
          create_bridge(:success, pipeline: p, started_at: start_time + 235, finished_at: start_time + 240)
        end
      end

      let_it_be(:canceled_bridge_pipeline) do
        create(:ci_pipeline, :canceled, started_at: start_time + 190, finished_at: start_time + 210).tap do |p|
          create(:ci_sources_pipeline, source_job: canceled_bridge, pipeline: p)
          create_build(:canceled, pipeline: p, started_at: start_time + 200, finished_at: start_time + 210)
          create_bridge(:success, pipeline: p, started_at: start_time + 205, finished_at: start_time + 210)
        end
      end

      it 'returns the duration of the running build' do
        travel_to(current) do
          expect(described_class.from_pipeline(pipeline)).to eq 1000.seconds
        end
      end

      context 'when there is no running build' do
        let!(:running_build) { nil }

        it 'returns the duration for all the builds (including self and downstreams)' do
          travel_to(current) do
            # 220 = 160 (see above)
            #     + success build (45) + failed (10) + canceled (10) - overlapping (success & failed) (5)
            expect(described_class.from_pipeline(pipeline)).to eq 220.seconds
          end
        end
      end

      # rubocop:disable RSpec/MultipleMemoizedHelpers
      context 'when there are downstream bridge jobs' do
        let_it_be(:success_direct_bridge) do
          create_bridge(:success, started_at: start_time + 280, finished_at: start_time + 400)
        end

        let_it_be(:success_downstream_pipeline) do
          create(:ci_pipeline, :success, started_at: start_time + 285, finished_at: start_time + 300).tap do |p|
            create(:ci_sources_pipeline, source_job: success_direct_bridge, pipeline: p)
            create_build(:success, pipeline: p, started_at: start_time + 290, finished_at: start_time + 296)
            create_bridge(:success, pipeline: p, started_at: start_time + 285, finished_at: start_time + 288)
          end
        end

        let_it_be(:failed_downstream_pipeline) do
          create(:ci_pipeline, :failed, started_at: start_time + 305, finished_at: start_time + 350).tap do |p|
            create(:ci_sources_pipeline, source_job: success_direct_bridge, pipeline: p)
            create_build(:failed, pipeline: p, started_at: start_time + 320, finished_at: start_time + 327)
            create_bridge(:success, pipeline: p, started_at: start_time + 305, finished_at: start_time + 350)
          end
        end

        let_it_be(:canceled_downstream_pipeline) do
          create(:ci_pipeline, :canceled, started_at: start_time + 360, finished_at: start_time + 400).tap do |p|
            create(:ci_sources_pipeline, source_job: success_direct_bridge, pipeline: p)
            create_build(:canceled, pipeline: p, started_at: start_time + 390, finished_at: start_time + 398)
            create_bridge(:success, pipeline: p, started_at: start_time + 360, finished_at: start_time + 378)
          end
        end

        it 'returns the duration of the running build' do
          travel_to(current) do
            expect(described_class.from_pipeline(pipeline)).to eq 1000.seconds
          end
        end

        context 'when there is no running build' do
          let!(:running_build) { nil }

          it 'returns the duration for all the builds (including self and downstreams)' do
            travel_to(current) do
              # 241 = 220 (see above)
              #     + success downstream build (6) + failed (7) + canceled (8)
              expect(described_class.from_pipeline(pipeline)).to eq 241.seconds
            end
          end
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers
    end

    it 'does not generate N+1 queries if more builds are added' do
      travel_to(current) do
        expect do
          described_class.from_pipeline(pipeline)
        end.not_to exceed_query_limit(1)

        create_list(:ci_build, 2, :success, pipeline: pipeline, started_at: start_time, finished_at: start_time + 50)

        expect do
          described_class.from_pipeline(pipeline)
        end.not_to exceed_query_limit(1)
      end
    end

    it 'does not generate N+1 queries if more bridges and their pipeline builds are added' do
      travel_to(current) do
        expect do
          described_class.from_pipeline(pipeline)
        end.not_to exceed_query_limit(1)

        create_list(
          :ci_bridge, 2, :success,
          pipeline: pipeline, started_at: start_time + 220, finished_at: start_time + 280).each do |bridge|
          create(:ci_pipeline, :success, started_at: start_time + 235, finished_at: start_time + 280).tap do |p|
            create(:ci_sources_pipeline, source_job: bridge, pipeline: p)
            create_builds(3, :success)
          end
        end

        expect do
          described_class.from_pipeline(pipeline)
        end.not_to exceed_query_limit(1)
      end
    end

    private

    def create_build(trait, **opts)
      create(:ci_build, trait, pipeline: pipeline, **opts)
    end

    def create_builds(counts, trait, **opts)
      create_list(:ci_build, counts, trait, pipeline: pipeline, **opts)
    end

    def create_bridge(trait, **opts)
      create(:ci_bridge, trait, pipeline: pipeline, **opts)
    end
  end
end
