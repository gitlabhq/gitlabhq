# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::PipelineSourceHierarchy, feature_category: :continuous_integration do
  include Ci::SourcePipelineHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:ancestor) { create(:ci_pipeline, project: project) }
  let_it_be(:parent) { create(:ci_pipeline, project: project) }
  let_it_be(:child) { create(:ci_pipeline, project: project) }
  let_it_be(:triggered_pipeline) { create(:ci_pipeline) }
  let_it_be(:triggered_child_pipeline) { create(:ci_pipeline) }

  before_all do
    create_source_pipeline(ancestor, parent)
    create_source_pipeline(parent, child)
    create_source_pipeline(child, triggered_pipeline)
    create_source_pipeline(triggered_pipeline, triggered_child_pipeline)
  end

  def pipeline_ids(relation)
    relation.pluck(:pipeline_id)
  end

  describe '#base_and_ancestors' do
    context 'when pipeline has no relatives' do
      let_it_be(:standalone) { create(:ci_pipeline) }

      it 'includes only the pipeline itself' do
        expect(pipeline_ids(described_class.new(standalone).base_and_ancestors))
          .to contain_exactly(standalone.id)
      end
    end

    context 'when pipeline is a root with descendants' do
      it 'includes only self' do
        expect(pipeline_ids(described_class.new(ancestor).base_and_ancestors))
          .to contain_exactly(ancestor.id)
      end
    end

    context 'when pipeline is in the middle of a chain' do
      it 'includes self and all ancestors' do
        expect(pipeline_ids(described_class.new(child).base_and_ancestors))
          .to contain_exactly(ancestor.id, parent.id, child.id)
      end
    end

    context 'when pipeline is a leaf' do
      it 'includes all ancestors and self' do
        expect(pipeline_ids(described_class.new(triggered_child_pipeline).base_and_ancestors))
          .to contain_exactly(ancestor.id, parent.id, child.id, triggered_pipeline.id, triggered_child_pipeline.id)
      end
    end

    context 'when project_condition: :same' do
      it 'only traverses same-project edges' do
        expect(pipeline_ids(described_class.new(child, options: { project_condition: :same }).base_and_ancestors))
          .to contain_exactly(ancestor.id, parent.id, child.id)
      end
    end
  end

  describe '#base_and_descendants' do
    context 'when pipeline has no relatives' do
      let_it_be(:standalone) { create(:ci_pipeline) }

      it 'includes only the pipeline itself' do
        expect(pipeline_ids(described_class.new(standalone).base_and_descendants))
          .to contain_exactly(standalone.id)
      end
    end

    context 'when pipeline is a root with descendants' do
      it 'includes self and all descendants' do
        expect(pipeline_ids(described_class.new(ancestor).base_and_descendants))
          .to contain_exactly(ancestor.id, parent.id, child.id, triggered_pipeline.id, triggered_child_pipeline.id)
      end
    end

    context 'when pipeline is in the middle of a chain' do
      it 'includes self and all descendants' do
        expect(pipeline_ids(described_class.new(child).base_and_descendants))
          .to contain_exactly(child.id, triggered_pipeline.id, triggered_child_pipeline.id)
      end
    end

    context 'when pipeline is a leaf' do
      it 'includes only self' do
        expect(pipeline_ids(described_class.new(triggered_child_pipeline).base_and_descendants))
          .to contain_exactly(triggered_child_pipeline.id)
      end
    end

    context 'when project_condition: :same' do
      it 'only traverses same-project edges' do
        expect(pipeline_ids(described_class.new(parent, options: { project_condition: :same }).base_and_descendants))
          .to contain_exactly(parent.id, child.id)
      end
    end
  end

  describe '#all_objects' do
    context 'when pipeline has no relatives' do
      let_it_be(:standalone) { create(:ci_pipeline) }

      it 'includes only the pipeline itself' do
        expect(pipeline_ids(described_class.new(standalone).all_objects))
          .to contain_exactly(standalone.id)
      end
    end

    context 'when pipeline is a root with descendants' do
      it 'includes self and all descendants' do
        expect(pipeline_ids(described_class.new(ancestor).all_objects))
          .to contain_exactly(ancestor.id, parent.id, child.id, triggered_pipeline.id, triggered_child_pipeline.id)
      end
    end

    context 'when pipeline is in the middle of a chain' do
      it 'includes ancestors, self, and descendants' do
        expect(pipeline_ids(described_class.new(child).all_objects))
          .to contain_exactly(ancestor.id, parent.id, child.id, triggered_pipeline.id, triggered_child_pipeline.id)
      end
    end

    context 'when pipeline is a leaf' do
      it 'includes all ancestors and self' do
        expect(pipeline_ids(described_class.new(triggered_child_pipeline).all_objects))
          .to contain_exactly(ancestor.id, parent.id, child.id, triggered_pipeline.id, triggered_child_pipeline.id)
      end
    end

    context 'when project_condition: :same' do
      it 'only traverses same-project edges' do
        expect(pipeline_ids(described_class.new(parent, options: { project_condition: :same }).all_objects))
          .to contain_exactly(ancestor.id, parent.id, child.id)
      end
    end

    context 'when project_condition: :different' do
      it 'only traverses cross-project edges' do
        expect(pipeline_ids(described_class.new(child, options: { project_condition: :different }).all_objects))
          .to contain_exactly(child.id, triggered_pipeline.id, triggered_child_pipeline.id)
      end
    end
  end
end
