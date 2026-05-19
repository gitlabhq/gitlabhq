# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::WorkItems::Update, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :private, reporters: user) }
  let_it_be(:project) { create(:project, :private, :repository, group: group, reporters: user) }
  let_it_be(:work_item) { create(:work_item, :task, project: project) }

  before do
    stub_feature_flags(work_item_rest_api: user)
  end

  shared_examples 'work item update endpoint' do
    context 'with title update' do
      it 'updates the title and returns 200' do
        patch api(api_request_path, user), params: { title: 'Updated title' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['title']).to eq('Updated title')
        expect(work_item.reload.title).to eq('Updated title')
      end
    end

    context 'with confidential update' do
      it 'makes the work item confidential' do
        patch api(api_request_path, user), params: { confidential: true }

        expect(response).to have_gitlab_http_status(:ok)
        expect(work_item.reload).to be_confidential
      end
    end

    context 'with state_event close' do
      it 'closes the work item' do
        patch api(api_request_path, user), params: { state_event: 'close' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(work_item.reload).to be_closed
      end
    end

    context 'with state_event reopen' do
      before do
        work_item.reload.close! unless work_item.reload.closed?
      end

      it 'reopens the work item' do
        patch api(api_request_path, user), params: { state_event: 'reopen' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(work_item.reload).to be_opened
      end
    end

    context 'with description feature' do
      it 'updates the description and returns it in the response' do
        patch api(api_request_path, user), params: {
          features: { description: { description: 'Updated description' } }
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.dig('features', 'description', 'description')).to eq('Updated description')
        expect(work_item.reload.description).to eq('Updated description')
      end
    end

    context 'with assignees feature' do
      it 'updates assignees and returns them in the response' do
        patch api(api_request_path, user), params: {
          features: { assignees: { assignee_ids: [user.id] } }
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.dig('features', 'assignees')).to contain_exactly(
          a_hash_including('id' => user.id)
        )
        expect(work_item.reload.assignee_ids).to contain_exactly(user.id)
      end
    end

    context 'with labels feature' do
      it 'adds labels to the work item' do
        patch api(api_request_path, user), params: {
          features: { labels: { add_label_ids: [label.id] } }
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(work_item.reload.label_ids).to include(label.id)
      end

      it 'removes labels from the work item' do
        work_item.labels << label

        patch api(api_request_path, user), params: {
          features: { labels: { remove_label_ids: [label.id] } }
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(work_item.reload.label_ids).not_to include(label.id)
      end
    end

    context 'with milestone feature' do
      it 'sets the milestone on the work item' do
        patch api(api_request_path, user), params: {
          features: { milestone: { milestone_id: milestone.id } }
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.dig('features', 'milestone', 'title')).to eq(milestone.title)
        expect(work_item.reload.milestone).to eq(milestone)
      end

      it 'unsets the milestone when milestone_id is null' do
        work_item.update!(milestone: milestone)

        patch api(api_request_path, user), params: {
          features: { milestone: { milestone_id: nil } }
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(work_item.reload.milestone).to be_nil
      end
    end

    context 'with start_and_due_date feature' do
      it 'updates dates and returns them in the response' do
        patch api(api_request_path, user), params: {
          features: { start_and_due_date: { start_date: '2026-05-01', due_date: '2026-06-01' } }
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.dig('features', 'start_and_due_date')).to include(
          'start_date' => '2026-05-01',
          'due_date' => '2026-06-01'
        )
        expect(work_item.reload.start_date.to_s).to eq('2026-05-01')
        expect(work_item.reload.due_date.to_s).to eq('2026-06-01')
      end
    end

    context 'with hierarchy feature' do
      let(:parent_work_item) { create(:work_item, :issue, project: project) }

      it 'sets the parent work item' do
        patch api(api_request_path, user), params: {
          features: { hierarchy: { parent_id: parent_work_item.id } }
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(work_item.reload.work_item_parent).to eq(parent_work_item)
      end

      it 'removes the parent work item when parent_id is null' do
        work_item.update!(work_item_parent: parent_work_item)

        patch api(api_request_path, user), params: {
          features: { hierarchy: { parent_id: nil } }
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(work_item.reload.work_item_parent).to be_nil
      end

      it 'returns not_found when the parent work item does not exist' do
        patch api(api_request_path, user), params: {
          features: { hierarchy: { parent_id: non_existing_record_id } }
        }

        expect(response).to have_gitlab_http_status(:not_found)
        expect(json_response['message']).to include("Parent work item #{non_existing_record_id}")
      end

      it 'rejects requests with more than the maximum number of children_ids' do
        patch api(api_request_path, user), params: {
          features: { hierarchy: { children_ids: (1..31).to_a } }
        }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to include('children_ids')
      end

      context 'with children_ids' do
        let_it_be(:parent_issue) { create(:work_item, :issue, project: project) }
        let_it_be(:child_a) { create(:work_item, :task, project: project) }
        let_it_be(:child_b) { create(:work_item, :task, project: project) }

        let(:parent_request_path) { "#{base_path}/#{parent_issue.iid}" }

        before do
          # Setting multiple children fans out to ParentLinks::CreateService per child, which
          # exceeds the default threshold. GraphQL disables limiting here too. See
          # app/graphql/mutations/work_items/hierarchy/add_children_items.rb.
          allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(200)
        end

        it 'sets the listed child work items as children of the target' do
          patch api(parent_request_path, user), params: {
            features: { hierarchy: { children_ids: [child_a.id, child_b.id] } }
          }

          expect(response).to have_gitlab_http_status(:ok)
          expect(parent_issue.reload.work_item_children).to contain_exactly(child_a, child_b)
        end

        it 'silently ignores ids that do not resolve to a work item' do
          patch api(parent_request_path, user), params: {
            features: { hierarchy: { children_ids: [child_a.id, non_existing_record_id] } }
          }

          expect(response).to have_gitlab_http_status(:ok)
          expect(parent_issue.reload.work_item_children).to contain_exactly(child_a)
        end

        it 'fetches the children with a single bulk lookup' do
          expect(::WorkItem).to receive(:id_in).once.and_call_original

          patch api(parent_request_path, user), params: {
            features: { hierarchy: { children_ids: [child_a.id, child_b.id] } }
          }

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end

    context 'with notes feature' do
      it 'locks discussion on the work item' do
        patch api(api_request_path, user), params: {
          features: { notes: { discussion_locked: true } }
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(work_item.reload).to be_discussion_locked
      end
    end

    context 'with notifications feature' do
      it 'subscribes the current user to the work item' do
        patch api(api_request_path, user), params: {
          features: { notifications: { subscribed: true } }
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(work_item.subscribed?(user, project)).to be(true)
      end
    end

    context 'with current_user_todos feature' do
      it 'adds a to-do for the current user' do
        patch api(api_request_path, user), params: {
          features: { current_user_todos: { action: 'add' } }
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(Todo.pending.where(target: work_item, user: user)).to exist
      end

      it 'marks all todos as done' do
        create(:todo, target: work_item, user: user, state: :pending, project: project, author: user)

        patch api(api_request_path, user), params: {
          features: { current_user_todos: { action: 'mark_as_done' } }
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(Todo.pending.where(target: work_item, user: user)).not_to exist
      end
    end

    context 'with award_emoji feature' do
      it 'adds an emoji reaction to the work item' do
        patch api(api_request_path, user), params: {
          features: { award_emoji: { action: 'add', name: 'thumbsup' } }
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(work_item.award_emoji.where(name: 'thumbsup', user: user)).to exist
      end
    end

    context 'with crm_contacts feature' do
      it 'sets CRM contacts on the work item' do
        contact = create(:contact, group: project.group)

        patch api(api_request_path, user), params: {
          features: { crm_contacts: { contact_ids: [contact.id] } }
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(work_item.reload.customer_relations_contacts).to include(contact)
      end
    end

    context 'with time_tracking feature' do
      it 'sets a time estimate on the work item' do
        patch api(api_request_path, user), params: {
          features: { time_tracking: { time_estimate: '2h' } }
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(work_item.reload.time_estimate).to eq(7200)
      end

      it 'adds a timelog entry' do
        patch api(api_request_path, user), params: {
          features: {
            time_tracking: {
              timelog: { time_spent: '1h 30m', summary: 'Worked on the task' }
            }
          }
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(work_item.timelogs.last&.time_spent).to eq(5400)
      end
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(work_item_rest_api: false)
      end

      it 'returns 403' do
        patch api(api_request_path, user), params: { title: 'Updated title' }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when unauthenticated' do
      it 'returns 401' do
        patch api(api_request_path), params: { title: 'Updated title' }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when work item does not exist' do
      it 'returns 404' do
        patch api(base_path + "/#{non_existing_record_iid}", user), params: { title: 'Updated title' }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user does not have permission to update' do
      let_it_be(:other_user) { create(:user) }

      before do
        stub_feature_flags(work_item_rest_api: other_user)
      end

      it 'returns 404 for private resources' do
        patch api(api_request_path, other_user), params: { title: 'Updated title' }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when feature is not supported by the work item type' do
      it 'returns 400' do
        allow_any_instance_of(WorkItems::TypesFramework::SystemDefined::Type) # rubocop:disable RSpec/AnyInstanceOf -- type instances are recreated per-namespace
          .to receive(:widget_classes).and_return([])

        patch api(api_request_path, user), params: { features: { description: { description: 'Some text' } } }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'with invalid state_event value' do
      it 'returns 400' do
        patch api(api_request_path, user), params: { state_event: 'invalid' }

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end

  describe 'PATCH /namespaces/:id/-/work_items/:work_item_iid' do
    let(:base_path) { "/namespaces/#{CGI.escape(project.project_namespace.full_path)}/-/work_items" }
    let(:api_request_path) { "#{base_path}/#{work_item.iid}" }
    let(:label) { create(:label, project: project) }
    let(:milestone) { create(:milestone, project: project) }

    it_behaves_like 'work item update endpoint'

    it_behaves_like 'authorizing granular token permissions', :update_work_item do
      let(:boundary_object) { project }
      let(:request) do
        patch api("/namespaces/#{CGI.escape(project.project_namespace.full_path)}/-/work_items/#{work_item.iid}",
          personal_access_token: pat),
          params: { title: 'Updated title' }
      end
    end

    context 'when namespace is a user namespace' do
      let_it_be(:user_namespace) { create(:namespace, owner: user) }

      it 'returns 404' do
        patch api("/namespaces/#{CGI.escape(user_namespace.full_path)}/-/work_items/1", user),
          params: { title: 'Updated' }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'PATCH /projects/:id/-/work_items/:work_item_iid' do
    let(:base_path) { "/projects/#{project.id}/-/work_items" }
    let(:api_request_path) { "#{base_path}/#{work_item.iid}" }
    let(:label) { create(:label, project: project) }
    let(:milestone) { create(:milestone, project: project) }

    it_behaves_like 'work item update endpoint'

    it_behaves_like 'authorizing granular token permissions', :update_work_item do
      let(:boundary_object) { project }
      let(:request) do
        patch api("/projects/#{project.id}/-/work_items/#{work_item.iid}", personal_access_token: pat),
          params: { title: 'Updated title' }
      end
    end

    it 'supports URL-encoded project full paths' do
      patch api("/projects/#{CGI.escape(project.full_path)}/-/work_items/#{work_item.iid}", user),
        params: { title: 'URL encoded path update' }

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'with add_label_ids limit validation' do
      it 'returns 400 when more than 30 label IDs are provided' do
        patch api(api_request_path, user), params: {
          features: { labels: { add_label_ids: Array.new(31, label.id) } }
        }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to include('must contain at most 30 items')
      end
    end
  end

  describe 'PATCH /groups/:id/-/work_items/:work_item_iid' do
    it 'returns not found for groups without epics license' do
      patch api("/groups/#{group.id}/-/work_items/1", user), params: { title: 'Updated' }

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end
end
