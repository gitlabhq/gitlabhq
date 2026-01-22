# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::Graphql::Mounter, feature_category: :database do
  let(:test_class) do
    Class.new do
      include Gitlab::Database::Aggregation::Graphql::Mounter

      attr_reader :fields

      def initialize
        @fields = []
      end

      def field(name, **options, &block)
        @fields << { name: name, options: options, block: block }
      end
    end
  end

  let(:parent_field) { test_class.new }

  describe '#mount_aggregation_engine' do
    let(:engine_class) do
      Class.new(Gitlab::Database::Aggregation::Engine)
    end

    it 'mounts the aggregation engine as a field' do
      expected_resolver_options = {
        field_name: :aggregation,
        types_prefix: :aggregation,
        description: 'test_desc'
      }
      block = proc {}
      expect(Resolvers::Analytics::Aggregation::EngineResolver)
        .to receive(:build).with(engine_class, **expected_resolver_options, &block).and_return('resolver mock')
      parent_field.mount_aggregation_engine(engine_class, description: 'test_desc', &block)

      expect(parent_field.fields.size).to eq(1)
      field = parent_field.fields.first

      expect(field[:name]).to eq(:aggregation)
      expect(field[:options]).to eq({
        description: 'test_desc',
        null: true,
        resolver_method: :object,
        resolver: 'resolver mock'
      })
    end

    it 'supoorts names customization' do
      mount_options = {
        field_name: :mr_engine,
        types_prefix: :merge_requests,
        description: 'test_desc'
      }
      block = proc {}
      expect(Resolvers::Analytics::Aggregation::EngineResolver)
        .to receive(:build).with(engine_class, **mount_options, &block).and_return('resolver mock')
      parent_field.mount_aggregation_engine(engine_class, **mount_options, &block)

      expect(parent_field.fields.size).to eq(1)
      field = parent_field.fields.first

      expect(field[:name]).to eq(mount_options[:field_name])
      expect(field[:options]).to eq({
        description: 'test_desc',
        null: true,
        resolver_method: :object,
        resolver: 'resolver mock'
      })
    end
  end
end
