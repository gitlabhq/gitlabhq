# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Validator::Client do
  include MetricsDashboardHelpers

  let_it_be(:schema_path) { 'lib/gitlab/metrics/dashboard/validator/schemas/dashboard.json' }

  subject { described_class.new(dashboard, schema_path) }

  describe '#execute' do
    context 'with no validation errors' do
      let(:dashboard) { load_sample_dashboard }

      it 'returns empty array' do
        expect(subject.execute).to eq([])
      end
    end

    context 'with validation errors' do
      let(:dashboard) { load_dashboard_yaml(fixture_file('lib/gitlab/metrics/dashboard/invalid_dashboard.yml')) }

      it 'returns array of error objects' do
        expect(subject.execute).to include(Gitlab::Metrics::Dashboard::Validator::Errors::SchemaValidationError)
      end
    end
  end
end
