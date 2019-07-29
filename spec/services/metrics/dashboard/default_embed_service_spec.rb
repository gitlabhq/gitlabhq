# frozen_string_literal: true

require 'spec_helper'

describe Metrics::Dashboard::DefaultEmbedService, :use_clean_rails_memory_store_caching do
  include MetricsDashboardHelpers

  set(:project) { build(:project) }
  set(:user) { create(:user) }
  set(:environment) { create(:environment, project: project) }

  before do
    project.add_maintainer(user)
  end

  describe '#get_dashboard' do
    let(:service_params) { [project, user, { environment: environment, dashboard_path: nil }] }
    let(:service_call) { described_class.new(*service_params).get_dashboard }

    it_behaves_like 'valid embedded dashboard service response'
    it_behaves_like 'raises error for users with insufficient permissions'

    it 'caches the unprocessed dashboard for subsequent calls' do
      expect(YAML).to receive(:safe_load).once.and_call_original

      described_class.new(*service_params).get_dashboard
      described_class.new(*service_params).get_dashboard
    end

    context 'when called with a non-system dashboard' do
      let(:dashboard_path) { 'garbage/dashboard/path' }

      it_behaves_like 'valid embedded dashboard service response'
    end
  end
end
