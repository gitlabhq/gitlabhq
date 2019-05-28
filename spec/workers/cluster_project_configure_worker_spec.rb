# frozen_string_literal: true

require 'spec_helper'

describe ClusterProjectConfigureWorker, '#perform' do
  let(:worker) { described_class.new }
  let(:cluster) { create(:cluster, :project) }

  it 'configures the cluster' do
    expect(Clusters::RefreshService).to receive(:create_or_update_namespaces_for_project)

    described_class.new.perform(cluster.projects.first.id)
  end
end
