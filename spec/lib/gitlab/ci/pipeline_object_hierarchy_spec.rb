# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::PipelineObjectHierarchy do
  include Ci::SourcePipelineHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:ancestor) { create(:ci_pipeline, project: project) }
  let_it_be(:parent) { create(:ci_pipeline, project: project) }
  let_it_be(:child) { create(:ci_pipeline, project: project) }
  let_it_be(:cousin_parent) { create(:ci_pipeline, project: project) }
  let_it_be(:cousin) { create(:ci_pipeline, project: project) }
  let_it_be(:triggered_pipeline) { create(:ci_pipeline) }
  let_it_be(:triggered_child_pipeline) { create(:ci_pipeline) }

  before_all do
    create_source_pipeline(ancestor, parent)
    create_source_pipeline(ancestor, cousin_parent)
    create_source_pipeline(parent, child)
    create_source_pipeline(cousin_parent, cousin)
    create_source_pipeline(child, triggered_pipeline)
    create_source_pipeline(triggered_pipeline, triggered_child_pipeline)
  end

  describe '#base_and_ancestors' do
    it 'includes the base and its ancestors' do
      relation = described_class.new(
        ::Ci::Pipeline.where(id: parent.id),
        options: { project_condition: :same }
      ).base_and_ancestors

      expect(relation).to contain_exactly(ancestor, parent)
    end

    it 'can find ancestors upto a certain level' do
      relation = described_class.new(
        ::Ci::Pipeline.where(id: child.id),
        options: { project_condition: :same }
      ).base_and_ancestors(upto: ancestor.id)

      expect(relation).to contain_exactly(parent, child)
    end

    describe 'hierarchy_order option' do
      let(:relation) do
        described_class.new(
          ::Ci::Pipeline.where(id: child.id),
          options: { project_condition: :same }
        ).base_and_ancestors(hierarchy_order: hierarchy_order)
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
      relation = described_class.new(
        ::Ci::Pipeline.where(id: parent.id),
        options: { project_condition: :same }
      ).base_and_descendants

      expect(relation).to contain_exactly(parent, child)
    end

    context 'when project_condition: :different' do
      it "includes the base and other project pipelines" do
        relation = described_class.new(
          ::Ci::Pipeline.where(id: child.id),
          options: { project_condition: :different }
        ).base_and_descendants

        expect(relation).to contain_exactly(child, triggered_pipeline, triggered_child_pipeline)
      end
    end

    context 'when project_condition: nil' do
      it "includes the base and its descendants with other project pipeline" do
        relation = described_class.new(::Ci::Pipeline.where(id: parent.id)).base_and_descendants

        expect(relation).to contain_exactly(parent, child, triggered_pipeline, triggered_child_pipeline)
      end
    end

    context 'when with_depth is true' do
      let(:relation) do
        described_class.new(
          ::Ci::Pipeline.where(id: ancestor.id),
          options: { project_condition: :same }
        ).base_and_descendants(with_depth: true)
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
    context 'when passing ancestors_base' do
      let(:options) { { project_condition: project_condition } }
      let(:ancestors_base) { ::Ci::Pipeline.where(id: child.id) }

      subject(:relation) { described_class.new(ancestors_base, options: options).all_objects }

      context 'when project_condition: :same' do
        let(:project_condition) { :same }

        it "includes its ancestors and descendants" do
          expect(relation).to contain_exactly(ancestor, parent, child)
        end
      end

      context 'when project_condition: :different' do
        let(:project_condition) { :different }

        it "includes the base and other project pipelines" do
          expect(relation).to contain_exactly(child, triggered_pipeline, triggered_child_pipeline)
        end
      end
    end

    context 'when passing ancestors_base and descendants_base' do
      let(:options) { { project_condition: project_condition } }
      let(:ancestors_base) { ::Ci::Pipeline.where(id: child.id) }
      let(:descendants_base) { described_class.new(::Ci::Pipeline.where(id: child.id), options: options).base_and_ancestors }

      subject(:relation) { described_class.new(ancestors_base, descendants_base, options: options).all_objects }

      context 'when project_condition: :same' do
        let(:project_condition) { :same }

        it 'returns all family tree' do
          expect(relation).to contain_exactly(ancestor, parent, cousin_parent, child, cousin)
        end
      end

      context 'when project_condition: :different' do
        let(:project_condition) { :different }

        it "includes the base and other project pipelines" do
          expect(relation).to contain_exactly(child, triggered_pipeline, triggered_child_pipeline)
        end
      end
    end
  end
end
