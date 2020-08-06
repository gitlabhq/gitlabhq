# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Validator do
  include MetricsDashboardHelpers

  let_it_be(:valid_dashboard) { load_sample_dashboard }
  let_it_be(:invalid_dashboard) { load_dashboard_yaml(fixture_file('lib/gitlab/metrics/dashboard/invalid_dashboard.yml')) }
  let_it_be(:duplicate_id_dashboard) { load_dashboard_yaml(fixture_file('lib/gitlab/metrics/dashboard/duplicate_id_dashboard.yml')) }

  describe '#validate' do
    context 'valid dashboard' do
      it 'returns true' do
        expect(described_class.validate(valid_dashboard)).to be true
      end
    end

    context 'invalid dashboard' do
      context 'invalid schema' do
        it 'returns false' do
          expect(described_class.validate(invalid_dashboard)).to be false
        end
      end

      context 'duplicate metric ids' do
        context 'with no project given' do
          it 'checks against given dashboard and returns false' do
            expect(described_class.validate(duplicate_id_dashboard)).to be false
          end
        end
      end
    end
  end

  describe '#validate!' do
    context 'valid dashboard' do
      it 'returns true' do
        expect(described_class.validate!(valid_dashboard)).to be true
      end
    end

    context 'invalid dashboard' do
      context 'invalid schema' do
        it 'raises error' do
          expect { described_class.validate!(invalid_dashboard) }
            .to raise_error(Gitlab::Metrics::Dashboard::Validator::Errors::InvalidDashboardError,
              "'this_should_be_a_int' is invalid at '/panel_groups/0/panels/0/weight'."\
              " Should be '{\"type\"=>\"number\"}' due to schema definition at '/properties/weight'")
        end
      end

      context 'duplicate metric ids' do
        context 'with no project given' do
          it 'checks against given dashboard and returns false' do
            expect { described_class.validate!(duplicate_id_dashboard) }
              .to raise_error(Gitlab::Metrics::Dashboard::Validator::Errors::InvalidDashboardError,
                "metric_id must be unique across a project")
          end
        end
      end
    end
  end
end
