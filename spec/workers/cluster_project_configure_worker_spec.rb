# frozen_string_literal: true

require 'spec_helper'

describe ClusterProjectConfigureWorker, '#perform' do
  let(:worker) { described_class.new }

  context 'ci_preparing_state feature is enabled' do
    let(:cluster) { create(:cluster) }

    before do
      stub_feature_flags(ci_preparing_state: true)
    end

    it 'does not configure the cluster' do
      expect(Clusters::RefreshService).not_to receive(:create_or_update_namespaces_for_project)

      described_class.new.perform(cluster.id)
    end
  end
end
