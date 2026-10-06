# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::WorkItems::DiscussionNotes, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:non_member) { create(:user) }
  let_it_be(:project) { create(:project, :private, reporters: user) }
  let_it_be_with_reload(:work_item) { create(:work_item, :issue, project: project) }
  let_it_be(:comment) { create(:note, project: project, noteable: work_item, author: user, note: 'A user comment') }

  let(:container) { project }
  let(:note_params) { { project: project } }

  shared_examples 'a project work item discussion notes endpoint' do
    it_behaves_like 'a work item discussion notes endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end

    it 'returns not_found when the user cannot read the work item' do
      get api(api_request_path, non_member)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'a project work item discussion note endpoint' do
    let(:api_request_path) { discussion_note_path.call(comment.discussion_id, comment.id) }

    it_behaves_like 'a work item discussion note endpoint'

    it_behaves_like 'authorizing granular token permissions', :read_work_item do
      let(:boundary_object) { project }
      let(:request) do
        get api(api_request_path, personal_access_token: pat)
      end
    end

    it 'returns not_found when the user cannot read the work item' do
      get api(api_request_path, non_member)

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'a project work item endpoint updating a discussion note' do
    let(:discussion_note) { create(:discussion_note_on_work_item, noteable: work_item, author: user, project: project) }
    let(:api_request_path) { discussion_note_path.call(discussion_note.discussion_id, discussion_note.id) }

    it_behaves_like 'a work item endpoint updating a discussion note'

    # Time tracking quick actions are project-only, so this is not part of the shared examples.
    it 'returns 202 when the note is modified with only quick actions', :aggregate_failures do
      put api(api_request_path, user), params: { body: '/spend 1d' }

      expect(response).to have_gitlab_http_status(:accepted)
      expect(json_response['commands_changes']).to include('spend_time')
      expect(json_response['summary']).to eq(['Added 1d spent time.'])
    end

    it_behaves_like 'authorizing granular token permissions', :update_issue_discussion_note do
      let(:boundary_object) { project }
      let(:request) do
        put api(api_request_path, personal_access_token: pat), params: { body: 'Hello!' }
      end
    end

    it 'returns not_found when the user cannot read the work item' do
      put api(api_request_path, non_member), params: { body: 'Hello!' }

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET /projects/:id/-/work_items/:work_item_iid/discussions/:discussion_id/notes' do
    let(:api_request_path) do
      "/projects/#{project.id}/-/work_items/#{work_item.iid}/discussions/#{comment.discussion_id}/notes"
    end

    it_behaves_like 'a project work item discussion notes endpoint'
  end

  describe 'GET /namespaces/:id/-/work_items/:work_item_iid/discussions/:discussion_id/notes' do
    let(:api_request_path) do
      "/namespaces/#{CGI.escape(project.project_namespace.full_path)}/-/work_items/#{work_item.iid}/discussions/" \
        "#{comment.discussion_id}/notes"
    end

    it_behaves_like 'a project work item discussion notes endpoint'
  end

  describe 'GET /projects/:id/-/work_items/:work_item_iid/discussions/:discussion_id/notes/:note_id' do
    let(:discussion_note_path) do
      ->(discussion_id, note_id, work_item_iid: work_item.iid) do
        "/projects/#{project.id}/-/work_items/#{work_item_iid}/discussions/#{discussion_id}/notes/#{note_id}"
      end
    end

    it_behaves_like 'a project work item discussion note endpoint'
  end

  describe 'GET /namespaces/:id/-/work_items/:work_item_iid/discussions/:discussion_id/notes/:note_id' do
    let(:discussion_note_path) do
      ->(discussion_id, note_id, work_item_iid: work_item.iid) do
        "/namespaces/#{CGI.escape(project.project_namespace.full_path)}/-/work_items/#{work_item_iid}/discussions/" \
          "#{discussion_id}/notes/#{note_id}"
      end
    end

    it_behaves_like 'a project work item discussion note endpoint'
  end

  describe 'PUT /projects/:id/-/work_items/:work_item_iid/discussions/:discussion_id/notes/:note_id' do
    let(:discussion_note_path) do
      ->(discussion_id, note_id, work_item_iid: work_item.iid) do
        "/projects/#{project.id}/-/work_items/#{work_item_iid}/discussions/#{discussion_id}/notes/#{note_id}"
      end
    end

    it_behaves_like 'a project work item endpoint updating a discussion note'
  end

  describe 'PUT /namespaces/:id/-/work_items/:work_item_iid/discussions/:discussion_id/notes/:note_id' do
    let(:discussion_note_path) do
      ->(discussion_id, note_id, work_item_iid: work_item.iid) do
        "/namespaces/#{CGI.escape(project.project_namespace.full_path)}/-/work_items/#{work_item_iid}/discussions/" \
          "#{discussion_id}/notes/#{note_id}"
      end
    end

    it_behaves_like 'a project work item endpoint updating a discussion note'
  end
end
