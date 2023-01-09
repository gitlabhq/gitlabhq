# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'merge requests creations', feature_category: :code_review_workflow do
  describe 'GET /:namespace/:project/merge_requests/new' do
    include ProjectForksHelper

    let(:project) { create(:project, :repository) }
    let(:user) { project.first_owner }

    before do
      login_as(user)
    end

    def get_new
      get namespace_project_new_merge_request_path(namespace_id: project.namespace, project_id: project)
    end

    it 'avoids N+1 DB queries even with forked projects' do
      control = ActiveRecord::QueryRecorder.new(skip_cached: false) { get_new }

      5.times { fork_project(project, user) }

      expect { get_new }.not_to exceed_query_limit(control)
    end

    it_behaves_like "observability csp policy", Projects::MergeRequests::CreationsController do
      let_it_be(:group) { create(:group) }
      let_it_be(:user) { create(:user) }
      let_it_be(:project) { create(:project, group: group) }
      let(:tested_path) do
        project_new_merge_request_path(project, merge_request: {
          title: 'Some feature',
            source_branch: 'fix',
            target_branch: 'feature',
            target_project: project,
            source_project: project
        })
      end
    end
  end
end
