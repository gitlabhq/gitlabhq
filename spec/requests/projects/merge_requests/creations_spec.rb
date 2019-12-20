# frozen_string_literal: true

require 'spec_helper'

describe 'merge requests creations' do
  describe 'GET /:namespace/:project/merge_requests/new' do
    include ProjectForksHelper

    let(:project) { create(:project, :repository) }
    let(:user) { project.owner }

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
  end
end
