# frozen_string_literal: true

require 'fast_spec_helper'

require_relative '../../../../scripts/internal_events/cli'

RSpec.describe InternalEventsCli::NewMetric, :aggregate_failures, feature_category: :service_ping do
  let(:time_frame) { '7d' }
  let(:identifier) { 'user' }
  let(:actions) { ['action_1'] }
  let(:filters) { nil }

  subject(:metric) do
    described_class.new(
      time_frame: time_frame,
      identifier: identifier,
      actions: actions,
      filters: filters
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
    let(:time_frame) { 'all' }

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

    context 'when filtered' do
      let(:filters) { [] }

      it 'has expected description content' do
        expect(metric.description_prefix).to eq('Weekly count of unique')
        expect(metric.technical_description).to eq(
          "Weekly count of unique values for 'label' from the selected events occurrences"
        )
      end
    end
  end
end

RSpec.describe InternalEventsCli::Metric::Identifier, :aggregate_failures, feature_category: :service_ping do
  subject(:identifier) { described_class.new(value) }

  context 'with no value' do
    let(:value) { nil }

    it 'has expected components' do
      expect(identifier.value).to eq(nil)
      expect(identifier.description).to eq('count of %s occurrences')
      expect(identifier.key_path).to eq('total')
    end
  end

  context 'when value is user' do
    let(:value) { 'user' }

    it 'has expected components' do
      expect(identifier.value).to eq('user')
      expect(identifier.description).to eq('count of unique users who triggered %s')
      expect(identifier.key_path).to eq('distinct_user_id_from')
    end
  end

  context 'when value is an identifier' do
    let(:value) { 'namespace' }

    it 'has expected components' do
      expect(identifier.value).to eq('namespace')
      expect(identifier.description).to eq('count of unique namespaces where %s occurred')
      expect(identifier.key_path).to eq('distinct_namespace_id_from')
    end
  end

  context 'when value is an additional property' do
    let(:value) { 'label' }

    it 'has expected components' do
      expect(identifier.value).to eq('label')
      expect(identifier.description).to eq("count of unique values for 'label' from %s occurrences")
      expect(identifier.key_path).to eq('distinct_label_from')
    end
  end
end
