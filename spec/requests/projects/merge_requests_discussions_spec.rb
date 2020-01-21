# frozen_string_literal: true

require 'spec_helper'

describe 'merge requests discussions' do
  # Further tests can be found at merge_requests_controller_spec.rb
  describe 'GET /:namespace/:project/-/merge_requests/:iid/discussions' do
    let(:project) { create(:project, :repository) }
    let(:user) { project.owner }
    let(:merge_request) { create(:merge_request_with_diffs, target_project: project, source_project: project) }

    before do
      project.add_developer(user)
      login_as(user)
    end

    def send_request
      get discussions_namespace_project_merge_request_path(namespace_id: project.namespace, project_id: project, id: merge_request.iid)
    end

    it 'returns 200' do
      send_request

      expect(response.status).to eq(200)
    end

    # https://docs.gitlab.com/ee/development/query_recorder.html#use-request-specs-instead-of-controller-specs
    it 'avoids N+1 DB queries', :request_store do
      control = ActiveRecord::QueryRecorder.new { send_request }

      create(:diff_note_on_merge_request, noteable: merge_request,
             project: merge_request.project)

      expect do
        send_request
      end.not_to exceed_query_limit(control)
    end

    it 'limits Gitaly queries', :request_store do
      Gitlab::GitalyClient.allow_n_plus_1_calls do
        create_list(:diff_note_on_merge_request, 7, noteable: merge_request,
                    project: merge_request.project)
      end

      # The creations above write into the Gitaly counts
      Gitlab::GitalyClient.reset_counts

      expect { send_request }
        .to change { Gitlab::GitalyClient.get_request_count }.by_at_most(4)
    end
  end
end
