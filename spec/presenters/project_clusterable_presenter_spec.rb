# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectClusterablePresenter, feature_category: :environment_management do
  include Gitlab::Routing.url_helpers

  let(:presenter) { described_class.new(project) }
  let(:project) { build_stubbed(:project) }
  let(:cluster) { build_stubbed(:cluster, :provided_by_gcp, projects: [project]) }

  describe '#can_create_cluster?' do
    let(:user) { build_stubbed(:user) }

    subject { presenter.can_create_cluster? }

    before do
      allow(presenter).to receive(:current_user).and_return(user)
    end

    context 'when user can create' do
      before do
        stub_member_access_level(project, maintainer: user)
      end

      it { is_expected.to be_truthy }
    end

    context 'when user cannot create' do
      it { is_expected.to be_falsey }
    end
  end

  describe '#index_path' do
    subject { presenter.index_path }

    it { is_expected.to eq(project_clusters_path(project)) }
  end

  describe '#connect_path' do
    subject { presenter.connect_path }

    it { is_expected.to eq(connect_project_clusters_path(project)) }
  end

  describe '#new_cluster_docs_path' do
    subject { presenter.new_cluster_docs_path }

    it { is_expected.to eq(new_cluster_docs_project_clusters_path(project)) }
  end

  describe '#create_user_clusters_path' do
    subject { presenter.create_user_clusters_path }

    it { is_expected.to eq(create_user_project_clusters_path(project)) }
  end

  describe '#cluster_status_cluster_path' do
    subject { presenter.cluster_status_cluster_path(cluster) }

    it { is_expected.to eq(cluster_status_project_cluster_path(project, cluster)) }
  end

  describe '#clear_cluster_cache_path' do
    subject { presenter.clear_cluster_cache_path(cluster) }

    it { is_expected.to eq(clear_cache_project_cluster_path(project, cluster)) }
  end

  describe '#cluster_path' do
    subject { presenter.cluster_path(cluster) }

    it { is_expected.to eq(project_cluster_path(project, cluster)) }
  end

  describe '#learn_more_link' do
    subject { presenter.learn_more_link }

    it { is_expected.to include('user/project/clusters/_index') }
  end
end
