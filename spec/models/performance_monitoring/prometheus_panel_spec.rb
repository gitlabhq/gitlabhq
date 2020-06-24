# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PerformanceMonitoring::PrometheusPanel do
  let(:json_content) do
    {
      "max_value" => 1,
      "type" => "area-chart",
      "title" => "Chart Title",
      "y_label" => "Y-Axis",
      "weight" => 1,
      "metrics" => [{
        "id" => "metric_of_ages",
        "unit" => "count",
        "label" => "Metric of Ages",
        "query_range" => "http_requests_total"
      }]
    }
  end

  describe '#new' do
    it 'accepts old schema format' do
      expect { described_class.new(json_content) }.not_to raise_error
    end

    it 'accepts new schema format' do
      expect { described_class.new(json_content.merge("y_axis" => { "precision" => 0 })) }.not_to raise_error
    end
  end

  describe '.from_json' do
    subject { described_class.from_json(json_content) }

    it 'creates a PrometheusPanelGroup object' do
      expect(subject).to be_a PerformanceMonitoring::PrometheusPanel
      expect(subject.type).to eq(json_content['type'])
      expect(subject.title).to eq(json_content['title'])
      expect(subject.y_label).to eq(json_content['y_label'])
      expect(subject.weight).to eq(json_content['weight'])
      expect(subject.metrics).to all(be_a PerformanceMonitoring::PrometheusMetric)
    end

    describe 'validations' do
      context 'json_content is not a hash' do
        let(:json_content) { nil }

        subject { described_class.from_json(json_content) }

        it { expect { subject }.to raise_error(ActiveModel::ValidationError) }
      end

      context 'when title is missing' do
        before do
          json_content['title'] = nil
        end

        subject { described_class.from_json(json_content) }

        it { expect { subject }.to raise_error(ActiveModel::ValidationError) }
      end

      context 'when metrics are missing' do
        before do
          json_content.delete('metrics')
        end

        subject { described_class.from_json(json_content) }

        it { expect { subject }.to raise_error(ActiveModel::ValidationError) }
      end
    end
  end

  describe '.id' do
    it 'returns hexdigest of group_title, type and title as the panel id' do
      group_title = 'Business Group'
      panel_type  = 'area-chart'
      panel_title = 'New feature requests made'

      expect(Digest::SHA2).to receive(:hexdigest).with("#{group_title}#{panel_type}#{panel_title}").and_return('hexdigest')
      expect(described_class.new(title: panel_title, type: panel_type).id(group_title)).to eql 'hexdigest'
    end
  end
end
