# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Todos, feature_category: :source_code_management do
  include DesignManagementTestHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:group_2) { create(:group) }
  let_it_be(:project_1) { create(:project, :repository, group: group) }
  let_it_be(:project_2) { create(:project) }
  let_it_be(:author_1) { create(:user) }
  let_it_be(:author_2) { create(:user) }
  let_it_be(:john_doe) { create(:user, username: 'john_doe', developer_of: [project_1, project_2]) }
  let_it_be(:issue) { create(:issue, project: project_1) }
  let_it_be(:work_item) { create(:work_item, :task, project: project_1) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project_1) }
  let_it_be(:alert) { create(:alert_management_alert, project: project_1) }
  let_it_be(:project_request_todo) { create(:todo, author: author_1, user: john_doe, target: project_2, action: Todo::MEMBER_ACCESS_REQUESTED) }
  let_it_be(:group_request_todo) { create(:todo, author: author_1, user: john_doe, project: nil, group: group_2, target: group_2, action: Todo::MEMBER_ACCESS_REQUESTED) }
  let_it_be(:alert_todo) { create(:todo, project: project_1, author: john_doe, user: john_doe, target: alert) }
  let_it_be(:merge_request_todo) { create(:todo, project: project_1, author: author_2, user: john_doe, target: merge_request) }
  let_it_be(:pending_1) { create(:todo, :mentioned, project: project_1, author: author_1, user: john_doe, target: issue) }
  let_it_be(:pending_2) { create(:todo, project: project_2, author: author_2, user: john_doe, target: create(:issue, project: project_2)) }
  let_it_be(:pending_3) { create(:on_commit_todo, project: project_1, author: author_2, user: john_doe) }
  let_it_be(:pending_4) { create(:on_commit_todo, project: project_1, author: author_2, user: john_doe, commit_id: 'invalid_id') }
  let_it_be(:pending_5) { create(:todo, :mentioned, project: project_1, author: author_1, user: john_doe, target: work_item, target_type: WorkItem.name) }
  let_it_be(:done) { create(:todo, :done, project: project_1, author: author_1, user: john_doe, target: issue) }
  let_it_be(:award_emoji_1) { create(:award_emoji, awardable: merge_request, user: author_1, name: AwardEmoji::THUMBS_UP) }
  let_it_be(:award_emoji_2) { create(:award_emoji, awardable: pending_1.target, user: author_1, name: AwardEmoji::THUMBS_UP) }
  let_it_be(:award_emoji_3) { create(:award_emoji, awardable: pending_2.target, user: author_2, name: AwardEmoji::THUMBS_DOWN) }

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
        expect(json_response.length).to eq(8)

        expect(json_response[0]).to include(
          'id' => pending_5.id,
          'target_type' => 'WorkItem',
          'target' => hash_including('type' => 'TASK')
        )

        expect(json_response[1]).to include(
          'id' => pending_3.id,
          'project' => instance_of(Hash),
          'author' => instance_of(Hash),
          'target' => instance_of(Hash),
          'state' => 'pending',
          'action_name' => 'assigned',
          'target_type' => 'Commit',
          'target_url' => be_present,
          'body' => be_present,
          'created_at' => be_present
        )

        expect(json_response[2]).to include(
          'target_type' => 'Issue',
          'target' => hash_including(
            'upvotes' => 0,
            'downvotes' => 1,
            'merge_requests_count' => 0
          )
        )

        expect(json_response[3]).to include(
          'target_type' => 'Issue',
          'target' => hash_including(
            'upvotes' => 1,
            'downvotes' => 0,
            'merge_requests_count' => 0
          )
        )

        # Only issues get a merge request count at the moment
        expect(json_response[4].dig('target', 'merge_requests_count')).to be_nil
        expect(json_response[4]).to include(
          'target_type' => 'MergeRequest',
          'target' => hash_including(
            'upvotes' => 1,
            'downvotes' => 0
          )
        )

        expect(json_response[5]).to include(
          'target_type' => 'AlertManagement::Alert',
          'target' => hash_including(
            'iid' => alert.iid,
            'title' => alert.title
          )
        )

        expect(json_response[6]).to include(
          'target_type' => 'Namespace',
          'action_name' => 'member_access_requested',
          'target' => hash_including(
            'id' => group_2.id,
            'name' => group_2.name,
            'full_path' => group_2.full_path
          ),
          'target_url' => Gitlab::Routing.url_helpers.group_group_members_url(group_2, tab: 'access_requests')
        )

        expect(json_response[7]).to include(
          'target_type' => 'Project',
          'action_name' => 'member_access_requested',
          'target' => hash_including(
            'id' => project_2.id,
            'name' => project_2.name,
            'path' => project_2.path
          ),
          'target_url' => Gitlab::Routing.url_helpers.project_project_members_url(project_2, tab: 'access_requests'),
          'body' => project_2.full_path
        )
      end

      context "when current user does not have access to one of the TODO's target" do
        it 'filters out unauthorized todos' do
          no_access_project = create(:project, :repository, group: group)
          no_access_merge_request = create(:merge_request, source_project: no_access_project)
          no_access_todo = create(:todo, project: no_access_project, author: author_2, user: john_doe, target: no_access_merge_request)

          get api('/todos', john_doe)

          expect(json_response.count).to eq(8)
          expect(json_response.map { |t| t['id'] }).not_to include(no_access_todo.id, pending_4.id)
        end
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
          expect(json_response.length).to eq(5)
        end
      end

      context 'and using the action filter' do
        it 'filters based on action param' do
          get api('/todos', john_doe), params: { action: 'mentioned' }

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(2)
        end
      end
    end

    it 'avoids N+1 queries', :request_store do
      create_issue_todo_for(john_doe)
      create(:todo, project: project_1, author: author_2, user: john_doe, target: merge_request)

      # Destroying to preserve behavior prior to fixing todo's target as WorkItem
      # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/375293 remove when N + 1 are fixed
      pending_5.destroy!

      get api('/todos', john_doe)

      control1 = ActiveRecord::QueryRecorder.new { get api('/todos', john_doe) }

      create_issue_todo_for(john_doe)
      create_mr_todo_for(john_doe, project_2)
      create(:todo, :mentioned, project: project_1, author: author_1, user: john_doe, target: merge_request)
      new_todo = create_mr_todo_for(john_doe)
      merge_request_3 = create(:merge_request, :jira_branch, source_project: new_todo.project)
      create(:on_commit_todo, project: new_todo.project, author: author_1, user: john_doe, target: merge_request_3)
      create(:todo, project: new_todo.project, author: author_2, user: john_doe, target: merge_request_3)
      create(:todo, author: author_2, user: john_doe, target: project_2, action: Todo::MEMBER_ACCESS_REQUESTED)
      create(:todo, author: author_2, user: john_doe, target: group_2, action: Todo::MEMBER_ACCESS_REQUESTED)

      expect { get api('/todos', john_doe) }.not_to exceed_query_limit(control1).with_threshold(7)

      control2 = ActiveRecord::QueryRecorder.new { get api('/todos', john_doe) }

      create_issue_todo_for(john_doe)
      create_issue_todo_for(john_doe, project_1)
      create_issue_todo_for(john_doe, project_1)

      # Additional query only when target belongs to project from different group
      expect { get api('/todos', john_doe) }.not_to exceed_query_limit(control2).with_threshold(1)

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'when there is a Design Todo' do
      let!(:design_todo) { create_todo_for_mentioned_in_design }

      def create_todo_for_mentioned_in_design
        issue = create(:issue, project: project_1)
        create(
          :todo,
          :mentioned,
          user: john_doe,
          project: project_1,
          target: create(:design, issue: issue),
          author: create(:user),
          note: create(:note, :confidential, project: project_1, note: "I am note, hear me roar")
        )
      end

      def api_request
        get api('/todos', john_doe)
      end

      before do
        enable_design_management

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

    def create_mr_todo_for(user, project = nil)
      new_project = project || create(:project, group: create(:group))
      new_project.add_developer(user) if project.blank?
      new_merge_request = create(:merge_request, source_project: new_project)
      create(:todo, project: new_project, author: user, user: user, target: new_merge_request)
    end

    def create_issue_todo_for(user, project = nil)
      new_project = project || create(:project, group: create(:group))
      new_project.group.add_developer(user) if project.blank?
      issue = create(:issue, project: new_project)
      create(:todo, project: new_project, target: issue, author: user, user: user)
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

  shared_examples 'an issuable' do |param|
    let(:issuable_type) { param }
    def create_todo_for_issuable(user, iid = issuable.iid)
      post api("/projects/#{project_1.id}/#{issuable_type}/#{iid}/todo", user)
    end

    it 'creates a todo on an issuable' do
      create_todo_for_issuable(john_doe)

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
      create_todo_for_issuable(john_doe)

      create_todo_for_issuable(john_doe)

      expect(response).to have_gitlab_http_status(:not_modified)
    end

    it 'returns 404 if the issuable is not found' do
      unknown_id = 0

      create_todo_for_issuable(john_doe, unknown_id)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns an error if the issuable is not accessible' do
      guest = create(:user)
      project_1.add_guest(guest)

      create_todo_for_issuable(guest)

      if issuable_type == 'merge_requests'
        expect(response).to have_gitlab_http_status(:forbidden)
      else
        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST :id/issuable_type/:issuable_id/todo' do
    context 'for an issue' do
      let_it_be(:issuable) do
        create(:issue, :confidential, project: project_1)
      end

      it_behaves_like 'an issuable', 'issues'

      it 'returns an error if the issue author does not have access' do
        post api("/projects/#{project_1.id}/issues/#{issuable.iid}/todo", issuable.author)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'for a merge request' do
      let_it_be(:issuable) do
        create(:merge_request, :simple, source_project: project_1)
      end

      it_behaves_like 'an issuable', 'merge_requests'

      it 'returns an error if the merge request author does not have access' do
        project_1.add_guest(issuable.author)

        post api("/projects/#{project_1.id}/merge_requests/#{issuable.iid}/todo", issuable.author)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
