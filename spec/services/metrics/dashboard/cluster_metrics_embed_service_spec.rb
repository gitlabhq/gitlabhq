# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::Dashboard::ClusterMetricsEmbedService, :use_clean_rails_memory_store_caching do
  include MetricsDashboardHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:cluster_project) { create(:cluster_project) }
  let_it_be(:cluster) { cluster_project.cluster }
  let_it_be(:project) { cluster_project.project }

  before do
    project.add_maintainer(user)
  end

  describe '.valid_params?' do
    let(:valid_params) { { cluster: 1, embedded: 'true', group: 'hello', title: 'world', y_label: 'countries' } }

    subject { described_class }

    it { expect(subject.valid_params?(valid_params)).to be_truthy }

    context 'missing all params' do
      let(:params) { {} }

      it { expect(subject.valid_params?(params)).to be_falsy }
    end

    [:cluster, :embedded, :group, :title, :y_label].each do |param_key|
      it 'returns false with missing param' do
        params = valid_params.except(param_key)

        expect(subject.valid_params?(params)).to be_falsy
      end
    end
  end

  describe '#get_dashboard' do
    let(:service_params) do
      [
        project,
        user,
        {
          cluster: cluster,
          cluster_type: :project,
          embedded: 'true',
          group: 'Cluster Health',
          title: 'CPU Usage',
          y_label: 'CPU (cores)'
        }
      ]
    end
    let(:service_call) { described_class.new(*service_params).get_dashboard }
    let(:panel_groups) { service_call[:dashboard][:panel_groups] }
    let(:panel) { panel_groups.first[:panels].first }

    it_behaves_like 'valid embedded dashboard service response'
    it_behaves_like 'caches the unprocessed dashboard for subsequent calls'

    it 'returns one panel' do
      expect(panel_groups.size).to eq 1
      expect(panel_groups.first[:panels].size).to eq 1
    end

    it 'returns panel by title and y_label' do
      expect(panel[:title]).to eq(service_params.last[:title])
      expect(panel[:y_label]).to eq(service_params.last[:y_label])
    end
  end
end
