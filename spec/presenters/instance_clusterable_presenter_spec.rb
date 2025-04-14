# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InstanceClusterablePresenter, feature_category: :environment_management do
  include Gitlab::Routing.url_helpers

  let(:presenter) { described_class.new(instance) }
  let(:cluster) { create(:cluster, :provided_by_gcp, :instance) }
  let(:instance) { cluster.instance }

  describe '#connect_path' do
    subject { described_class.new(instance).connect_path }

    it { is_expected.to eq(connect_admin_clusters_path) }
  end

  describe '#clear_cluster_cache_path' do
    subject { presenter.clear_cluster_cache_path(cluster) }

    it { is_expected.to eq(clear_cache_admin_cluster_path(cluster)) }
  end

  describe '#create_cluster_migration_path' do
    subject { presenter.create_cluster_migration_path(cluster) }

    it { is_expected.to eq(migrate_admin_cluster_path(cluster)) }
  end

  describe '#update_cluster_migration_path' do
    subject { presenter.update_cluster_migration_path(cluster) }

    it { is_expected.to eq(update_migration_admin_cluster_path(cluster)) }
  end

  describe '#sidebar_text' do
    subject { presenter.sidebar_text }

    it 'renders correct sidebar text' do
      is_expected.to eq(s_('ClusterIntegration|Adding a Kubernetes cluster will automatically share ' \
        'the cluster across all projects. Use review apps, deploy your applications, ' \
        'and easily run your pipelines for all projects using the same cluster.'))
    end
  end

  describe '#learn_more_link' do
    subject { presenter.learn_more_link }

    it { is_expected.to include('user/instance/clusters/_index') }
  end
end
