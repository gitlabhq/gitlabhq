# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../scripts/internal_events/cli'

RSpec.describe InternalEventsCli::NewMetric, :aggregate_failures, feature_category: :service_ping do
  let(:time_frame) { ['7d'] }
  let(:identifier) { 'user' }
  let(:actions) { ['action_1'] }
  let(:filters) { nil }
  let(:operator) { 'unique_count' }
  let(:data_source) { 'internal_events' }

  subject(:metric) do
    described_class.new(
      time_frame: time_frame,
      identifier: identifier,
      actions: actions,
      filters: filters,
      operator: operator,
      data_source: data_source
    )
  end

  it 'has expected description content' do
    expect(metric.description_prefix).to eq('Weekly count of unique users')
    expect(metric.technical_description).to eq('Weekly count of unique users who triggered action_1')
  end

  context 'when filtered' do
    let(:filters) { [] }

    it 'has expected description content' do
      expect(metric.description_prefix).to eq('Weekly count of unique users')
      expect(metric.technical_description).to eq('Weekly count of unique users who triggered the selected events')
    end
  end

  context 'when all time' do
    let(:time_frame) { ['all'] }

    it 'has expected description content' do
      expect(metric.description_prefix).to eq('Total count of unique users')
      expect(metric.technical_description).to eq('Total count of unique users who triggered action_1')
    end
  end

  context 'with multiple events' do
    let(:actions) { %w[action_1 action_2] }

    it 'has expected description content' do
      expect(metric.description_prefix).to eq('Weekly count of unique users')
      expect(metric.technical_description).to eq('Weekly count of unique users who triggered the selected events')
    end
  end

  context 'when unique by default identifier' do
    let(:identifier) { 'project' }

    it 'has expected description content' do
      expect(metric.description_prefix).to eq('Weekly count of unique projects')
      expect(metric.technical_description).to eq('Weekly count of unique projects where action_1 occurred')
    end

    context 'when filtered' do
      let(:filters) { [] }

      it 'has expected description content' do
        expect(metric.description_prefix).to eq('Weekly count of unique projects')
        expect(metric.technical_description).to eq('Weekly count of unique projects where the selected events occurred')
      end
    end
  end

  context 'when unique by additional property' do
    let(:identifier) { 'label' }

    it 'has expected description content' do
      expect(metric.description_prefix).to eq('Weekly count of unique')
      expect(metric.technical_description).to eq("Weekly count of unique values for 'label' from action_1 occurrences")
    end

    context "when sum by value" do
      let(:identifier) { 'value' }
      let(:operator) { 'sum' }

      it 'has expected description content' do
        expect(metric.description_prefix).to eq('Weekly sum of all')
        expect(metric.technical_description).to eq("Weekly sum of all values for 'value' from action_1 occurrences")
      end
    end

    context 'when filtered' do
      let(:filters) { [] }

      it 'has expected description content' do
        expect(metric.description_prefix).to eq('Weekly count of unique')
        expect(metric.technical_description).to eq(
          "Weekly count of unique values for 'label' from the selected events occurrences"
        )
      end

      context "when sum by value" do
        let(:identifier) { 'value' }
        let(:operator) { 'sum' }

        it 'has expected description content' do
          expect(metric.description_prefix).to eq('Weekly sum of all')
          expect(metric.technical_description).to eq(
            "Weekly sum of all values for 'value' from the selected events occurrences"
          )
        end
      end
    end
  end

  context "with database metrics" do
    let(:data_source) { 'database' }

    it 'has expected description content' do
      expect(metric.description_prefix).to eq('Weekly')
      expect(metric.technical_description).to eq('Weekly')
    end

    context "with non-singular time frame" do
      let(:time_frame) { %w[7d all] }

      it 'has expected description content' do
        expect(metric.description_prefix).to eq('')
        expect(metric.technical_description).to eq('')
      end
    end
  end
end

RSpec.describe InternalEventsCli::Metric::Identifier, :aggregate_failures, feature_category: :service_ping do
  subject(:identifier) { described_class.new(value) }

  let(:operator) { InternalEventsCli::Metric::Operator.new('unique_count') }

  context 'with no value' do
    let(:value) { nil }
    let(:operator) { InternalEventsCli::Metric::Operator.new('count') }

    it 'has expected components' do
      expect(identifier.value).to eq(nil)
      expect(identifier.description).to eq('%s occurrences')
      expect(identifier.key_path(operator)).to eq('total')
    end
  end

  context 'when value is user' do
    let(:value) { 'user' }

    it 'has expected components' do
      expect(identifier.value).to eq('user')
      expect(identifier.description).to eq('users who triggered %s')
      expect(identifier.key_path(operator)).to eq('distinct_user_id_from')
    end
  end

  context 'when value is an identifier' do
    let(:value) { 'namespace' }

    it 'has expected components' do
      expect(identifier.value).to eq('namespace')
      expect(identifier.description).to eq('namespaces where %s occurred')
      expect(identifier.key_path(operator)).to eq('distinct_namespace_id_from')
    end
  end

  context 'when value is an additional property' do
    let(:value) { 'label' }

    it 'has expected components' do
      expect(identifier.value).to eq('label')
      expect(identifier.description).to eq("values for 'label' from %s occurrences")
      expect(identifier.key_path(operator)).to eq('distinct_label_from')
    end
  end

  context 'when summing value' do
    let(:operator) { InternalEventsCli::Metric::Operator.new('sum') }
    let(:value) { 'value' }

    it 'has expected components' do
      expect(identifier.value).to eq('value')
      expect(identifier.description).to eq("values for 'value' from %s occurrences")
      expect(identifier.key_path(operator)).to eq('value_from')
    end
  end
end
