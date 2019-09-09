# frozen_string_literal: true

require 'spec_helper'

describe API::Statistics, 'Statistics' do
  include ProjectForksHelper
  TABLES_TO_ANALYZE = %w[
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
    context 'when no user' do
      it "returns authentication error" do
        get api(path, nil)

        expect(response).to have_gitlab_http_status(401)
      end
    end

    context "when not an admin" do
      let(:user) { create(:user) }

      it "returns forbidden error" do
        get api(path, user)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'when authenticated as admin' do
      let(:admin) { create(:admin) }

      it 'matches the response schema' do
        get api(path, admin)

        expect(response).to have_gitlab_http_status(200)
        expect(response).to match_response_schema('statistics')
      end

      it 'gives the right statistics' do
        projects = create_list(:project, 4, namespace: create(:namespace, owner: admin))
        issues = create_list(:issue, 2, project: projects.first, updated_by: admin)

        create_list(:snippet, 2, :public, author: admin)
        create_list(:note, 2, author: admin, project: projects.first, noteable: issues.first)
        create_list(:milestone, 3, project: projects.first)
        create(:key, user: admin)
        create(:merge_request, source_project: projects.first)
        fork_project(projects.first, admin)

        # Make sure the reltuples have been updated
        # to get a correct count on postgresql
        TABLES_TO_ANALYZE.each do |table|
          ActiveRecord::Base.connection.execute("ANALYZE #{table}")
        end

        get api(path, admin)

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
