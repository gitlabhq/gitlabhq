# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::MetricsDashboard::Service, :use_clean_rails_memory_store_caching do
  let(:project) { build(:project) }

  describe 'get_dashboard' do
    it 'returns a json representation of the environment dashboard' do
      result = described_class.new(project).get_dashboard

      expect(result.keys).to contain_exactly(:dashboard, :status)
      expect(result[:status]).to eq(:success)

      expect(result[:dashboard]).to include('dashboard', 'order', 'panel_groups')
      expect(result[:dashboard]['panel_groups']).to all( include('group', 'priority', 'panels') )
    end

    it 'caches the dashboard for subsequent calls' do
      expect(YAML).to receive(:load_file).once.and_call_original

      described_class.new(project).get_dashboard
      described_class.new(project).get_dashboard
    end
  end
end
