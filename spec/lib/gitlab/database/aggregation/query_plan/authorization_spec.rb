# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::QueryPlan::Authorization, feature_category: :value_stream_management do
  let(:user) { build_stubbed(:user) }
  let(:resource) { build_stubbed(:project) }
  let(:context) { { scope: :test_scope, current_user: user, authorization_resources: [resource] } }

  let(:engine_class) do
    Gitlab::Database::Aggregation::Engine.build do
      def self.metrics_mapping
        { count: Gitlab::Database::Aggregation::PartDefinition }
      end

      def self.dimensions_mapping
        { column: Gitlab::Database::Aggregation::ActiveRecord::DimensionDefinition }
      end

      def self.filters_mapping
        { exact_match: Gitlab::Database::Aggregation::ActiveRecord::FilterDefinition }
      end

      metrics do
        count :total_count, :integer
        count :owner_count, :integer, authorize: :read_owner_analytics
      end

      dimensions do
        column :status, :string
        column :owner_dimension, :string, authorize: :read_owner_analytics
      end

      filters do
        exact_match :status, :string
      end
    end
  end

  let(:engine) { engine_class.new(context: context) }

  before do
    allow(Ability).to receive(:allowed?).with(user, :read_owner_analytics, resource).and_return(allowed)
  end

  def build_plan(metrics: [{ identifier: :total_count }], dimensions: [], order: [])
    Gitlab::Database::Aggregation::Request.new(metrics: metrics, dimensions: dimensions, order: order)
      .to_query_plan(engine)
  end

  context 'when the user is authorized' do
    let(:allowed) { true }

    it 'keeps protected parts in a valid plan', :aggregate_failures do
      plan = build_plan(
        metrics: [{ identifier: :total_count }, { identifier: :owner_count }],
        dimensions: [{ identifier: :owner_dimension }]
      )

      expect(plan.metrics.map(&:identifier)).to contain_exactly(:total_count, :owner_count)
      expect(plan.unauthorized_parts).to be_empty
      expect(plan).to be_valid
      expect(plan).not_to be_unauthorized
    end
  end

  context 'when the user is not authorized' do
    let(:allowed) { false }

    it 'prunes protected metrics silently when authorized metrics remain', :aggregate_failures do
      plan = build_plan(metrics: [{ identifier: :total_count }, { identifier: :owner_count }])

      expect(plan.metrics.map(&:identifier)).to contain_exactly(:total_count)
      expect(plan.unauthorized_metrics.map(&:identifier)).to contain_exactly(:owner_count)
      expect(plan).to be_valid
      expect(plan).not_to be_unauthorized
    end

    it 'lists every unauthorized part, including pruned metrics', :aggregate_failures do
      plan = build_plan(
        metrics: [{ identifier: :total_count }, { identifier: :owner_count }],
        dimensions: [{ identifier: :status }, { identifier: :owner_dimension }]
      )

      expect(plan.unauthorized_parts).to contain_exactly(
        an_instance_of(Gitlab::Database::Aggregation::QueryPlan::Metric).and(have_attributes(identifier: :owner_count)),
        an_instance_of(Gitlab::Database::Aggregation::QueryPlan::Dimension)
          .and(have_attributes(identifier: :owner_dimension))
      )
      expect(plan).not_to be_valid
      expect(plan.errors.full_messages).to contain_exactly("access to dimension 'owner_dimension' is not authorized")
    end

    it 'runs the remaining plan validations when pruning leaves authorized metrics', :aggregate_failures do
      plan = build_plan(
        metrics: [{ identifier: :total_count }, { identifier: :owner_count }],
        dimensions: [{ identifier: :unknown_dimension }]
      )

      expect(plan).not_to be_valid
      expect(plan).not_to be_unauthorized
      expect(plan.errors.full_messages)
        .to contain_exactly("the specified identifier is not available: 'unknown_dimension'")
    end

    it 'fails authorization when every requested metric is pruned', :aggregate_failures do
      plan = build_plan(metrics: [{ identifier: :owner_count }])

      expect(plan).not_to be_valid
      expect(plan).to be_unauthorized
      expect(plan.errors.full_messages).to contain_exactly("access to metric 'owner_count' is not authorized")
    end

    it 'fails authorization for a protected dimension', :aggregate_failures do
      plan = build_plan(dimensions: [{ identifier: :owner_dimension }])

      expect(plan).not_to be_valid
      expect(plan).to be_unauthorized
      expect(plan.errors.full_messages).to contain_exactly("access to dimension 'owner_dimension' is not authorized")
    end

    it 'fails authorization when ordering by a pruned metric', :aggregate_failures do
      plan = build_plan(
        metrics: [{ identifier: :total_count }, { identifier: :owner_count }],
        order: [{ identifier: :owner_count, direction: :desc }]
      )

      expect(plan).not_to be_valid
      expect(plan).to be_unauthorized
      expect(plan.errors.full_messages).to contain_exactly("ordering by 'owner_count' is not authorized")
    end

    it 'skips the remaining plan validations when authorization fails', :aggregate_failures do
      plan = build_plan(
        metrics: [{ identifier: :total_count }],
        dimensions: [{ identifier: :owner_dimension }, { identifier: :unknown_dimension }]
      )

      expect(plan).not_to be_valid
      expect(plan.errors.full_messages).to contain_exactly("access to dimension 'owner_dimension' is not authorized")
    end

    it 'is not unauthorized for other validation errors', :aggregate_failures do
      plan = build_plan(dimensions: [{ identifier: :unknown_dimension }])

      expect(plan).not_to be_valid
      expect(plan).not_to be_unauthorized
      expect(plan.errors.full_messages)
        .to contain_exactly("the specified identifier is not available: 'unknown_dimension'")
    end
  end

  context 'when the engine has no authorize declarations' do
    let(:allowed) { false }
    let(:context) { { scope: :test_scope } }
    let(:engine_class) do
      Gitlab::Database::Aggregation::Engine.build do
        def self.metrics_mapping
          { count: Gitlab::Database::Aggregation::PartDefinition }
        end

        def self.dimensions_mapping
          { column: Gitlab::Database::Aggregation::ActiveRecord::DimensionDefinition }
        end

        def self.filters_mapping
          { exact_match: Gitlab::Database::Aggregation::ActiveRecord::FilterDefinition }
        end

        metrics do
          count :total_count, :integer
        end
      end
    end

    it 'does not require authorization resources', :aggregate_failures do
      plan = build_plan

      expect(plan.unauthorized_parts).to be_empty
      expect(plan).to be_valid
      expect(plan).not_to be_unauthorized
    end
  end
end
