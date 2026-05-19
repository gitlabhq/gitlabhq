# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Partitionable::AssociationFinder, feature_category: :continuous_integration do
  let(:klass) do
    Class.new(ApplicationRecord) do
      self.table_name = 'merge_request_metrics'

      include Ci::Partitionable::AssociationFinder

      belongs_to :pipeline, class_name: 'Ci::Pipeline'
      partitionable_belongs_to_loader :pipeline
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

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(partitioned_pipeline_association_finder: false)
      end

      it 'falls back to the default Rails reader and does not call find_by_id' do
        record = klass.new(pipeline_id: pipeline.id)

        expect(Ci::Pipeline).not_to receive(:find_by_id)
        expect(record.pipeline).to eq(pipeline)
      end
    end
  end
end
