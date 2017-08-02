require 'spec_helper'

describe API::IssueLinks do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:issue) { create(:issue, project: project) }

  before do
    project.add_guest(user)
  end

  describe 'GET /links' do
    context 'when unauthenticated' do
      it 'returns 401' do
        get api("/projects/#{project.id}/issues/#{issue.iid}/links")

        expect(response).to have_http_status(401)
      end
    end

    context 'when authenticated' do
      it 'returns related issues' do
        target_issue = create(:issue, project: project)
        create(:issue_link, source: issue, target: target_issue)

        get api("/projects/#{project.id}/issues/#{issue.iid}/links", user)

        expect(response).to have_http_status(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(1)
        expect(json_response.first).to include('iid', 'title', 'issue_link_id')
      end
    end
  end

  describe 'POST /links' do
    context 'when unauthenticated' do
      it 'returns 401' do
        target_issue = create(:issue)

        post api("/projects/#{project.id}/issues/#{issue.iid}/links"),
             target_project_id: target_issue.project.id, target_issue_iid: target_issue.iid

        expect(response).to have_http_status(401)
      end
    end

    context 'when authenticated' do
      context 'given target project not found' do
        it 'returns 404' do
          target_issue = create(:issue)

          post api("/projects/#{project.id}/issues/#{issue.iid}/links", user),
               target_project_id: 999, target_issue_iid: target_issue.iid

          expect(response).to have_http_status(404)
          expect(json_response['message']).to eq('404 Project Not Found')
        end
      end

      context 'given target issue not found' do
        it 'returns 404' do
          target_project = create(:project, :public)

          post api("/projects/#{project.id}/issues/#{issue.iid}/links", user),
               target_project_id: target_project.id, target_issue_iid: 999

          expect(response).to have_http_status(404)
          expect(json_response['message']).to eq('404 Not found')
        end
      end

      context 'when user does not have write access to given issue' do
        it 'returns 404' do
          unauthorized_project = create(:project)
          target_issue = create(:issue, project: unauthorized_project)
          unauthorized_project.add_guest(user)

          post api("/projects/#{project.id}/issues/#{issue.iid}/links", user),
               target_project_id: unauthorized_project.id, target_issue_iid: target_issue.iid

          expect(response).to have_http_status(404)
          expect(json_response['message']).to eq('No Issue found for given params')
        end
      end

      context 'when trying to relate to a confidential issue' do
        it 'returns 404' do
          project = create(:project, :public)
          target_issue = create(:issue, :confidential, project: project)

          post api("/projects/#{project.id}/issues/#{issue.iid}/links", user),
               target_project_id: project.id, target_issue_iid: target_issue.iid

          expect(response).to have_http_status(404)
          expect(json_response['message']).to eq('404 Not found')
        end
      end

      context 'when trying to relate to a private project issue' do
        it 'returns 404' do
          project = create(:project, :private)
          target_issue = create(:issue, project: project)

          post api("/projects/#{project.id}/issues/#{issue.iid}/links", user),
               target_project_id: project.id, target_issue_iid: target_issue.iid

          expect(response).to have_http_status(404)
          expect(json_response['message']).to eq('404 Project Not Found')
        end
      end

      context 'when user has ability to create an issue link' do
        it 'returns 201' do
          target_issue = create(:issue, project: project)
          project.add_reporter(user)

          post api("/projects/#{project.id}/issues/#{issue.iid}/links", user),
               target_project_id: project.id, target_issue_iid: target_issue.iid

          expect(response).to have_http_status(201)
          expect(json_response).to include('source_issue', 'target_issue')
        end

        it 'returns 201 when sending full path of target project' do
          target_issue = create(:issue, project: project)
          project.add_reporter(user)

          post api("/projects/#{project.id}/issues/#{issue.iid}/links", user),
               target_project_id: project.to_reference(full: true), target_issue_iid: target_issue.iid

          expect(response).to have_http_status(201)
          expect(json_response).to include('source_issue', 'target_issue')
        end
      end
    end
  end

  describe 'DELETE /links/:issue_link_id' do
    context 'when unauthenticated' do
      it 'returns 401' do
        issue_link = create(:issue_link)

        delete api("/projects/#{project.id}/issues/#{issue.iid}/links/#{issue_link.id}")

        expect(response).to have_http_status(401)
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

          expect(response).to have_http_status(404)
          expect(json_response['message']).to eq('No Issue Link found')
        end
      end

      context 'issue link not found' do
        it 'returns 404' do
          delete api("/projects/#{project.id}/issues/#{issue.iid}/links/999", user)

          expect(response).to have_http_status(404)
          expect(json_response['message']).to eq('404 Not found')
        end
      end

      context 'when trying to delete a link with a private project issue' do
        it 'returns 404' do
          project = create(:project, :private)
          target_issue = create(:issue, project: project)
          issue_link = create(:issue_link, source: issue, target: target_issue)

          delete api("/projects/#{project.id}/issues/#{issue.iid}/links/#{issue_link.id}", user)

          expect(response).to have_http_status(404)
          expect(json_response['message']).to eq('404 Project Not Found')
        end
      end

      context 'when user has ability to delete the issue link' do
        it 'returns 200' do
          target_issue = create(:issue, project: project)
          issue_link = create(:issue_link, source: issue, target: target_issue)
          project.add_reporter(user)

          delete api("/projects/#{project.id}/issues/#{issue.iid}/links/#{issue_link.id}", user)

          expect(response).to have_http_status(200)
          expect(json_response).to include('source_issue', 'target_issue')
        end
      end
    end
  end
end
