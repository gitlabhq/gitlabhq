# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ClusterDiscovery, feature_category: :deployment_management do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }

  before_all do
    group.add_maintainer(current_user)
  end

  describe 'GET /discover-cert-based-clusters' do
    # NOTE: this sets up the following hierarchy of groups and projects with their associated cert-based clusters
    #
    # group:
    #   -> No. clusters: 2
    #   project1:
    #     -> No. clusters: 2
    #   project2:
    #     -> No. clusters: 0
    #   subgroup1:
    #     -> No. clusters: 2
    #     project3:
    #       -> No. clusters: 2
    #   subgroup2:
    #     -> No. clusters: 0
    #     project4:
    #       -> No. clusters: 2
    #     project5:
    #       -> No. clusters: 0
    #     subsubgroup1:
    #       -> No. clusters: 2
    let_it_be(:project1) { create(:project, :private, namespace: group) }
    let_it_be(:project2) { create(:project, :private, namespace: group) }
    let_it_be(:subgroup1) { create(:group, :private, parent: group) }
    let_it_be(:project3) { create(:project, :private, namespace: subgroup1) }
    let_it_be(:subgroup2) { create(:group, :private, parent: group) }
    let_it_be(:project4) { create(:project, :private, namespace: subgroup2) }
    let_it_be(:project5) { create(:project, :private, namespace: subgroup2) }
    let_it_be(:subsubgroup1) { create(:group, :private, parent: subgroup2) }
    let_it_be(:group_clusters) do
      create_list(:cluster, 2, :provided_by_gcp, :group, :production_environment, groups: [group])
    end

    let_it_be(:project1_clusters) do
      create_list(:cluster, 2, :provided_by_gcp, :project, :production_environment, projects: [project1])
    end

    let_it_be(:subgroup1_clusters) do
      create_list(:cluster, 2, :provided_by_gcp, :group, :production_environment, groups: [subgroup1])
    end

    let_it_be(:project3_clusters) do
      create_list(:cluster, 2, :provided_by_gcp, :project, :production_environment, projects: [project3])
    end

    let_it_be(:project4_clusters) do
      create_list(:cluster, 2, :provided_by_gcp, :project, :production_environment, projects: [project4])
    end

    let_it_be(:subsubgroup1_clusters) do
      create_list(:cluster, 2, :provided_by_gcp, :group, :production_environment, groups: [subsubgroup1])
    end

    context 'when user is not authorized' do
      let(:unauthorized_user) { create(:user) }

      subject(:request) { get api("/discover-cert-based-clusters", unauthorized_user), params: { group_id: group.id } }

      it 'responds with 404 Not Found' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user is authorized' do
      subject(:request) { get api("/discover-cert-based-clusters", current_user), params: { group_id: group.id } }

      it 'responds with 200' do
        request

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'response contains direct and descendant group clusters' do
        request

        expect(response).to have_gitlab_http_status(:ok)

        group_clusters_response = json_response['groups']
        expect(group_clusters_response.keys).to contain_exactly(group.full_path, subgroup1.full_path,
          subsubgroup1.full_path)
        expect(group_clusters_response[group.full_path].pluck('id')).to match_array(group_clusters.pluck(:id))
        expect(group_clusters_response[subgroup1.full_path].pluck('id')).to match_array(subgroup1_clusters.pluck(:id))
        expect(group_clusters_response[subsubgroup1.full_path].pluck('id')).to match_array(
          subsubgroup1_clusters.pluck(:id))
      end

      it 'response contains descendant project clusters' do
        request

        expect(response).to have_gitlab_http_status(:ok)

        project_clusters_response = json_response['projects']
        expect(project_clusters_response.keys).to contain_exactly(
          project1.path_with_namespace, project3.path_with_namespace, project4.path_with_namespace)
        expect(project_clusters_response[project1.path_with_namespace].pluck('id')).to match_array(
          project1_clusters.pluck(:id))
        expect(project_clusters_response[project3.path_with_namespace].pluck('id')).to match_array(
          project3_clusters.pluck(:id))
        expect(project_clusters_response[project4.path_with_namespace].pluck('id')).to match_array(
          project4_clusters.pluck(:id))
      end
    end
  end
end
