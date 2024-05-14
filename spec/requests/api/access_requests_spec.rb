# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::AccessRequests, feature_category: :system_access do
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:access_requester) { create(:user) }
  let_it_be(:stranger) { create(:user) }

  let_it_be(:project) do
    create(:project, :public, creator_id: maintainer.id, namespace: maintainer.namespace) do |project|
      project.add_developer(developer)
      project.add_maintainer(maintainer)
      project.request_access(access_requester)
    end
  end

  let_it_be(:group) do
    create(:group, :public) do |group|
      group.add_developer(developer)
      group.add_owner(maintainer)
      group.request_access(access_requester)
    end
  end

  shared_examples 'GET /:sources/:id/access_requests' do |source_type|
    context "with :sources == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) { get api("/#{source_type.pluralize}/#{source.id}/access_requests", stranger) }
      end

      context 'when authenticated as a non-maintainer/owner' do
        %i[developer access_requester stranger].each do |type|
          context "as a #{type}" do
            it 'returns 403' do
              user = public_send(type)
              get api("/#{source_type.pluralize}/#{source.id}/access_requests", user)

              expect(response).to have_gitlab_http_status(:forbidden)
            end
          end
        end
      end

      context 'when authenticated as a maintainer/owner' do
        it 'returns access requesters' do
          get api("/#{source_type.pluralize}/#{source.id}/access_requests", maintainer)

          expect(response).to have_gitlab_http_status(:ok)
          expect(response).to include_pagination_headers
          expect(json_response).to be_an Array
          expect(json_response.size).to eq(1)
        end
      end
    end
  end

  shared_examples 'POST /:sources/:id/access_requests' do |source_type|
    context "with :sources == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) { post api("/#{source_type.pluralize}/#{source.id}/access_requests", stranger) }
      end

      context 'when authenticated as a member' do
        %i[developer maintainer].each do |type|
          context "as a #{type}" do
            it 'returns 403' do
              expect do
                user = public_send(type)
                post api("/#{source_type.pluralize}/#{source.id}/access_requests", user)

                expect(response).to have_gitlab_http_status(:forbidden)
              end.not_to change { source.requesters.count }
            end
          end
        end
      end

      context 'when authenticated as an access requester' do
        it 'returns 400' do
          expect do
            post api("/#{source_type.pluralize}/#{source.id}/access_requests", access_requester)

            expect(response).to have_gitlab_http_status(:bad_request)
          end.not_to change { source.requesters.count }
        end
      end

      context 'when authenticated as a stranger' do
        context "when access request is disabled for the #{source_type}" do
          before do
            source.update!(request_access_enabled: false)
          end

          it 'returns 403' do
            expect do
              post api("/#{source_type.pluralize}/#{source.id}/access_requests", stranger)

              expect(response).to have_gitlab_http_status(:forbidden)
            end.not_to change { source.requesters.count }
          end
        end

        it 'returns 201' do
          expect do
            post api("/#{source_type.pluralize}/#{source.id}/access_requests", stranger)

            expect(response).to have_gitlab_http_status(:created)
          end.to change { source.requesters.count }.by(1)

          # User attributes
          expect(json_response['id']).to eq(stranger.id)
          expect(json_response['name']).to eq(stranger.name)
          expect(json_response['username']).to eq(stranger.username)
          expect(json_response['state']).to eq(stranger.state)
          expect(json_response['avatar_url']).to eq(stranger.avatar_url)
          expect(json_response['web_url']).to eq(Gitlab::Routing.url_helpers.user_url(stranger))

          # Member attributes
          expect(json_response['requested_at']).to be_present
        end
      end
    end
  end

  shared_examples 'PUT /:sources/:id/access_requests/:user_id/approve' do |source_type|
    context "with :sources == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) { put api("/#{source_type.pluralize}/#{source.id}/access_requests/#{access_requester.id}/approve", stranger) }
      end

      context 'when authenticated as a non-maintainer/owner' do
        %i[developer access_requester stranger].each do |type|
          context "as a #{type}" do
            it 'returns 403' do
              user = public_send(type)
              put api("/#{source_type.pluralize}/#{source.id}/access_requests/#{access_requester.id}/approve", user)

              expect(response).to have_gitlab_http_status(:forbidden)
            end
          end
        end
      end

      context 'when authenticated as a maintainer/owner' do
        it 'returns 201' do
          expect do
            put api("/#{source_type.pluralize}/#{source.id}/access_requests/#{access_requester.id}/approve", maintainer),
              params: { access_level: Member::MAINTAINER }

            expect(response).to have_gitlab_http_status(:created)
          end.to change { source.members.count }.by(1)
          # User attributes
          expect(json_response['id']).to eq(access_requester.id)
          expect(json_response['name']).to eq(access_requester.name)
          expect(json_response['username']).to eq(access_requester.username)
          expect(json_response['state']).to eq(access_requester.state)
          expect(json_response['avatar_url']).to eq(access_requester.avatar_url)
          expect(json_response['web_url']).to eq(Gitlab::Routing.url_helpers.user_url(access_requester))

          # Member attributes
          expect(json_response['access_level']).to eq(Member::MAINTAINER)
        end

        context 'user_id does not match an existing access requester' do
          it 'returns 404' do
            expect do
              put api("/#{source_type.pluralize}/#{source.id}/access_requests/#{stranger.id}/approve", maintainer)

              expect(response).to have_gitlab_http_status(:not_found)
            end.not_to change { source.members.count }
          end
        end
      end
    end
  end

  shared_examples 'DELETE /:sources/:id/access_requests/:user_id' do |source_type|
    context "with :sources == #{source_type.pluralize}" do
      it_behaves_like 'a 404 response when source is private' do
        let(:route) { delete api("/#{source_type.pluralize}/#{source.id}/access_requests/#{access_requester.id}", stranger) }
      end

      context 'when authenticated as a non-maintainer/owner' do
        %i[developer stranger].each do |type|
          context "as a #{type}" do
            it 'returns 403' do
              user = public_send(type)
              delete api("/#{source_type.pluralize}/#{source.id}/access_requests/#{access_requester.id}", user)

              expect(response).to have_gitlab_http_status(:forbidden)
            end
          end
        end
      end

      context 'when authenticated as the access requester' do
        it 'deletes the access requester' do
          expect do
            delete api("/#{source_type.pluralize}/#{source.id}/access_requests/#{access_requester.id}", access_requester)

            expect(response).to have_gitlab_http_status(:no_content)
          end.to change { source.requesters.count }.by(-1)
        end
      end

      context 'when authenticated as a maintainer/owner' do
        it 'deletes the access requester' do
          expect do
            delete api("/#{source_type.pluralize}/#{source.id}/access_requests/#{access_requester.id}", maintainer)

            expect(response).to have_gitlab_http_status(:no_content)
          end.to change { source.requesters.count }.by(-1)
        end

        context 'user_id matches a member, not an access requester' do
          it 'returns 404' do
            expect do
              delete api("/#{source_type.pluralize}/#{source.id}/access_requests/#{developer.id}", maintainer)

              expect(response).to have_gitlab_http_status(:not_found)
            end.not_to change { source.requesters.count }
          end
        end

        context 'user_id does not match an existing access requester' do
          it 'returns 404' do
            expect do
              delete api("/#{source_type.pluralize}/#{source.id}/access_requests/#{stranger.id}", maintainer)

              expect(response).to have_gitlab_http_status(:not_found)
            end.not_to change { source.requesters.count }
          end
        end
      end
    end
  end

  it_behaves_like 'GET /:sources/:id/access_requests', 'project' do
    let(:source) { project }
  end

  it_behaves_like 'GET /:sources/:id/access_requests', 'group' do
    let(:source) { group }
  end

  it_behaves_like 'POST /:sources/:id/access_requests', 'project' do
    let(:source) { project }
  end

  it_behaves_like 'POST /:sources/:id/access_requests', 'group' do
    let(:source) { group }
  end

  it_behaves_like 'PUT /:sources/:id/access_requests/:user_id/approve', 'project' do
    let(:source) { project }
  end

  it_behaves_like 'PUT /:sources/:id/access_requests/:user_id/approve', 'group' do
    let(:source) { group }
  end

  it_behaves_like 'DELETE /:sources/:id/access_requests/:user_id', 'project' do
    let(:source) { project }
  end

  it_behaves_like 'DELETE /:sources/:id/access_requests/:user_id', 'group' do
    let(:source) { group }
  end
end
