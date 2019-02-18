# frozen_string_literal: true

require 'spec_helper'

describe API::IssuableBulkUpdate do
  set(:project) { create(:project) }
  set(:user) { project.creator }

  shared_examples "PUT /projects/:id/:issuable/bulk_update" do |issuable|
    def bulk_update(issuable, issuables, params, update_user = user)
      put api("/projects/#{project.id}/#{issuable.pluralize}/bulk_update", update_user),
        params: { issuable_ids: Array(issuables).map(&:id) }.merge(params)
    end

    context 'with not enough permissions' do
      it 'returns 403 for guest users' do
        guest = create(:user)
        project.add_guest(guest)

        bulk_update(issuable, issuables, { state_event: 'close' }, guest)

        expect(response).to have_gitlab_http_status(403)
      end
    end

    context 'when modifying the state' do
      it "closes #{issuable}" do
        bulk_update(issuable, issuables, { state_event: 'close' })

        expect(response).to have_gitlab_http_status(200)
        expect(json_response['message']).to eq("#{issuables.count} #{issuable.pluralize(issuables.count)} updated")
        expect(project.public_send(issuable.pluralize).opened).to be_empty
        expect(project.public_send(issuable.pluralize).closed).not_to be_empty
      end

      it "opens #{issuable}" do
        closed_issuables = create_list("closed_#{issuable}".to_sym, 2)

        bulk_update(issuable, closed_issuables, { state_event: 'reopen' })

        expect(response).to have_gitlab_http_status(200)
        expect(project.public_send(issuable.pluralize).closed).to be_empty
      end
    end

    context 'when modifying the milestone' do
      let(:milestone) { create(:milestone, project: project) }

      it "adds a milestone #{issuable}" do
        bulk_update(issuable, issuables, { milestone_id: milestone.id })

        expect(response).to have_gitlab_http_status(200)
        issuables.each do |issuable|
          expect(issuable.reload.milestone).to eq(milestone)
        end
      end

      it 'removes a milestone' do
        issuables.first.milestone = milestone
        milestone_issuable = issuables.first

        bulk_update(issuable, [milestone_issuable], { milestone_id: 0 })

        expect(response).to have_gitlab_http_status(200)
        expect(milestone_issuable.reload.milestone).to eq(nil)
      end
    end

    context 'when modifying the subscription state' do
      it "subscribes to #{issuable}" do
        bulk_update(issuable, issuables, { subscription_event: 'subscribe' })

        expect(response).to have_gitlab_http_status(200)
        expect(issuables).to all(be_subscribed(user, project))
      end

      it 'unsubscribes from issues' do
        issuables.each do |issuable|
          issuable.subscriptions.create(user: user, project: project, subscribed: true)
        end

        bulk_update(issuable, issuables, { subscription_event: 'unsubscribe' })

        expect(response).to have_gitlab_http_status(200)
        issuables.each do |issuable|
          expect(issuable).not_to be_subscribed(user, project)
        end
      end
    end

    context 'when modifying the assignee' do
      it 'adds assignee to issues' do
        params = issuable == 'issue' ? { assignee_ids: [user.id] } : { assignee_id: user.id }

        bulk_update(issuable, issuables, params)

        expect(response).to have_gitlab_http_status(200)
        issuables.each do |issuable|
          expect(issuable.reload.assignees).to eq([user])
        end
      end

      it 'removes assignee' do
        assigned_issuable = issuables.first

        if issuable == 'issue'
          params = { assignee_ids: 0 }
          assigned_issuable.assignees << user
        else
          params = { assignee_id: 0 }
          assigned_issuable.update_attribute(:assignee, user)
        end

        bulk_update(issuable, [assigned_issuable], params)
        expect(assigned_issuable.reload.assignees).to eq([])
      end
    end

    context 'when modifying labels' do
      let(:bug) { create(:label, project: project) }
      let(:regression) { create(:label, project: project) }
      let(:feature) { create(:label, project: project) }

      it 'adds new labels' do
        bulk_update(issuable, issuables, { add_label_ids: [bug.id, regression.id, feature.id] })

        issuables.each do |issusable|
          expect(issusable.reload.label_ids).to contain_exactly(bug.id, regression.id, feature.id)
        end
      end

      it 'removes labels' do
        labled_issuable = issuables.first
        labled_issuable.labels << bug
        labled_issuable.labels << regression
        labled_issuable.labels << feature

        bulk_update(issuable, [labled_issuable], { remove_label_ids: [bug.id, regression.id] })

        expect(labled_issuable.reload.label_ids).to contain_exactly(feature.id)
      end
    end
  end

  it_behaves_like 'PUT /projects/:id/:issuable/bulk_update', 'issue' do
    let(:issuables) { create_list(:issue, 2, project: project) }
  end

  it_behaves_like 'PUT /projects/:id/:issuable/bulk_update', 'merge_request' do
    let(:merge_request_1) { create(:merge_request, source_project: project) }
    let(:merge_request_2) { create(:merge_request, :simple, source_project: project) }
    let(:issuables) { [merge_request_1, merge_request_2] }
  end
end
