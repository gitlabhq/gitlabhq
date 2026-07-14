# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Partitionable::AssociationFinder, feature_category: :continuous_integration do
  let(:klass) do
    Class.new(ApplicationRecord) do
      self.table_name = 'merge_request_metrics'

      include Ci::Partitionable::AssociationFinder

      belongs_to :pipeline, class_name: 'Ci::Pipeline'
      belongs_to :merge_request
      partitionable_belongs_to_loader :pipeline

      scope :preload_pipeline, -> { with_partition_aware_preload.preload(:pipeline) }
    end
  end

  before do
    stub_const('TestPartitionableRecord', klass)
  end

  describe '.partitionable_belongs_to_loader' do
    it 'raises when the association does not exist' do
      bad_class = Class.new(ApplicationRecord) do
        self.table_name = 'merge_request_metrics'
        include Ci::Partitionable::AssociationFinder
      end

      expect { bad_class.partitionable_belongs_to_loader(:nope) }
        .to raise_error(ArgumentError, /No association :nope/)
    end

    it 'raises when the association is has_many' do
      bad_class = Class.new(ApplicationRecord) do
        self.table_name = 'merge_request_metrics'
        include Ci::Partitionable::AssociationFinder
        has_many :pipelines, class_name: 'Ci::Pipeline'
      end

      expect { bad_class.partitionable_belongs_to_loader(:pipelines) }
        .to raise_error(ArgumentError, /must be a non-polymorphic belongs_to/)
    end

    it 'raises when the association is polymorphic' do
      bad_class = Class.new(ApplicationRecord) do
        self.table_name = 'merge_request_metrics'
        include Ci::Partitionable::AssociationFinder
        belongs_to :target, polymorphic: true
      end

      expect { bad_class.partitionable_belongs_to_loader(:target) }
        .to raise_error(ArgumentError, /must be a non-polymorphic belongs_to/)
    end
  end

  describe 'overridden reader' do
    let_it_be(:project, freeze: true) { create(:project) }
    let_it_be(:pipeline, freeze: true) { create(:ci_pipeline, project: project) }

    context 'with a nil foreign key' do
      let(:record) { klass.new(pipeline_id: nil) }

      it 'returns nil without querying' do
        expect(Ci::Pipeline).not_to receive(:find_by_id)
        expect(record.pipeline).to be_nil
      end
    end

    context 'with a foreign key set' do
      let(:record) { klass.new(pipeline_id: pipeline.id) }

      it 'routes the first load through Ci::Pipeline.find_by_id' do
        expect(Ci::Pipeline).to receive(:find_by_id).with(pipeline.id).and_call_original

        expect(record.pipeline).to eq(pipeline)
      end

      it 'marks the association as loaded after the first read' do
        record.pipeline

        expect(record.association(:pipeline).loaded?).to be(true)
      end

      it 'does not call find_by_id again on subsequent reads' do
        record.pipeline

        expect(Ci::Pipeline).not_to receive(:find_by_id)
        expect(record.pipeline).to eq(pipeline)
      end
    end

    context 'when find_by_id returns nil' do
      let(:record) { klass.new(pipeline_id: non_existing_record_id) }

      it 'returns nil and marks the association as loaded with nil target' do
        expect(record.pipeline).to be_nil
        expect(record.association(:pipeline).loaded?).to be(true)
        expect(record.association(:pipeline).target).to be_nil
      end
    end
  end

  describe '.partitioned_pipeline_loaders' do
    it 'registers the association name mapped to its foreign key' do
      expect(klass.partitioned_pipeline_loaders).to eq(pipeline: 'pipeline_id')
    end
  end

  describe Ci::Partitionable::AssociationFinder::PipelineRelationPreload do
    let_it_be(:project, freeze: true) { create(:project) }
    let_it_be(:pipeline_one) { create(:ci_pipeline, project: project) }
    let_it_be(:pipeline_two) { create(:ci_pipeline, project: project) }

    let_it_be(:record_one) { create(:merge_request).metrics.tap { |m| m.update!(pipeline_id: pipeline_one.id) } }
    let_it_be(:record_two) { create(:merge_request).metrics.tap { |m| m.update!(pipeline_id: pipeline_two.id) } }

    let(:relation) { klass.where(id: [record_one.id, record_two.id]).preload_pipeline }

    it 'marks the pipeline association loaded without a per-record p_ci_pipelines query' do
      records = relation.load.to_a

      # After preload, reading the association must not issue any SQL.
      expect do
        records.each(&:pipeline)
      end.not_to make_queries

      expect(records.map(&:pipeline)).to match_array([pipeline_one, pipeline_two])
    end

    it 'still preloads sibling associations via super' do
      sibling_relation = klass
        .where(id: [record_one.id, record_two.id])
        .preload_pipeline
        .preload(:merge_request)

      records = sibling_relation.load.to_a

      expect(records.map { |r| r.association(:merge_request).loaded? }).to all(be(true))
    end

    it 'is a no-op when no partitioned association is requested' do
      expect(Gitlab::Ci::Pipeline::BulkByIdLookup).not_to receive(:new)

      klass.where(id: [record_one.id]).extending(described_class).preload(:merge_request).load
    end

    context 'with a warm partition cache covering the pipeline ids' do
      before do
        min_id, max_id = [pipeline_one.id, pipeline_two.id].minmax
        create(:ci_partition, id: pipeline_one.partition_id, pipelines_id_range: (min_id..max_id))
        Gitlab::Ci::Pipeline::PartitionCache.invalidate
      end

      after do
        Gitlab::Ci::Pipeline::PartitionCache.invalidate
      end

      it 'prunes the pipeline lookup by partition_id (no full-scan fallback)' do
        recorder = ActiveRecord::QueryRecorder.new { relation.load }

        expect(recorder.log).to include(a_string_matching(/partition_id/))
      end

      it 'does not log a full-scan fallback' do
        expect(Gitlab::AppLogger).not_to receive(:info)
          .with(hash_including(message: a_string_matching(/full scan/)))

        relation.load
      end
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(partition_aware_pipeline_preload: false)
      end

      it 'does not use BulkByIdLookup and falls back to vanilla preload' do
        expect(Gitlab::Ci::Pipeline::BulkByIdLookup).not_to receive(:new)

        records = relation.load.to_a

        expect(records.map { |r| r.association(:pipeline).loaded? }).to all(be(true))
      end
    end
  end
end
