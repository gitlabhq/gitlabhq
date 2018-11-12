require 'spec_helper'

describe Clusters::ClusterPresenter do
  include Gitlab::Routing.url_helpers

  let(:cluster) { create(:cluster, :provided_by_gcp, :project) }

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
      expect(presenter.status).to eq(cluster.status)
    end
  end

  describe '#gke_cluster_url' do
    subject { described_class.new(cluster).gke_cluster_url }

    it { is_expected.to include(cluster.provider.zone) }
    it { is_expected.to include(cluster.name) }
  end

  describe '#can_toggle_cluster' do
    let(:user) { create(:user) }

    before do
      allow(cluster).to receive(:current_user).and_return(user)
    end

    subject { described_class.new(cluster).can_toggle_cluster? }

    context 'when user can update' do
      before do
        allow_any_instance_of(described_class).to receive(:can?).with(user, :update_cluster, cluster).and_return(true)
      end

      context 'when cluster is created' do
        before do
          allow(cluster).to receive(:created?).and_return(true)
        end

        it { is_expected.to eq(true) }
      end

      context 'when cluster is not created' do
        before do
          allow(cluster).to receive(:created?).and_return(false)
        end

        it { is_expected.to eq(false) }
      end
    end

    context 'when user can not update' do
      before do
        allow_any_instance_of(described_class).to receive(:can?).with(user, :update_cluster, cluster).and_return(false)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe '#show_path' do
    subject { described_class.new(cluster).show_path }

    context 'project_type cluster' do
      let(:project) { cluster.project }

      it { is_expected.to eq(project_cluster_path(project, cluster)) }
    end

    context 'group_type cluster' do
      let(:group) { cluster.group }
      let(:cluster) { create(:cluster, :provided_by_gcp, :group) }

      it { is_expected.to eq(group_cluster_path(group, cluster)) }
    end
  end
end
