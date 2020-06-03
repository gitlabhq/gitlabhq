# frozen_string_literal: true

require 'spec_helper'

describe PerformanceMonitoring::PrometheusDashboard do
  let(:json_content) do
    {
      "dashboard" => "Dashboard Title",
      "templating" => {
        "variables" => {
          "variable1" => %w(value1 value2 value3)
        }
      },
      "panel_groups" => [{
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
      }]
    }
  end

  describe '.from_json' do
    subject { described_class.from_json(json_content) }

    it 'creates a PrometheusDashboard object' do
      expect(subject).to be_a PerformanceMonitoring::PrometheusDashboard
      expect(subject.dashboard).to eq(json_content['dashboard'])
      expect(subject.panel_groups).to all(be_a PerformanceMonitoring::PrometheusPanelGroup)
    end

    describe 'validations' do
      shared_examples 'validation failed' do |errors_messages|
        it 'raises error with corresponding messages', :aggregate_failures do
          expect { subject }.to raise_error do |error|
            expect(error).to be_kind_of(ActiveModel::ValidationError)
            expect(error.model.errors.messages).to eql(errors_messages)
          end
        end
      end

      context 'dashboard definition is missing panels_groups and dashboard keys' do
        let(:json_content) do
          {
            "dashboard" => nil
          }
        end

        it_behaves_like 'validation failed', panel_groups: ["can't be blank"], dashboard: ["can't be blank"]
      end

      context 'group definition is missing panels and group keys' do
        let(:json_content) do
          {
            "dashboard" => "Dashboard Title",
            "templating" => {
              "variables" => {
                "variable1" => %w(value1 value2 value3)
              }
            },
            "panel_groups" => [{ "group" => nil }]
          }
        end

        it_behaves_like 'validation failed', panels: ["can't be blank"], group: ["can't be blank"]
      end

      context 'panel definition is missing metrics and title keys' do
        let(:json_content) do
          {
            "dashboard" => "Dashboard Title",
            "templating" => {
              "variables" => {
                "variable1" => %w(value1 value2 value3)
              }
            },
            "panel_groups" => [{
              "group" => "Group Title",
              "panels" => [{
                "type" => "area-chart",
                "y_label" => "Y-Axis"
              }]
            }]
          }
        end

        it_behaves_like 'validation failed', metrics: ["can't be blank"], title: ["can't be blank"]
      end

      context 'metrics definition is missing unit, query and query_range keys' do
        let(:json_content) do
          {
            "dashboard" => "Dashboard Title",
            "templating" => {
              "variables" => {
                "variable1" => %w(value1 value2 value3)
              }
            },
            "panel_groups" => [{
              "group" => "Group Title",
              "panels" => [{
                "type" => "area-chart",
                "title" => "Chart Title",
                "y_label" => "Y-Axis",
                "metrics" => [{
                  "id" => "metric_of_ages",
                  "label" => "Metric of Ages",
                  "query_range" => nil
                }]
              }]
            }]
          }
        end

        it_behaves_like 'validation failed', unit: ["can't be blank"], query_range: ["can't be blank"], query: ["can't be blank"]
      end

      # for each parent entry validation first is done to its children,
      # whole execution is stopped on first encountered error
      # which is the one that is reported
      context 'multiple offences on different levels' do
        let(:json_content) do
          {
            "dashboard" => nil,
            "panel_groups" => [{
              "group" => nil,
              "panels" => [{
                "type" => "area-chart",
                "title" => nil,
                "y_label" => "Y-Axis",
                "metrics" => [{
                  "id" => "metric_of_ages",
                  "label" => "Metric of Ages",
                  "query_range" => 'query'
                }, {
                  "id" => "metric_of_ages",
                  "unit" => "count",
                  "label" => "Metric of Ages",
                  "query_range" => nil
                }]
              }]
            }, {
              "group" => 'group',
              "panels" => nil
            }]
          }
        end

        it_behaves_like 'validation failed', unit: ["can't be blank"]
      end
    end
  end

  describe '.find_for' do
    let(:project) { build_stubbed(:project) }
    let(:user) { build_stubbed(:user) }
    let(:environment) { build_stubbed(:environment) }
    let(:path) { ::Metrics::Dashboard::SystemDashboardService::DASHBOARD_PATH }

    context 'dashboard has been found' do
      it 'uses dashboard finder to find and load dashboard data and returns dashboard instance', :aggregate_failures do
        expect(Gitlab::Metrics::Dashboard::Finder).to receive(:find).with(project, user, environment: environment, dashboard_path: path).and_return(status: :success, dashboard: json_content)

        dashboard_instance = described_class.find_for(project: project, user: user, path: path, options: { environment: environment })

        expect(dashboard_instance).to be_instance_of described_class
        expect(dashboard_instance.environment).to be environment
        expect(dashboard_instance.path).to be path
      end
    end

    context 'dashboard has NOT been found' do
      it 'returns nil' do
        allow(Gitlab::Metrics::Dashboard::Finder).to receive(:find).and_return(status: :error)

        dashboard_instance = described_class.find_for(project: project, user: user, path: path, options: { environment: environment })

        expect(dashboard_instance).to be_nil
      end
    end
  end

  describe '#to_yaml' do
    subject { prometheus_dashboard.to_yaml }

    let(:prometheus_dashboard) { described_class.from_json(json_content) }
    let(:expected_yaml) do
      "---\npanel_groups:\n- panels:\n  - metrics:\n    - id: metric_of_ages\n      unit: count\n      label: Metric of Ages\n      query: \n      query_range: http_requests_total\n    type: area-chart\n    title: Chart Title\n    y_label: Y-Axis\n    weight: \n  group: Group Title\n  priority: \ndashboard: Dashboard Title\n"
    end

    it { is_expected.to eq(expected_yaml) }
  end
end
