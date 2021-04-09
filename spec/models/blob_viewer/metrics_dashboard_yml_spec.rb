# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BlobViewer::MetricsDashboardYml do
  include FakeBlobHelpers
  include RepoHelpers

  let_it_be(:project) { create(:project, :repository) }

  let(:blob) { fake_blob(path: '.gitlab/dashboards/custom-dashboard.yml', data: data) }
  let(:sha) { sample_commit.id }
  let(:data) { fixture_file('lib/gitlab/metrics/dashboard/sample_dashboard.yml') }

  subject(:viewer) { described_class.new(blob) }

  context 'with metrics_dashboard_exhaustive_validations feature flag on' do
    before do
      stub_feature_flags(metrics_dashboard_exhaustive_validations: true)
    end

    context 'when the definition is valid' do
      before do
        allow(Gitlab::Metrics::Dashboard::Validator).to receive(:errors).and_return([])
      end

      describe '#valid?' do
        it 'calls prepare! on the viewer' do
          expect(viewer).to receive(:prepare!)

          viewer.valid?
        end

        it 'processes dashboard yaml and returns true', :aggregate_failures do
          yml = ::Gitlab::Config::Loader::Yaml.new(data).load_raw!

          expect_next_instance_of(::Gitlab::Config::Loader::Yaml, data) do |loader|
            expect(loader).to receive(:load_raw!).and_call_original
          end
          expect(Gitlab::Metrics::Dashboard::Validator)
            .to receive(:errors)
            .with(yml, dashboard_path: '.gitlab/dashboards/custom-dashboard.yml', project: project)
            .and_call_original
          expect(viewer.valid?).to be true
        end
      end

      describe '#errors' do
        it 'returns empty array' do
          expect(viewer.errors).to eq []
        end
      end
    end

    context 'when definition is invalid' do
      let(:error) { ::Gitlab::Metrics::Dashboard::Validator::Errors::SchemaValidationError.new }
      let(:data) do
        <<~YAML
          dashboard:
        YAML
      end

      before do
        allow(Gitlab::Metrics::Dashboard::Validator).to receive(:errors).and_return([error])
      end

      describe '#valid?' do
        it 'returns false' do
          expect(viewer.valid?).to be false
        end
      end

      describe '#errors' do
        it 'returns validation errors' do
          expect(viewer.errors).to eq ["Dashboard failed schema validation"]
        end
      end
    end

    context 'when YAML syntax is invalid' do
      let(:data) do
        <<~YAML
          dashboard: 'empty metrics'
           panel_groups:
          - group: 'Group Title'
        YAML
      end

      describe '#valid?' do
        it 'returns false' do
          expect(Gitlab::Metrics::Dashboard::Validator).not_to receive(:errors)
          expect(viewer.valid?).to be false
        end
      end

      describe '#errors' do
        it 'returns validation errors' do
          expect(viewer.errors).to all be_kind_of String
        end
      end
    end

    context 'when YAML loader raises error' do
      let(:data) do
        <<~YAML
          large yaml file
        YAML
      end

      before do
        allow(::Gitlab::Config::Loader::Yaml).to receive(:new)
          .and_raise(::Gitlab::Config::Loader::Yaml::DataTooLargeError, 'The parsed YAML is too big')
      end

      it 'is invalid' do
        expect(Gitlab::Metrics::Dashboard::Validator).not_to receive(:errors)
        expect(viewer.valid?).to be false
      end

      it 'returns validation errors' do
        expect(viewer.errors).to eq ['The parsed YAML is too big']
      end
    end
  end

  context 'with metrics_dashboard_exhaustive_validations feature flag off' do
    before do
      stub_feature_flags(metrics_dashboard_exhaustive_validations: false)
    end

    context 'when the definition is valid' do
      describe '#valid?' do
        before do
          allow(PerformanceMonitoring::PrometheusDashboard).to receive(:from_json)
        end

        it 'calls prepare! on the viewer' do
          expect(viewer).to receive(:prepare!)

          viewer.valid?
        end

        it 'processes dashboard yaml and returns true', :aggregate_failures do
          yml = ::Gitlab::Config::Loader::Yaml.new(data).load_raw!

          expect_next_instance_of(::Gitlab::Config::Loader::Yaml, data) do |loader|
            expect(loader).to receive(:load_raw!).and_call_original
          end
          expect(PerformanceMonitoring::PrometheusDashboard)
            .to receive(:from_json)
                  .with(yml)
                  .and_call_original
          expect(viewer.valid?).to be true
        end
      end

      describe '#errors' do
        it 'returns empty array' do
          expect(viewer.errors).to eq []
        end
      end
    end

    context 'when definition is invalid' do
      let(:error) { ActiveModel::ValidationError.new(PerformanceMonitoring::PrometheusDashboard.new.tap(&:validate)) }
      let(:data) do
        <<~YAML
        dashboard:
        YAML
      end

      describe '#valid?' do
        it 'returns false' do
          expect(PerformanceMonitoring::PrometheusDashboard)
            .to receive(:from_json).and_raise(error)

          expect(viewer.valid?).to be false
        end
      end

      describe '#errors' do
        it 'returns validation errors' do
          allow(PerformanceMonitoring::PrometheusDashboard)
            .to receive(:from_json).and_raise(error)

          expect(viewer.errors).to eq error.model.errors.messages.map { |messages| messages.join(': ') }
        end
      end
    end

    context 'when YAML syntax is invalid' do
      let(:data) do
        <<~YAML
        dashboard: 'empty metrics'
         panel_groups:
        - group: 'Group Title'
        YAML
      end

      describe '#valid?' do
        it 'returns false' do
          expect(PerformanceMonitoring::PrometheusDashboard).not_to receive(:from_json)
          expect(viewer.valid?).to be false
        end
      end

      describe '#errors' do
        it 'returns validation errors' do
          expect(viewer.errors).to eq ["YAML syntax: (<unknown>): did not find expected key while parsing a block mapping at line 1 column 1"]
        end
      end
    end

    context 'when YAML loader raises error' do
      let(:data) do
        <<~YAML
        large yaml file
        YAML
      end

      before do
        allow(::Gitlab::Config::Loader::Yaml).to(
          receive(:new).and_raise(::Gitlab::Config::Loader::Yaml::DataTooLargeError, 'The parsed YAML is too big')
        )
      end

      it 'is invalid' do
        expect(PerformanceMonitoring::PrometheusDashboard).not_to receive(:from_json)
        expect(viewer.valid?).to be false
      end

      it 'returns validation errors' do
        expect(viewer.errors).to eq ["YAML syntax: The parsed YAML is too big"]
      end
    end
  end
end
