# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::PipelineObjectHierarchy do
  let_it_be(:project) { create_default(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_empty_pipeline, status: :created, project: project) }
  let_it_be(:ancestor) { create(:ci_pipeline, project: pipeline.project) }
  let_it_be(:parent) { create(:ci_pipeline, project: pipeline.project) }
  let_it_be(:child) { create(:ci_pipeline, project: pipeline.project) }
  let_it_be(:cousin_parent) { create(:ci_pipeline, project: pipeline.project) }
  let_it_be(:cousin) { create(:ci_pipeline, project: pipeline.project) }

  before_all do
    create_source_relation(ancestor, parent)
    create_source_relation(ancestor, cousin_parent)
    create_source_relation(parent, child)
    create_source_relation(cousin_parent, cousin)
  end

  describe '#base_and_ancestors' do
    it 'includes the base and its ancestors' do
      relation = described_class.new(::Ci::Pipeline.where(id: parent.id)).base_and_ancestors

      expect(relation).to contain_exactly(ancestor, parent)
    end

    it 'can find ancestors upto a certain level' do
      relation = described_class.new(::Ci::Pipeline.where(id: child.id)).base_and_ancestors(upto: ancestor.id)

      expect(relation).to contain_exactly(parent, child)
    end

    describe 'hierarchy_order option' do
      let(:relation) do
        described_class.new(::Ci::Pipeline.where(id: child.id)).base_and_ancestors(hierarchy_order: hierarchy_order)
      end

      context ':asc' do
        let(:hierarchy_order) { :asc }

        it 'orders by child to ancestor' do
          expect(relation).to eq([child, parent, ancestor])
        end
      end

      context ':desc' do
        let(:hierarchy_order) { :desc }

        it 'orders by ancestor to child' do
          expect(relation).to eq([ancestor, parent, child])
        end
      end
    end
  end

  describe '#base_and_descendants' do
    it 'includes the base and its descendants' do
      relation = described_class.new(::Ci::Pipeline.where(id: parent.id)).base_and_descendants

      expect(relation).to contain_exactly(parent, child)
    end

    context 'when with_depth is true' do
      let(:relation) do
        described_class.new(::Ci::Pipeline.where(id: ancestor.id)).base_and_descendants(with_depth: true)
      end

      it 'includes depth in the results' do
        object_depths = {
          ancestor.id => 1,
          parent.id => 2,
          cousin_parent.id => 2,
          child.id => 3,
          cousin.id => 3
        }

        relation.each do |object|
          expect(object.depth).to eq(object_depths[object.id])
        end
      end
    end
  end

  describe '#all_objects' do
    it 'includes its ancestors and descendants' do
      relation = described_class.new(::Ci::Pipeline.where(id: parent.id)).all_objects

      expect(relation).to contain_exactly(ancestor, parent, child)
    end

    it 'returns all family tree' do
      relation = described_class.new(
        ::Ci::Pipeline.where(id: child.id),
        described_class.new(::Ci::Pipeline.where(id: child.id)).base_and_ancestors
      ).all_objects

      expect(relation).to contain_exactly(ancestor, parent, cousin_parent, child, cousin)
    end
  end

  private

  def create_source_relation(parent, child)
    create(:ci_sources_pipeline,
           source_job: create(:ci_build, pipeline: parent),
           source_project: parent.project,
           pipeline: child,
           project: child.project)
  end
end
