# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Todos do
  let_it_be(:group) { create(:group) }
  let_it_be(:project_1) { create(:project, :repository, group: group) }
  let_it_be(:project_2) { create(:project) }
  let_it_be(:author_1) { create(:user) }
  let_it_be(:author_2) { create(:user) }
  let_it_be(:john_doe) { create(:user, username: 'john_doe') }
  let_it_be(:merge_request) { create(:merge_request, source_project: project_1) }
  let_it_be(:merge_request_todo) { create(:todo, project: project_1, author: author_2, user: john_doe, target: merge_request) }
  let_it_be(:pending_1) { create(:todo, :mentioned, project: project_1, author: author_1, user: john_doe) }
  let_it_be(:pending_2) { create(:todo, project: project_2, author: author_2, user: john_doe) }
  let_it_be(:pending_3) { create(:on_commit_todo, project: project_1, author: author_2, user: john_doe) }
  let_it_be(:done) { create(:todo, :done, project: project_1, author: author_1, user: john_doe) }
  let_it_be(:award_emoji_1) { create(:award_emoji, awardable: merge_request, user: author_1, name: 'thumbsup') }
  let_it_be(:award_emoji_2) { create(:award_emoji, awardable: pending_1.target, user: author_1, name: 'thumbsup') }
  let_it_be(:award_emoji_3) { create(:award_emoji, awardable: pending_2.target, user: author_2, name: 'thumbsdown') }

  before_all do
    project_1.add_developer(john_doe)
    project_2.add_developer(john_doe)
  end

  describe 'GET /todos' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        get api('/todos')

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      context 'when invalid params' do
        context "invalid action" do
          it 'returns 400' do
            get api('/todos', john_doe), params: { action: 'InvalidAction' }
            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end

        context "invalid state" do
          it 'returns 400' do
            get api('/todos', john_doe), params: { state: 'InvalidState' }
            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end

        context "invalid type" do
          it 'returns 400' do
            get api('/todos', john_doe), params: { type: 'InvalidType' }
            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      it 'returns an array of pending todos for current user' do
        get api('/todos', john_doe)

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to include_pagination_headers
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(4)
        expect(json_response[0]['id']).to eq(pending_3.id)
        expect(json_response[0]['project']).to be_a Hash
        expect(json_response[0]['author']).to be_a Hash
        expect(json_response[0]['target_type']).to be_present
        expect(json_response[0]['target']).to be_a Hash
        expect(json_response[0]['target_url']).to be_present
        expect(json_response[0]['body']).to be_present
        expect(json_response[0]['state']).to eq('pending')
        expect(json_response[0]['action_name']).to eq('assigned')
        expect(json_response[0]['created_at']).to be_present
        expect(json_response[0]['target_type']).to eq('Commit')

        expect(json_response[1]['target_type']).to eq('Issue')
        expect(json_response[1]['target']['upvotes']).to eq(0)
        expect(json_response[1]['target']['downvotes']).to eq(1)
        expect(json_response[1]['target']['merge_requests_count']).to eq(0)

        expect(json_response[2]['target_type']).to eq('Issue')
        expect(json_response[2]['target']['upvotes']).to eq(1)
        expect(json_response[2]['target']['downvotes']).to eq(0)
        expect(json_response[2]['target']['merge_requests_count']).to eq(0)

        expect(json_response[3]['target_type']).to eq('MergeRequest')
        # Only issues get a merge request count at the moment
        expect(json_response[3]['target']['merge_requests_count']).to be_nil
        expect(json_response[3]['target']['upvotes']).to eq(1)
        expect(json_response[3]['target']['downvotes']).to eq(0)
      end

      context 'and using the author filter' do
        it 'filters based on author_id param' do
          get api('/todos', john_doe), params: { author_id: author_2.id }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(3)
        end
      end

      context 'and using the type filter' do
        it 'filters based on type param' do
          create(:todo, project: project_1, author: author_2, user: john_doe, target: merge_request)

          get api('/todos', john_doe), params: { type: 'MergeRequest' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(2)
        end
      end

      context 'and using the state filter' do
        it 'filters based on state param' do
          get api('/todos', john_doe), params: { state: 'done' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(1)
        end
      end

      context 'and using the project filter' do
        it 'filters based on project_id param' do
          get api('/todos', john_doe), params: { project_id: project_2.id }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(1)
        end
      end

      context 'and using the group filter' do
        it 'filters based on project_id param' do
          get api('/todos', john_doe), params: { group_id: group.id, sort: :target_id }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(3)
        end
      end

      context 'and using the action filter' do
        it 'filters based on action param' do
          get api('/todos', john_doe), params: { action: 'mentioned' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(1)
        end
      end
    end

    it 'avoids N+1 queries', :request_store do
      create(:todo, project: project_1, author: author_2, user: john_doe, target: merge_request)

      get api('/todos', john_doe)

      control = ActiveRecord::QueryRecorder.new { get api('/todos', john_doe) }

      merge_request_2 = create(:merge_request, source_project: project_2)
      create(:todo, project: project_2, author: author_2, user: john_doe, target: merge_request_2)

      project_3 = create(:project, :repository)
      project_3.add_developer(john_doe)
      merge_request_3 = create(:merge_request, source_project: project_3)
      create(:todo, project: project_3, author: author_2, user: john_doe, target: merge_request_3)
      create(:todo, :mentioned, project: project_1, author: author_1, user: john_doe)
      create(:on_commit_todo, project: project_3, author: author_1, user: john_doe)

      expect { get api('/todos', john_doe) }.not_to exceed_query_limit(control)
      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'when there is a Design Todo' do
      let!(:design_todo) { create_todo_for_mentioned_in_design }

      def create_todo_for_mentioned_in_design
        issue = create(:issue, project: project_1)
        create(:todo, :mentioned,
               user: john_doe,
               project: project_1,
               target: create(:design, issue: issue),
               author: create(:user),
               note: create(:note, project: project_1, note: "I am note, hear me roar"))
      end

      def api_request
        get api('/todos', john_doe)
      end

      before do
        api_request
      end

      specify do
        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'avoids N+1 queries', :request_store do
        control = ActiveRecord::QueryRecorder.new { api_request }

        create_todo_for_mentioned_in_design

        expect { api_request }.not_to exceed_query_limit(control)
      end

      it 'includes the Design Todo in the response' do
        expect(json_response).to include(
          a_hash_including('id' => design_todo.id)
        )
      end
    end
  end

  describe 'POST /todos/:id/mark_as_done' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        post api("/todos/#{pending_1.id}/mark_as_done")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'marks a todo as done' do
        post api("/todos/#{pending_1.id}/mark_as_done", john_doe)

        expect(response).to have_gitlab_http_status(:created)
        expect(json_response['id']).to eq(pending_1.id)
        expect(json_response['state']).to eq('done')
        expect(pending_1.reload).to be_done
      end

      it 'updates todos cache' do
        expect_any_instance_of(User).to receive(:update_todos_count_cache).and_call_original

        post api("/todos/#{pending_1.id}/mark_as_done", john_doe)
      end

      it 'returns 404 if the todo does not belong to the current user' do
        post api("/todos/#{pending_1.id}/mark_as_done", author_1)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST /mark_as_done' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        post api('/todos/mark_as_done')

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      it 'marks all todos as done' do
        post api('/todos/mark_as_done', john_doe)

        expect(response).to have_gitlab_http_status(:no_content)
        expect(pending_1.reload).to be_done
        expect(pending_2.reload).to be_done
        expect(pending_3.reload).to be_done
      end

      it 'updates todos cache' do
        expect_any_instance_of(User).to receive(:update_todos_count_cache).and_call_original

        post api("/todos/mark_as_done", john_doe)
      end
    end
  end

  shared_examples 'an issuable' do |issuable_type|
    it 'creates a todo on an issuable' do
      post api("/projects/#{project_1.id}/#{issuable_type}/#{issuable.iid}/todo", john_doe)

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['project']).to be_a Hash
      expect(json_response['author']).to be_a Hash
      expect(json_response['target_type']).to eq(issuable.class.name)
      expect(json_response['target']).to be_a Hash
      expect(json_response['target_url']).to be_present
      expect(json_response['body']).to be_present
      expect(json_response['state']).to eq('pending')
      expect(json_response['action_name']).to eq('marked')
      expect(json_response['created_at']).to be_present
      expect(json_response['updated_at']).to be_present
    end

    it 'returns 304 there already exist a todo on that issuable' do
      create(:todo, project: project_1, author: author_1, user: john_doe, target: issuable)

      post api("/projects/#{project_1.id}/#{issuable_type}/#{issuable.iid}/todo", john_doe)

      expect(response).to have_gitlab_http_status(:not_modified)
    end

    it 'returns 404 if the issuable is not found' do
      unknown_id = 0

      post api("/projects/#{project_1.id}/#{issuable_type}/#{unknown_id}/todo", john_doe)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns an error if the issuable is not accessible' do
      guest = create(:user)
      project_1.add_guest(guest)

      post api("/projects/#{project_1.id}/#{issuable_type}/#{issuable.iid}/todo", guest)

      if issuable_type == 'merge_requests'
        expect(response).to have_gitlab_http_status(:forbidden)
      else
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST :id/issuable_type/:issueable_id/todo' do
    context 'for an issue' do
      it_behaves_like 'an issuable', 'issues' do
        let_it_be(:issuable) do
          create(:issue, :confidential, author: author_1, project: project_1)
        end
      end
    end

    context 'for a merge request' do
      it_behaves_like 'an issuable', 'merge_requests' do
        let_it_be(:issuable) do
          create(:merge_request, :simple, source_project: project_1)
        end
      end
    end
  end
end
