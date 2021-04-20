# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::IssueLinksController do
  let(:user) { create :user }
  let(:project) { create(:project_empty_repo) }
  let(:issue) { create :issue, project: project }

  describe 'GET /*namespace_id/:project_id/issues/:issue_id/links' do
    let(:issue_b) { create :issue, project: project }
    let!(:issue_link) { create :issue_link, source: issue, target: issue_b }

    before do
      project.add_guest(user)
      login_as user
    end

    it 'returns JSON response' do
      list_service_response = IssueLinks::ListService.new(issue, user).execute

      get namespace_project_issue_links_path(issue_links_params)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq(list_service_response.as_json)
    end
  end

  describe 'POST /*namespace_id/:project_id/issues/:issue_id/links' do
    let(:issue_b) { create :issue, project: project }

    before do
      project.add_role(user, user_role)
      login_as user
    end

    context 'with success' do
      let(:user_role) { :developer }
      let(:issuable_references) { [issue_b.to_reference] }

      it 'returns success JSON' do
        post namespace_project_issue_links_path(issue_links_params(issuable_references: issuable_references))

        list_service_response = IssueLinks::ListService.new(issue, user).execute

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq('message' => nil,
                                    'issuables' => list_service_response.as_json)
      end
    end

    context 'with failure' do
      context 'when unauthorized' do
        let(:user_role) { :guest }
        let(:issuable_references) { [issue_b.to_reference] }

        it 'returns 403' do
          post namespace_project_issue_links_path(issue_links_params(issuable_references: issuable_references))

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when failing service result' do
        let(:user_role) { :developer }
        let(:issuable_references) { ["##{non_existing_record_iid}"] }

        it 'returns failure JSON' do
          post namespace_project_issue_links_path(issue_links_params(issuable_references: issuable_references))

          list_service_response = IssueLinks::ListService.new(issue, user).execute

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response).to eq('message' => 'No matching issue found. Make sure that you are adding a valid issue URL.', 'issuables' => list_service_response.as_json)
        end
      end
    end
  end

  describe 'DELETE /*namespace_id/:project_id/issues/:issue_id/link/:id' do
    let(:issue_link) { create :issue_link, source: issue, target: referenced_issue }

    before do
      project.add_role(user, user_role)
      login_as user
    end

    context 'when unauthorized' do
      context 'when no authorization on current project' do
        let(:referenced_issue) { create :issue, project: project }
        let(:user_role) { :guest }

        it 'returns 403' do
          delete namespace_project_issue_link_path(issue_links_params(id: issue_link.id))

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'when no authorization on the related issue project' do
        # unauthorized project issue
        let(:referenced_issue) { create :issue }
        let(:user_role) { :developer }

        it 'returns 404' do
          delete namespace_project_issue_link_path(issue_links_params(id: issue_link.id))

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when authorized' do
      let(:referenced_issue) { create :issue, project: project }
      let(:user_role) { :developer }

      it 'returns success JSON' do
        delete namespace_project_issue_link_path(issue_links_params(id: issue_link.id))

        list_service_response = IssueLinks::ListService.new(issue, user).execute

        expect(json_response).to eq('issuables' => list_service_response.as_json)
      end
    end

    context 'when non of issues of the link is not the issue requested in the path' do
      let(:referenced_issue) { create(:issue, project: project) }
      let(:another_issue) { create(:issue, project: project) }
      let(:issue) { create(:issue, project: project) }
      let(:user_role) { :developer }

      let!(:issue_link) { create :issue_link, source: another_issue, target: referenced_issue }

      subject do
        delete namespace_project_issue_link_path(issue_links_params(id: issue_link.id))
      end

      it 'returns 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'does not delete the link' do
        expect { subject }.not_to change { IssueLink.count }.from(1)
      end
    end
  end

  def issue_links_params(opts = {})
    opts.reverse_merge(namespace_id: issue.project.namespace,
                       project_id: issue.project,
                       issue_id: issue,
                       format: :json)
  end
end
