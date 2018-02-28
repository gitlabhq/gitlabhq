require 'spec_helper'

describe Gcp::ClusterPresenter do
  let(:project) { create(:project) }
  let(:cluster) { create(:gcp_cluster, project: project) }

  subject(:presenter) do
    described_class.new(cluster)
  end

  it 'inherits from Gitlab::View::Presenter::Delegated' do
    expect(described_class.superclass).to eq(Gitlab::View::Presenter::Delegated)
  end

  describe '#initialize' do
    it 'takes a cluster and optional params' do
      expect { presenter }.not_to raise_error
    end

    it 'exposes cluster' do
      expect(presenter.cluster).to eq(cluster)
    end

    it 'forwards missing methods to cluster' do
      expect(presenter.gcp_cluster_zone).to eq(cluster.gcp_cluster_zone)
    end
  end

  describe '#gke_cluster_url' do
    subject { described_class.new(cluster).gke_cluster_url }

    it { is_expected.to include(cluster.gcp_cluster_zone) }
    it { is_expected.to include(cluster.gcp_cluster_name) }
  end
end
