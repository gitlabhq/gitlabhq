# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupClusterablePresenter do
  include Gitlab::Routing.url_helpers

  let(:presenter) { described_class.new(group) }
  let(:cluster) { create(:cluster, :provided_by_gcp, :group) }
  let(:group) { cluster.group }

  describe '#can_create_cluster?' do
    let(:user) { create(:user) }

    subject { presenter.can_create_cluster? }

    before do
      allow(presenter).to receive(:current_user).and_return(user)
    end

    context 'when user can create' do
      before do
        group.add_maintainer(user)
      end

      it { is_expected.to be_truthy }
    end

    context 'when user cannot create' do
      it { is_expected.to be_falsey }
    end
  end

  describe '#index_path' do
    subject { presenter.index_path }

    it { is_expected.to eq(group_clusters_path(group)) }
  end

  describe '#connect_path' do
    subject { presenter.connect_path }

    it { is_expected.to eq(connect_group_clusters_path(group)) }
  end

  describe '#create_user_clusters_path' do
    subject { presenter.create_user_clusters_path }

    it { is_expected.to eq(create_user_group_clusters_path(group)) }
  end

  describe '#cluster_status_cluster_path' do
    subject { presenter.cluster_status_cluster_path(cluster) }

    it { is_expected.to eq(cluster_status_group_cluster_path(group, cluster)) }
  end

  describe '#clear_cluster_cache_path' do
    subject { presenter.clear_cluster_cache_path(cluster) }

    it { is_expected.to eq(clear_cache_group_cluster_path(group, cluster)) }
  end

  describe '#cluster_path' do
    subject { presenter.cluster_path(cluster) }

    it { is_expected.to eq(group_cluster_path(group, cluster)) }
  end

  describe '#learn_more_link' do
    subject { presenter.learn_more_link }

    it { is_expected.to include('user/group/clusters/_index') }
  end
end
