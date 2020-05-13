# frozen_string_literal: true

require 'spec_helper'

describe PlanLimits do
  let(:plan_limits) { create(:plan_limits) }
  let(:model) { ProjectHook }
  let(:count) { model.count }

  before do
    create(:project_hook)
  end

  context 'without plan limits configured' do
    describe '#exceeded?' do
      it 'does not exceed any relation offset' do
        expect(plan_limits.exceeded?(:project_hooks, model)).to be false
        expect(plan_limits.exceeded?(:project_hooks, count)).to be false
      end
    end
  end

  context 'with plan limits configured' do
    before do
      plan_limits.update!(project_hooks: 2)
    end

    describe '#exceeded?' do
      it 'does not exceed the relation offset' do
        expect(plan_limits.exceeded?(:project_hooks, model)).to be false
        expect(plan_limits.exceeded?(:project_hooks, count)).to be false
      end
    end

    context 'with boundary values' do
      before do
        create(:project_hook)
      end

      describe '#exceeded?' do
        it 'does exceed the relation offset' do
          expect(plan_limits.exceeded?(:project_hooks, model)).to be true
          expect(plan_limits.exceeded?(:project_hooks, count)).to be true
        end
      end
    end
  end

  context 'validates default values' do
    let(:columns_with_zero) do
      %w[
        ci_active_pipelines
        ci_pipeline_size
        ci_active_jobs
      ]
    end

    it "has positive values for enabled limits" do
      attributes = plan_limits.attributes
      attributes = attributes.except(described_class.primary_key)
      attributes = attributes.except(described_class.reflections.values.map(&:foreign_key))
      attributes = attributes.except(*columns_with_zero)

      expect(attributes).to all(include(be_positive))
    end

    it "has zero values for disabled limits" do
      attributes = plan_limits.attributes
      attributes = attributes.slice(*columns_with_zero)

      expect(attributes).to all(include(be_zero))
    end
  end
end
