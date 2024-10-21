# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::IssueLinks, feature_category: :team_planning do
  let_it_be(:non_member) { create(:user) }
  let_it_be(:guest_user) { create(:user) }
  let_it_be(:public_project) { create(:project, :public, guests: guest_user) }
  let_it_be(:private_project) { create(:project, :private, guests: guest_user) }

  let_it_be(:project) { public_project }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:target_issue) { create(:issue, project: project) }

  describe 'GET /links' do
    let_it_be(:issue_link) { create(:issue_link, source: issue, target: target_issue) }

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
      let_it_be(:target_issue2) { create(:issue, project: project) }
      let_it_be(:issue_link2) { create(:issue_link, source: issue, target: target_issue2) }

      it 'returns related issues' do
        perform_request(guest_user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(2)
        expect(response).to match_response_schema('public_api/v4/related_issues')
      end

      it 'returns multiple links without N + 1' do
        perform_request(guest_user)

        control = ActiveRecord::QueryRecorder.new { perform_request(guest_user) }

        create(:issue_link, source: issue, target: create(:issue, project: project))

        expect { perform_request(guest_user) }.not_to exceed_query_limit(control)
      end
    end
  end

  describe 'POST /links' do
    def perform_request(user = nil, params: {})
      post api("/projects/#{project.id}/issues/#{issue.iid}/links", user), params: params
    end

    context 'when unauthenticated' do
      it 'returns 401' do
        perform_request(params: { target_project_id: target_issue.project.id, target_issue_iid: target_issue.iid })

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      context 'given target project not found' do
        it 'returns 404' do
          perform_request(guest_user, params: { target_project_id: -1, target_issue_iid: target_issue.iid })

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 Project Not Found')
        end
      end

      context 'given target issue not found' do
        it 'returns 404' do
          perform_request(
            guest_user,
            params: { target_project_id: project.id, target_issue_iid: non_existing_record_iid }
          )

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 Not found')
        end
      end

      context 'when user does not have access to given issue' do
        it 'returns 403' do
          perform_request(non_member, params: { target_project_id: project.id, target_issue_iid: target_issue.iid })

          expect(response).to have_gitlab_http_status(:forbidden)
          expect(json_response['message'])
            .to eq("Couldn't link issues. You must have at least the Guest role in both projects.")
        end
      end

      context 'when trying to relate to a confidential issue' do
        let_it_be(:target_issue) { create(:issue, :confidential, project: project) }

        it 'returns 404' do
          perform_request(guest_user, params: { target_project_id: project.id, target_issue_iid: target_issue.iid })

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 Not found')
        end
      end

      context 'when trying to relate to a private project issue' do
        let_it_be(:project) { private_project }

        it 'returns 404' do
          perform_request(non_member, params: { target_project_id: project.id, target_issue_iid: target_issue.iid })

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 Project Not Found')
        end
      end

      context 'when user has ability to create an issue link' do
        it 'returns 201 status and contains the expected link response' do
          perform_request(
            guest_user,
            params: { target_project_id: project.id, target_issue_iid: target_issue.iid, link_type: 'relates_to' }
          )

          expect_link_response(link_type: 'relates_to')
          expect(json_response['source_issue']['id']).to eq(issue.id)
          expect(json_response['target_issue']['id']).to eq(target_issue.id)
        end

        it 'returns 201 when sending full path of target project' do
          perform_request(
            guest_user,
            params: { target_project_id: project.full_path, target_issue_iid: target_issue.iid }
          )

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

  describe 'GET /links/:issue_link_id' do
    let_it_be(:issue_link) { create(:issue_link, source: issue, target: target_issue) }

    def perform_request(issue_link_id, user = nil, params = {})
      get api("/projects/#{project.id}/issues/#{issue.iid}/links/#{issue_link_id}", user), params: params
    end

    context 'when unauthenticated' do
      context 'when accessing an issue of a private project' do
        let_it_be(:project) { private_project }

        it 'returns 401' do
          perform_request(issue_link.id)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      # This isn't ideal, see https://gitlab.com/gitlab-org/gitlab/-/issues/364077
      context 'when accessing an issue of a public project' do
        it 'returns 401' do
          perform_request(issue_link.id)

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    context 'when authenticated' do
      context 'when issue link does not exist' do
        it 'returns 404' do
          perform_request(non_existing_record_id, guest_user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when issue link does not belong to the specified issue' do
        it 'returns 404' do
          other_issue = create(:issue, project: project)
          # source is different than the given API route issue
          other_link = create(:issue_link, source: other_issue, target: target_issue)
          perform_request(other_link.id, guest_user)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when user has ability to read the issue link' do
        it 'returns 200' do
          perform_request(issue_link.id, guest_user)

          aggregate_failures "testing response" do
            expect(response).to have_gitlab_http_status(:ok)
            expect(response).to match_response_schema('public_api/v4/issue_link')
          end
        end
      end

      context 'when user cannot read issue link' do
        context 'when the issue link targets an issue in a non-accessible project' do
          it 'returns 404' do
            private_issue = create(:issue, project: create(:project, :private))
            private_link = create(:issue_link, source: issue, target: private_issue)

            perform_request(private_link.id, guest_user)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end

        context 'when issue link targets a non-accessible issue' do
          it 'returns 404' do
            confidential_issue = create(:issue, :confidential, project: public_project)
            confidential_link = create(:issue_link, source: issue, target: confidential_issue)

            perform_request(confidential_link.id, guest_user)

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end
    end
  end

  describe 'DELETE /links/:issue_link_id' do
    let_it_be(:issue_link) { create(:issue_link, source: issue, target: target_issue) }

    def perform_request(issue_link_id, user = nil)
      delete api("/projects/#{project.id}/issues/#{issue.iid}/links/#{issue_link_id}", user)
    end

    context 'when unauthenticated' do
      it 'returns 401' do
        perform_request(issue_link.id)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      context 'when user does not have write access to given issue link' do
        it 'returns 404' do
          external_public_issue = create(:issue, project: create(:project, :public))
          external_link = create(:issue_link, source: issue, target: external_public_issue)
          perform_request(external_link.id, guest_user)

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('No Issue Link found')
        end
      end

      context 'issue link not found' do
        it 'returns 404' do
          perform_request(non_existing_record_id, guest_user)

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 Not found')
        end
      end

      context 'when trying to delete a link with a private project issue' do
        let_it_be(:project) { private_project }

        it 'returns 404' do
          perform_request(issue_link.id, non_member)

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 Project Not Found')
        end
      end

      context 'when user has ability to delete the issue link' do
        it 'returns 200' do
          perform_request(issue_link.id, guest_user)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to match_response_schema('public_api/v4/issue_link')
        end

        it 'returns 404 when the issue link does not belong to the specified issue' do
          other_issue = create(:issue, project: project)
          other_link = create(:issue_link, source: other_issue, target: target_issue)

          perform_request(other_link.id, guest_user)

          expect(response).to have_gitlab_http_status(:not_found)
          expect(json_response['message']).to eq('404 Not found')
        end
      end
    end
  end
end
