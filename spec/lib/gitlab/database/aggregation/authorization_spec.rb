# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::Authorization, feature_category: :database do
  let(:user) { build_stubbed(:user) }
  let(:resource) { build_stubbed(:project) }
  let(:context) { { scope: :test_scope, current_user: user, authorization_resources: [resource] } }

  let(:engine_class) do
    Gitlab::Database::Aggregation::Engine.build do
      def self.metrics_mapping
        {
          count: Gitlab::Database::Aggregation::PartDefinition,
          metric: Gitlab::Database::Aggregation::ClickHouse::MetricDefinition
        }
      end

      def self.dimensions_mapping
        { column: Gitlab::Database::Aggregation::ActiveRecord::DimensionDefinition }
      end

      def self.filters_mapping
        {
          exact_match: Gitlab::Database::Aggregation::ActiveRecord::FilterDefinition,
          metric_exact_match: Gitlab::Database::Aggregation::ClickHouse::MetricExactMatchFilter
        }
      end

      metrics do
        count :total_count, :integer
        count :owner_count, :integer, authorize: :read_owner_analytics
        metric :"duration.max", :integer, ->(_params) { Arel.sql('max(duration)') },
          authorize: :read_owner_analytics
      end

      dimensions do
        column :status, :string
        column :owner_dimension, :string, authorize: :read_owner_analytics
        column :assignee_id, :integer, association: true, authorize: :read_owner_analytics
      end

      filters do
        exact_match :status, :string
        exact_match :owner_filter, :string, authorize: :read_owner_analytics
        metric_exact_match :owner_count, :integer
      end

      def execute_query_plan(plan)
        plan
      end
    end
  end

  let(:engine) { engine_class.new(context: context) }

  def build_request(metrics: [{ identifier: :total_count }], dimensions: [], filters: [], order: [])
    Gitlab::Database::Aggregation::Request.new(
      metrics: metrics, dimensions: dimensions, filters: filters, order: order
    )
  end

  def stub_authorized(allowed)
    allow(Ability).to receive(:allowed?).with(user, :read_owner_analytics, resource).and_return(allowed)
  end

  describe '.parts_require_authorization?' do
    it 'is true when any part declares authorize' do
      expect(engine_class.parts_require_authorization?).to be(true)
    end

    it 'is false when no part declares authorize' do
      plain_engine = Gitlab::Database::Aggregation::Engine.build do
        def self.metrics_mapping
          { count: Gitlab::Database::Aggregation::PartDefinition }
        end

        def self.dimensions_mapping
          { column: Gitlab::Database::Aggregation::PartDefinition }
        end

        def self.filters_mapping
          { column: Gitlab::Database::Aggregation::PartDefinition }
        end

        metrics do
          count :total_count, :integer
        end
      end

      expect(plain_engine.parts_require_authorization?).to be(false)
    end
  end

  describe 'authorization context requirements' do
    it 'raises ArgumentError when current_user is missing' do
      engine = engine_class.new(context: { scope: :test_scope, authorization_resources: [resource] })

      expect { engine.execute(build_request) }
        .to raise_error(ArgumentError, /`current_user:` and `authorization_resources:` are required/)
    end

    it 'raises ArgumentError when authorization_resources are missing' do
      engine = engine_class.new(context: { scope: :test_scope, current_user: user })

      expect { engine.execute(build_request) }
        .to raise_error(ArgumentError, /`current_user:` and `authorization_resources:` are required/)
    end

    it 'does not require authorization context for engines without authorize declarations' do
      plain_engine = Gitlab::Database::Aggregation::Engine.build do
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

        def execute_query_plan(plan)
          plan
        end
      end

      response = plain_engine.new(context: { scope: :test_scope }).execute(build_request)

      expect(response).to be_success
    end
  end

  describe 'metric authorization' do
    context 'when the user is authorized' do
      before do
        stub_authorized(true)
      end

      it 'keeps protected metrics in the executed plan' do
        response = engine.execute(build_request(metrics: [{ identifier: :total_count },
          { identifier: :owner_count }]))

        expect(response).to be_success
        expect(response.payload[:data].metrics.map(&:identifier)).to contain_exactly(:total_count, :owner_count)
      end
    end

    context 'when the user is not authorized' do
      before do
        stub_authorized(false)
      end

      it 'drops protected metrics from the executed plan' do
        response = engine.execute(build_request(metrics: [{ identifier: :total_count },
          { identifier: :owner_count }]))

        expect(response).to be_success
        expect(response.payload[:data].metrics.map(&:identifier)).to contain_exactly(:total_count)
      end

      it 'drops protected dotted metrics from the executed plan' do
        response = engine.execute(build_request(metrics: [{ identifier: :total_count },
          { identifier: :"duration.max" }]))

        expect(response).to be_success
        expect(response.payload[:data].metrics.map(&:identifier)).to contain_exactly(:total_count)
      end

      it 'returns a validation error when every requested metric is unauthorized' do
        response = engine.execute(build_request(metrics: [{ identifier: :owner_count }]))

        expect(response).to be_error
        expect(response.message).to include('at least one metric is required')
      end

      it 'preserves unprotected request parts when pruning' do
        response = engine.execute(build_request(
          metrics: [{ identifier: :total_count }, { identifier: :owner_count }],
          dimensions: [{ identifier: :status }],
          filters: [{ identifier: :status, values: ['opened'] }],
          order: [{ identifier: :total_count, direction: :desc }]
        ))

        expect(response).to be_success

        plan = response.payload[:data]
        expect(plan.dimensions.map(&:identifier)).to contain_exactly(:status)
        expect(plan.filters.map(&:identifier)).to contain_exactly(:status)
        expect(plan.order.map(&:identifier)).to contain_exactly(:total_count)
      end

      it 'still reports unknown metric identifiers as validation errors' do
        response = engine.execute(build_request(metrics: [{ identifier: :unknown_metric }]))

        expect(response).to be_error
        expect(response.message).to include("the specified identifier is not available: 'unknown_metric'")
      end
    end
  end

  describe 'dimension authorization' do
    before do
      stub_authorized(allowed)
    end

    context 'when the user is authorized' do
      let(:allowed) { true }

      it 'allows protected dimensions' do
        response = engine.execute(build_request(dimensions: [{ identifier: :owner_dimension }]))

        expect(response).to be_success
        expect(response.payload[:data].dimensions.map(&:identifier)).to contain_exactly(:owner_dimension)
      end
    end

    context 'when the user is not authorized' do
      let(:allowed) { false }

      it 'returns a validation error for protected dimensions' do
        response = engine.execute(build_request(dimensions: [{ identifier: :owner_dimension }]))

        expect(response).to be_error
        expect(response.message).to include("access to dimension 'owner_dimension' is not authorized")
      end

      it 'resolves association dimension aliases' do
        response = engine.execute(build_request(dimensions: [{ identifier: :assignee }]))

        expect(response).to be_error
        expect(response.message).to include("access to dimension 'assignee_id' is not authorized")
      end

      it 'allows unprotected dimensions' do
        response = engine.execute(build_request(dimensions: [{ identifier: :status }]))

        expect(response).to be_success
      end
    end
  end

  describe 'filter authorization' do
    before do
      stub_authorized(allowed)
    end

    context 'when the user is not authorized' do
      let(:allowed) { false }

      it 'returns a validation error for protected filters' do
        response = engine.execute(build_request(filters: [{ identifier: :owner_filter, values: ['x'] }]))

        expect(response).to be_error
        expect(response.message).to include("access to filter 'owner_filter' is not authorized")
      end

      it 'returns a validation error for metric filters referencing a protected metric' do
        response = engine.execute(build_request(
          metrics: [{ identifier: :owner_count }],
          filters: [{ identifier: :owner_count, values: [1] }]
        ))

        expect(response).to be_error
        expect(response.message).to include("access to filter 'owner_count' is not authorized")
      end

      it 'allows unprotected filters' do
        response = engine.execute(build_request(filters: [{ identifier: :status, values: ['opened'] }]))

        expect(response).to be_success
      end
    end

    context 'when the user is authorized' do
      let(:allowed) { true }

      it 'allows protected filters' do
        response = engine.execute(build_request(filters: [{ identifier: :owner_filter, values: ['x'] }]))

        expect(response).to be_success
      end
    end
  end

  describe 'order authorization' do
    before do
      stub_authorized(allowed)
    end

    context 'when the user is not authorized' do
      let(:allowed) { false }

      it 'returns a validation error when ordering by a protected metric' do
        response = engine.execute(build_request(
          metrics: [{ identifier: :total_count }, { identifier: :owner_count }],
          order: [{ identifier: :owner_count, direction: :desc }]
        ))

        expect(response).to be_error
        expect(response.message).to include("ordering by 'owner_count' is not authorized")
      end

      it 'returns a validation error when ordering by a protected dimension' do
        response = engine.execute(build_request(
          dimensions: [{ identifier: :owner_dimension }],
          order: [{ identifier: :owner_dimension, direction: :asc }]
        ))

        expect(response).to be_error
        expect(response.message).to include("ordering by 'owner_dimension' is not authorized")
      end
    end

    context 'when the user is authorized' do
      let(:allowed) { true }

      it 'allows ordering by protected parts' do
        response = engine.execute(build_request(
          metrics: [{ identifier: :owner_count }],
          order: [{ identifier: :owner_count, direction: :desc }]
        ))

        expect(response).to be_success
      end
    end
  end

  describe 'callable authorization' do
    let(:other_resource) { build_stubbed(:project) }
    let(:context) do
      { scope: :test_scope, current_user: user, authorization_resources: [resource, other_resource] }
    end

    let(:received_arguments) { [] }

    let(:engine_class) do
      callable_result = allowed
      arguments = received_arguments
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
          count :owner_count, :integer, authorize: ->(user, resources) do
            arguments << [user, resources]
            callable_result
          end
        end

        def execute_query_plan(plan)
          plan
        end
      end
    end

    context 'when the callable allows access' do
      let(:allowed) { true }

      it 'keeps the protected metric and receives the user with all resources' do
        response = engine.execute(build_request(metrics: [{ identifier: :owner_count }]))

        expect(response).to be_success
        expect(response.payload[:data].metrics.map(&:identifier)).to contain_exactly(:owner_count)
        expect(received_arguments).to contain_exactly([user, [resource, other_resource]])
      end
    end

    context 'when the callable denies access' do
      let(:allowed) { false }

      it 'drops the protected metric' do
        response = engine.execute(build_request(
          metrics: [{ identifier: :total_count }, { identifier: :owner_count }]))

        expect(response).to be_success
        expect(response.payload[:data].metrics.map(&:identifier)).to contain_exactly(:total_count)
      end
    end
  end
end
