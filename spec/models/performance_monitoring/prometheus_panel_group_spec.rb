# frozen_string_literal: true

require 'spec_helper'

describe PerformanceMonitoring::PrometheusPanelGroup do
  let(:json_content) do
    {
      "group" => "Group Title",
      "panels" => [{
        "type" => "area-chart",
        "title" => "Chart Title",
        "y_label" => "Y-Axis",
        "metrics" => [{
          "id" => "metric_of_ages",
          "unit" => "count",
          "label" => "Metric of Ages",
          "query_range" => "http_requests_total"
        }]
      }]
    }
  end

  describe '.from_json' do
    subject { described_class.from_json(json_content) }

    it 'creates a PrometheusPanelGroup object' do
      expect(subject).to be_a PerformanceMonitoring::PrometheusPanelGroup
      expect(subject.group).to eq(json_content['group'])
      expect(subject.panels).to all(be_a PerformanceMonitoring::PrometheusPanel)
    end

    describe 'validations' do
      context 'when group is missing' do
        before do
          json_content.delete('group')
        end

        subject { described_class.from_json(json_content) }

        it { expect { subject }.to raise_error(ActiveModel::ValidationError) }
      end

      context 'when panels are missing' do
        before do
          json_content['panels'] = []
        end

        subject { described_class.from_json(json_content) }

        it { expect { subject }.to raise_error(ActiveModel::ValidationError) }
      end
    end
  end
end
