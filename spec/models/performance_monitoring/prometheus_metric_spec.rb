# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PerformanceMonitoring::PrometheusMetric do
  let(:json_content) do
    {
      "id" => "metric_of_ages",
      "unit" => "count",
      "label" => "Metric of Ages",
      "query_range" => "http_requests_total"
    }
  end

  describe '.from_json' do
    subject { described_class.from_json(json_content) }

    it 'creates a PrometheusMetric object' do
      expect(subject).to be_a PerformanceMonitoring::PrometheusMetric
      expect(subject.id).to eq(json_content['id'])
      expect(subject.unit).to eq(json_content['unit'])
      expect(subject.label).to eq(json_content['label'])
      expect(subject.query_range).to eq(json_content['query_range'])
    end

    describe 'validations' do
      context 'json_content is not a hash' do
        let(:json_content) { nil }

        subject { described_class.from_json(json_content) }

        it { expect { subject }.to raise_error(ActiveModel::ValidationError) }
      end

      context 'when unit is missing' do
        before do
          json_content['unit'] = nil
        end

        subject { described_class.from_json(json_content) }

        it { expect { subject }.to raise_error(ActiveModel::ValidationError) }
      end

      context 'when query and query_range is missing' do
        before do
          json_content['query_range'] = nil
        end

        subject { described_class.from_json(json_content) }

        it { expect { subject }.to raise_error(ActiveModel::ValidationError) }
      end

      context 'when query_range is missing but query is available' do
        before do
          json_content['query_range'] = nil
          json_content['query'] = 'http_requests_total'
        end

        subject { described_class.from_json(json_content) }

        it { is_expected.to be_valid }
      end
    end
  end
end
