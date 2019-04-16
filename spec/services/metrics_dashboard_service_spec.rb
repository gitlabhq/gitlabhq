require 'spec_helper'

describe MetricsDashboardService, :use_clean_rails_memory_store_caching do
  let(:project) { build(:project) }

  describe 'get_dashboard' do
    it 'returns a json representation of the environment dashboard' do
      dashboard = described_class.new(project).get_dashboard
      json = JSON.parse(dashboard, symbolize_names: true)

      expect(json).to include(:dashboard, :order, :panel_groups)
      expect(json[:panel_groups]).to all( include(:group, :priority, :panels) )
    end

    it 'caches the dashboard for subsequent calls' do
      expect(YAML).to receive(:load_file).once.and_call_original

      described_class.new(project).get_dashboard
      described_class.new(project).get_dashboard
    end
  end
end
