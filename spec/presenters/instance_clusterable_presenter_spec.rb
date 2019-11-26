# frozen_string_literal: true

require 'spec_helper'

describe InstanceClusterablePresenter do
  include Gitlab::Routing.url_helpers

  let(:presenter) { described_class.new(instance) }
  let(:cluster) { create(:cluster, :provided_by_gcp, :instance) }
  let(:instance) { cluster.instance }

  describe '#create_aws_clusters_path' do
    subject { described_class.new(instance).create_aws_clusters_path }

    it { is_expected.to eq(create_aws_admin_clusters_path) }
  end

  describe '#authorize_aws_role_path' do
    subject { described_class.new(instance).authorize_aws_role_path }

    it { is_expected.to eq(authorize_aws_role_admin_clusters_path) }
  end

  describe '#revoke_aws_role_path' do
    subject { described_class.new(instance).revoke_aws_role_path }

    it { is_expected.to eq(revoke_aws_role_admin_clusters_path) }
  end

  describe '#aws_api_proxy_path' do
    let(:resource) { 'resource' }

    subject { described_class.new(instance).aws_api_proxy_path(resource) }

    it { is_expected.to eq(aws_proxy_admin_clusters_path(resource: resource)) }
  end

  describe '#clear_cluster_cache_path' do
    subject { presenter.clear_cluster_cache_path(cluster) }

    it { is_expected.to eq(clear_cache_admin_cluster_path(cluster)) }
  end
end
