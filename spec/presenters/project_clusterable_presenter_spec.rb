# frozen_string_literal: true

require 'spec_helper'

describe ProjectClusterablePresenter do
  include Gitlab::Routing.url_helpers

  let(:presenter) { described_class.new(project) }
  let(:project) { create(:project) }
  let(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }

  describe '#can_create_cluster?' do
    let(:user) { create(:user) }

    subject { presenter.can_create_cluster? }

    before do
      allow(presenter).to receive(:current_user).and_return(user)
    end

    context 'when user can create' do
      before do
        project.add_maintainer(user)
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

  describe '#new_path' do
    subject { presenter.new_path }

    it { is_expected.to eq(new_project_cluster_path(project)) }
  end

  describe '#authorize_aws_role_path' do
    subject { presenter.authorize_aws_role_path }

    it { is_expected.to eq(authorize_aws_role_project_clusters_path(project)) }
  end

  describe '#create_user_clusters_path' do
    subject { presenter.create_user_clusters_path }

    it { is_expected.to eq(create_user_project_clusters_path(project)) }
  end

  describe '#create_gcp_clusters_path' do
    subject { presenter.create_gcp_clusters_path }

    it { is_expected.to eq(create_gcp_project_clusters_path(project)) }
  end

  describe '#cluster_status_cluster_path' do
    subject { presenter.cluster_status_cluster_path(cluster) }

    it { is_expected.to eq(cluster_status_project_cluster_path(project, cluster)) }
  end

  describe '#install_applications_cluster_path' do
    let(:application) { :helm }

    subject { presenter.install_applications_cluster_path(cluster, application) }

    it { is_expected.to eq(install_applications_project_cluster_path(project, cluster, application)) }
  end

  describe '#update_applications_cluster_path' do
    let(:application) { :helm }

    subject { presenter.update_applications_cluster_path(cluster, application) }

    it { is_expected.to eq(update_applications_project_cluster_path(project, cluster, application)) }
  end

  describe '#clear_cluster_cache_path' do
    subject { presenter.clear_cluster_cache_path(cluster) }

    it { is_expected.to eq(clear_cache_project_cluster_path(project, cluster)) }
  end

  describe '#cluster_path' do
    subject { presenter.cluster_path(cluster) }

    it { is_expected.to eq(project_cluster_path(project, cluster)) }
  end
end
