# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Validator do
  include MetricsDashboardHelpers

  let_it_be(:valid_dashboard) { load_sample_dashboard }
  let_it_be(:invalid_dashboard) { load_dashboard_yaml(fixture_file('lib/gitlab/metrics/dashboard/invalid_dashboard.yml')) }
  let_it_be(:duplicate_id_dashboard) { load_dashboard_yaml(fixture_file('lib/gitlab/metrics/dashboard/duplicate_id_dashboard.yml')) }

  let_it_be(:project) { create(:project) }

  describe '#validate' do
    context 'valid dashboard schema' do
      it 'returns true' do
        expect(described_class.validate(valid_dashboard)).to be true
      end

      context 'with duplicate metric_ids' do
        it 'returns false' do
          expect(described_class.validate(duplicate_id_dashboard)).to be false
        end
      end

      context 'with dashboard_path and project' do
        subject { described_class.validate(valid_dashboard, dashboard_path: 'test/path.yml', project: project) }

        context 'with no conflicting metric identifiers in db' do
          it { is_expected.to be true }
        end

        context 'with metric identifier present in current dashboard' do
          before do
            create(:prometheus_metric,
              identifier:     'metric_a1',
              dashboard_path: 'test/path.yml',
              project:        project
            )
          end

          it { is_expected.to be true }
        end

        context 'with metric identifier present in another dashboard' do
          before do
            create(:prometheus_metric,
              identifier:     'metric_a1',
              dashboard_path: 'some/other/dashboard/path.yml',
              project:        project
            )
          end

          it { is_expected.to be false }
        end
      end
    end

    context 'invalid dashboard schema' do
      it 'returns false' do
        expect(described_class.validate(invalid_dashboard)).to be false
      end
    end
  end

  describe '#validate!' do
    shared_examples 'validation failed' do |errors_message|
      it 'raises error with corresponding messages', :aggregate_failures do
        expect { subject }.to raise_error do |error|
          expect(error).to be_kind_of(Gitlab::Metrics::Dashboard::Validator::Errors::InvalidDashboardError)
          expect(error.message).to eq(errors_message)
        end
      end
    end

    context 'valid dashboard schema' do
      it 'returns true' do
        expect(described_class.validate!(valid_dashboard)).to be true
      end

      context 'with duplicate metric_ids' do
        subject { described_class.validate!(duplicate_id_dashboard) }

        it_behaves_like 'validation failed', 'metric_id must be unique across a project'
      end

      context 'with dashboard_path and project' do
        subject { described_class.validate!(valid_dashboard, dashboard_path: 'test/path.yml', project: project) }

        context 'with no conflicting metric identifiers in db' do
          it { is_expected.to be true }
        end

        context 'with metric identifier present in current dashboard' do
          before do
            create(:prometheus_metric,
              identifier:     'metric_a1',
              dashboard_path: 'test/path.yml',
              project:        project
            )
          end

          it { is_expected.to be true }
        end

        context 'with metric identifier present in another dashboard' do
          before do
            create(:prometheus_metric,
              identifier:     'metric_a1',
              dashboard_path: 'some/other/dashboard/path.yml',
              project:        project
            )
          end

          it_behaves_like 'validation failed', 'metric_id must be unique across a project'
        end
      end
    end

    context 'invalid dashboard schema' do
      subject { described_class.validate!(invalid_dashboard) }

      context 'wrong property type' do
        it_behaves_like 'validation failed', "'this_should_be_a_int' at /panel_groups/0/panels/0/weight is not of type: number"
      end

      context 'panel groups missing' do
        let_it_be(:invalid_dashboard) { load_dashboard_yaml(fixture_file('lib/gitlab/metrics/dashboard/dashboard_missing_panel_groups.yml')) }

        it_behaves_like 'validation failed', 'root is missing required keys: panel_groups'
      end

      context 'groups are missing panels and group keys' do
        let_it_be(:invalid_dashboard) { load_dashboard_yaml(fixture_file('lib/gitlab/metrics/dashboard/dashboard_groups_missing_panels_and_group.yml')) }

        it_behaves_like 'validation failed', '/panel_groups/0 is missing required keys: group'
      end

      context 'panel is missing metrics key' do
        let_it_be(:invalid_dashboard) { load_dashboard_yaml(fixture_file('lib/gitlab/metrics/dashboard/dashboard_panel_is_missing_metrics.yml')) }

        it_behaves_like 'validation failed', '/panel_groups/0/panels/0 is missing required keys: metrics'
      end
    end
  end

  describe '#errors' do
    context 'valid dashboard schema' do
      it 'returns no errors' do
        expect(described_class.errors(valid_dashboard)).to eq []
      end

      context 'with duplicate metric_ids' do
        it 'returns errors' do
          expect(described_class.errors(duplicate_id_dashboard)).to eq [Gitlab::Metrics::Dashboard::Validator::Errors::DuplicateMetricIds.new]
        end
      end

      context 'with dashboard_path and project' do
        subject { described_class.errors(valid_dashboard, dashboard_path: 'test/path.yml', project: project) }

        context 'with no conflicting metric identifiers in db' do
          it { is_expected.to eq [] }
        end

        context 'with metric identifier present in current dashboard' do
          before do
            create(:prometheus_metric,
                   identifier:     'metric_a1',
                   dashboard_path: 'test/path.yml',
                   project:        project
                  )
          end

          it { is_expected.to eq [] }
        end

        context 'with metric identifier present in another dashboard' do
          before do
            create(:prometheus_metric,
                   identifier:     'metric_a1',
                   dashboard_path: 'some/other/dashboard/path.yml',
                   project:        project
                  )
          end

          it { is_expected.to eq [Gitlab::Metrics::Dashboard::Validator::Errors::DuplicateMetricIds.new] }
        end
      end
    end

    context 'invalid dashboard schema' do
      it 'returns collection of validation errors' do
        expect(described_class.errors(invalid_dashboard)).to all be_kind_of(Gitlab::Metrics::Dashboard::Validator::Errors::SchemaValidationError)
      end
    end
  end
end
