# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Statistics, 'Statistics', :aggregate_failures, feature_category: :devops_reports do
  include ProjectForksHelper
  tables_to_analyze = %w[
    projects
    users
    namespaces
    issues
    merge_requests
    notes
    snippets
    fork_networks
    fork_network_members
    keys
    milestones
  ].freeze

  let(:path) { "/application/statistics" }

  describe "GET /application/statistics" do
    it_behaves_like 'GET request permissions for admin mode'

    context 'when no user' do
      it "returns authentication error" do
        get api(path, nil)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context "when not an admin" do
      let(:user) { create(:user) }

      it "returns forbidden error" do
        get api(path, user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as admin' do
      let(:admin) { create(:admin) }

      it 'matches the response schema' do
        get api(path, admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to match_response_schema('statistics')
      end

      it 'gives the right statistics' do
        projects = create_list(:project, 4, namespace: create(:namespace, owner: admin))
        issues = create_list(:issue, 2, project: projects.first, updated_by: admin)

        create_list(:personal_snippet, 2, :public, author: admin)
        create_list(:note, 2, author: admin, project: projects.first, noteable: issues.first)
        create_list(:milestone, 3, project: projects.first)
        create(:key, user: admin)
        create(:merge_request, :skip_diff_creation, source_project: projects.first)
        fork_project(projects.first, admin)

        # Make sure the reltuples have been updated
        # to get a correct count on postgresql
        tables_to_analyze.each do |table|
          ApplicationRecord.connection.execute("ANALYZE #{table}")
        end

        get api(path, admin, admin_mode: true)

        expected_statistics = {
          issues: 2,
          merge_requests: 1,
          notes: 2,
          snippets: 2,
          forks: 1,
          ssh_keys: 1,
          milestones: 3,
          users: 1,
          projects: 5,
          groups: 1,
          active_users: 1
        }

        expected_statistics.each do |entity, count|
          expect(json_response[entity.to_s]).to eq(count.to_s)
        end
      end
    end
  end
end
