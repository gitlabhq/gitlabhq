# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::IssueLinks do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }

  before do
    project.add_guest(user)
  end

  describe 'GET /links' do
    def perform_request(user = nil, params = {})
      get api("/projects/#{project.id}/issues/#{issue.iid}/links", user), params: params
    end

    context 'when unauthenticated' do
      it 'returns 401' do
        perform_request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      let_it_be(:issue_link1) { create(:issue_link, source: issue, target: create(:issue, project: project)) }
      let_it_be(:issue_link2) { create(:issue_link, source: issue, target: create(:issue, project: project)) }

      it 'returns related issues' do
        perform_request(user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
        expect(response).to match_response_schema('public_api/v4/issue_links')
      end

      it 'returns multiple links without N + 1' do
        perform_request(user)

        control_count = ActiveRecord::QueryRecorder.new { perform_request(user) }.count

        create(:issue_link, source: issue, target: create(:issue, project: project))

        expect { perform_request(user) }.not_to exceed_query_limit(control_count)
      end
    end
  end

  describe 'POST /links' do
    context 'when unauthenticated' do
      it 'returns 401' do
        target_issue = create(:issue)

        post api("/projects/#{project.id}/issues/#{issue.iid}/links"),
             params: { target_project_id: target_issue.project.id, target_issue_iid: target_issue.iid }

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      context 'given target project not found' do
        it 'returns 404' do
          target_issue = create(:issue)

          post api("/projects/#{project.id}/issues/#{issue.iid}/links", user),
               params: { target_project_id: -1, target_issue_iid: target_issue.iid }

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 Project Not Found')
        end
      end

      context 'given target issue not found' do
        it 'returns 404' do
          target_project = create(:project, :public)

          post api("/projects/#{project.id}/issues/#{issue.iid}/links", user),
               params: { target_project_id: target_project.id, target_issue_iid: non_existing_record_iid }

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 Not found')
        end
      end

      context 'when user does not have write access to given issue' do
        it 'returns 404' do
          unauthorized_project = create(:project)
          target_issue = create(:issue, project: unauthorized_project)
          unauthorized_project.add_guest(user)

          post api("/projects/#{project.id}/issues/#{issue.iid}/links", user),
               params: { target_project_id: unauthorized_project.id, target_issue_iid: target_issue.iid }

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('No matching issue found. Make sure that you are adding a valid issue URL.')
        end
      end

      context 'when trying to relate to a confidential issue' do
        it 'returns 404' do
          project = create(:project, :public)
          target_issue = create(:issue, :confidential, project: project)

          post api("/projects/#{project.id}/issues/#{issue.iid}/links", user),
               params: { target_project_id: project.id, target_issue_iid: target_issue.iid }

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 Not found')
        end
      end

      context 'when trying to relate to a private project issue' do
        it 'returns 404' do
          project = create(:project, :private)
          target_issue = create(:issue, project: project)

          post api("/projects/#{project.id}/issues/#{issue.iid}/links", user),
               params: { target_project_id: project.id, target_issue_iid: target_issue.iid }

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 Project Not Found')
        end
      end

      context 'when user has ability to create an issue link' do
        let_it_be(:target_issue) { create(:issue, project: project) }

        before do
          project.add_reporter(user)
        end

        it 'returns 201 status and contains the expected link response' do
          post api("/projects/#{project.id}/issues/#{issue.iid}/links", user),
               params: { target_project_id: project.id, target_issue_iid: target_issue.iid, link_type: 'relates_to' }

          expect_link_response(link_type: 'relates_to')
        end

        it 'returns 201 when sending full path of target project' do
          post api("/projects/#{project.id}/issues/#{issue.iid}/links", user),
               params: { target_project_id: project.full_path, target_issue_iid: target_issue.iid }

          expect_link_response
        end

        def expect_link_response(link_type: 'relates_to')
          expect(response).to have_gitlab_http_status(:created)
          expect(response).to match_response_schema('public_api/v4/issue_link')
          expect(json_response['link_type']).to eq(link_type)
        end
      end
    end
  end

  describe 'DELETE /links/:issue_link_id' do
    context 'when unauthenticated' do
      it 'returns 401' do
        issue_link = create(:issue_link)

        delete api("/projects/#{project.id}/issues/#{issue.iid}/links/#{issue_link.id}")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      context 'when user does not have write access to given issue link' do
        it 'returns 404' do
          unauthorized_project = create(:project)
          target_issue = create(:issue, project: unauthorized_project)
          issue_link = create(:issue_link, source: issue, target: target_issue)
          unauthorized_project.add_guest(user)

          delete api("/projects/#{project.id}/issues/#{issue.iid}/links/#{issue_link.id}", user)

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('No Issue Link found')
        end
      end

      context 'issue link not found' do
        it 'returns 404' do
          delete api("/projects/#{project.id}/issues/#{issue.iid}/links/#{non_existing_record_id}", user)

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 Not found')
        end
      end

      context 'when trying to delete a link with a private project issue' do
        it 'returns 404' do
          project = create(:project, :private)
          target_issue = create(:issue, project: project)
          issue_link = create(:issue_link, source: issue, target: target_issue)

          delete api("/projects/#{project.id}/issues/#{issue.iid}/links/#{issue_link.id}", user)

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 Project Not Found')
        end
      end

      context 'when user has ability to delete the issue link' do
        it 'returns 200' do
          target_issue = create(:issue, project: project)
          issue_link = create(:issue_link, source: issue, target: target_issue)
          project.add_reporter(user)

          delete api("/projects/#{project.id}/issues/#{issue.iid}/links/#{issue_link.id}", user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/issue_link')
        end
      end
    end
  end
end
