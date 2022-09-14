# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::ProcessableObjectHierarchy do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.owner }

  let_it_be(:pipeline) { create(:ci_empty_pipeline, project: project, ref: 'master') }

  let_it_be(:job1) { create(:ci_build, :created, pipeline: pipeline, name: 'job1') }
  let_it_be(:job2) { create(:ci_build, :created, :dependent, pipeline: pipeline, name: 'job2', needed: job1) }
  let_it_be(:job3) { create(:ci_build, :created, :dependent, pipeline: pipeline, name: 'job3', needed: job1) }
  let_it_be(:job4) { create(:ci_build, :created, :dependent, pipeline: pipeline, name: 'job4', needed: job2) }
  let_it_be(:job5) { create(:ci_build, :created, :dependent, pipeline: pipeline, name: 'job5', needed: job3) }
  let_it_be(:job6) { create(:ci_build, :created, :dependent, pipeline: pipeline, name: 'job6', needed: job4) }

  describe '#base_and_ancestors' do
    it 'includes the base and its ancestors' do
      relation = described_class.new(::Ci::Processable.where(id: job2.id)).base_and_ancestors

      expect(relation).to eq([job2, job1])
    end

    it 'can find ancestors upto a certain level' do
      relation = described_class.new(::Ci::Processable.where(id: job4.id)).base_and_ancestors(upto: job1.name)

      expect(relation).to eq([job4, job2])
    end

    describe 'hierarchy_order option' do
      let(:relation) do
        described_class.new(::Ci::Processable.where(id: job4.id)).base_and_ancestors(hierarchy_order: hierarchy_order)
      end

      context 'for :asc' do
        let(:hierarchy_order) { :asc }

        it 'orders by child to ancestor' do
          expect(relation).to eq([job4, job2, job1])
        end
      end

      context 'for :desc' do
        let(:hierarchy_order) { :desc }

        it 'orders by ancestor to child' do
          expect(relation).to eq([job1, job2, job4])
        end
      end
    end
  end

  describe '#base_and_descendants' do
    it 'includes the base and its descendants' do
      relation = described_class.new(::Ci::Processable.where(id: job2.id)).base_and_descendants

      expect(relation).to contain_exactly(job2, job4, job6)
    end

    context 'when with_depth is true' do
      let(:relation) do
        described_class.new(::Ci::Processable.where(id: job1.id)).base_and_descendants(with_depth: true)
      end

      it 'includes depth in the results' do
        object_depths = {
          job1.id => 1,
          job2.id => 2,
          job3.id => 2,
          job4.id => 3,
          job5.id => 3,
          job6.id => 4
        }

        relation.each do |object|
          expect(object.depth).to eq(object_depths[object.id])
        end
      end
    end
  end
end
